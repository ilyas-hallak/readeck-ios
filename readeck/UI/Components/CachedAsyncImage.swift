import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {
    let url: URL?
    let cacheKey: String?
    @EnvironmentObject private var appSettings: AppSettings
    @State private var isImageCached = false
    @State private var hasCheckedCache = false
    @State private var cachedImage: UIImage?

    init(url: URL?, cacheKey: String? = nil) {
        self.url = url
        self.cacheKey = cacheKey
    }

    var body: some View {
        if let url {
            imageView(for: url)
                .task {
                    await checkCache(for: url)
                }
        } else {
            placeholderImage
        }
    }

    @ViewBuilder
    private func imageView(for url: URL) -> some View {
        if appSettings.isNetworkConnected {
            onlineImageView(url: url)
        } else {
            offlineImageView(url: url)
        }
    }

    // MARK: - Online Mode

    private func onlineImageView(url: URL) -> some View {
        KFImage(url)
            .cacheOriginalImage()
            .diskCacheExpiration(.never)
            .placeholder { Color.gray.opacity(0.3) }
            .fade(duration: 0.25)
            .resizable()
            .frame(maxWidth: .infinity)
    }

    // MARK: - Offline Mode

    @ViewBuilder
    private func offlineImageView(url: URL) -> some View {
        if hasCheckedCache && !isImageCached {
            placeholderWithWarning
        } else if let cachedImage {
            cachedImageView(image: cachedImage)
        } else {
            kingfisherCacheOnlyView(url: url)
        }
    }

    private func cachedImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(maxWidth: .infinity)
    }

    private func kingfisherCacheOnlyView(url: URL) -> some View {
        KFImage(url)
            .cacheOriginalImage()
            .diskCacheExpiration(.never)
            .loadDiskFileSynchronously()
            .onlyFromCache(true)
            .placeholder { Color.gray.opacity(0.3) }
            .onSuccess { _ in
                Logger.ui.debug("✅ Loaded image from cache: \(url.absoluteString)")
            }
            .onFailure { error in
                Logger.ui.warning("❌ Failed to load cached image: \(url.absoluteString) - \(error.localizedDescription)")
            }
            .fade(duration: 0.25)
            .resizable()
            .frame(maxWidth: .infinity)
    }

    private var placeholderImage: some View {
        Color.gray.opacity(0.3)
            .frame(maxWidth: .infinity)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .font(.largeTitle)
            )
    }

    private var placeholderWithWarning: some View {
        Color.gray.opacity(0.3)
            .frame(maxWidth: .infinity)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.gray)
                        .font(.title)
                    Text("Offline - Image not cached")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }

    // MARK: - Cache Checking

    private func checkCache(for url: URL) async {
        // Try custom cache key first, then fallback to URL-based cache
        if let cacheKey = cacheKey, await tryLoadFromCustomKey(cacheKey) {
            return
        }

        await checkStandardCache(for: url)
    }

    private func tryLoadFromCustomKey(_ key: String) async -> Bool {
        let image = await retrieveImageFromCache(key: key)

        await MainActor.run {
            if let image {
                cachedImage = image
                isImageCached = true
                Logger.ui.debug("✅ Loaded image from cache using key: \(key)")
            } else {
                Logger.ui.debug("Image not found with cache key, trying URL-based cache")
            }
            hasCheckedCache = true
        }

        return image != nil
    }

    private func checkStandardCache(for url: URL) async {
        let isCached = await isImageInCache(url: url)

        await MainActor.run {
            isImageCached = isCached
            hasCheckedCache = true

            if !appSettings.isNetworkConnected {
                Logger.ui.debug(isCached
                    ? "✅ Image is cached for offline use: \(url.absoluteString)"
                    : "❌ Image NOT cached for offline use: \(url.absoluteString)")
            }
        }
    }

    private func retrieveImageFromCache(key: String) async -> UIImage? {
        await withCheckedContinuation { continuation in
            ImageCache.default.retrieveImage(forKey: key) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func isImageInCache(url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image != nil)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
