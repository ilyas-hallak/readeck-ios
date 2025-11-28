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
            // Online mode: Normal behavior with caching
            KFImage(url)
                .cacheOriginalImage()
                .diskCacheExpiration(.never)
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .fade(duration: 0.25)
                .resizable()
                .frame(maxWidth: .infinity)
        } else {
            // Offline mode: Only load from cache
            if hasCheckedCache && !isImageCached {
                // Image not in cache - show placeholder
                placeholderWithWarning
            } else if let cachedImage {
                // Show cached image loaded via custom key
                Image(uiImage: cachedImage)
                    .resizable()
                    .frame(maxWidth: .infinity)
            } else {
                KFImage(url)
                    .cacheOriginalImage()
                    .diskCacheExpiration(.never)
                    .loadDiskFileSynchronously()
                    .onlyFromCache(true)
                    .placeholder {
                        Color.gray.opacity(0.3)
                    }
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
        }
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

    private func checkCache(for url: URL) async {
        // If we have a custom cache key, try to load from cache using that key first
        if let cacheKey = cacheKey {
            let result = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
                ImageCache.default.retrieveImage(forKey: cacheKey) { result in
                    switch result {
                    case .success(let cacheResult):
                        continuation.resume(returning: cacheResult.image)
                    case .failure:
                        continuation.resume(returning: nil)
                    }
                }
            }

            await MainActor.run {
                if let image = result {
                    cachedImage = image
                    isImageCached = true
                    Logger.ui.debug("✅ Loaded image from cache using key: \(cacheKey)")
                } else {
                    // Fallback to URL-based cache check
                    Logger.ui.debug("Image not found with cache key, trying URL-based cache")
                }
                hasCheckedCache = true
            }

            // If we found the image with cache key, we're done
            if cachedImage != nil {
                return
            }
        }

        // Fallback: Check standard Kingfisher cache using URL
        let isCached = await withCheckedContinuation { continuation in
            KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image != nil)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }

        await MainActor.run {
            isImageCached = isCached
            hasCheckedCache = true

            if !appSettings.isNetworkConnected {
                if isCached {
                    Logger.ui.debug("✅ Image is cached for offline use: \(url.absoluteString)")
                } else {
                    Logger.ui.warning("❌ Image NOT cached for offline use: \(url.absoluteString)")
                }
            }
        }
    }
}
