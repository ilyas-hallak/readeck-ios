import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {

    /// Describes how the caller lays the image out, so it can be decoded at the size
    /// it is actually drawn at instead of at the source resolution.
    ///
    /// Article images are routinely 2000-3000px wide, which is a 20-40 MB bitmap in
    /// memory once decoded. Feeding that into an 80pt thumbnail or a 360pt header
    /// costs the decode, the backing store and every GPU upload for nothing.
    enum Sizing: Equatable {
        /// Decode at the source resolution. For views that zoom into the image.
        case original
        /// The image is drawn with `scaledToFit` inside this box.
        case fit(CGSize)
        /// The image is drawn with `scaledToFill` inside this box, so the shorter
        /// edge has to be covered as well.
        case fill(CGSize)
        /// The image is drawn at a fixed width with its natural height.
        case width(CGFloat)

        /// Longest edge, in points, that the drawn image can occupy.
        var maxDimension: CGFloat? {
            switch self {
            case .original:
                return nil
            case .fit(let box):
                // Fitting never scales beyond the larger edge of the box.
                return max(box.width, box.height)
            case .fill(let box):
                // Filling scales until the shorter edge is covered, so a landscape
                // image overflows the longer edge. Budget for 2:1, which covers every
                // aspect ratio that shows up in practice; anything wider is only
                // slightly soft instead of pin sharp.
                return max(max(box.width, box.height), min(box.width, box.height) * 2)
            case .width(let width):
                // Height is free, so a portrait image is taller than it is wide.
                // 3:2 portrait is the realistic worst case.
                return width * 1.5
            }
        }
    }

    let url: URL?
    let cacheKey: String?
    let sizing: Sizing
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.displayScale) private var displayScale
    @State private var isImageCached = false
    @State private var hasCheckedCache = false
    @State private var cachedImage: UIImage?

    init(url: URL?, cacheKey: String? = nil, sizing: Sizing = .original) {
        self.url = url
        self.cacheKey = cacheKey
        self.sizing = sizing
    }

    var body: some View {
        if let url {
            imageView(for: url)
                // Only the offline branch reads the cache probe below. Running it while
                // online decoded a second, full-resolution copy of every image that was
                // then never drawn.
                .task(id: appSettings.isNetworkConnected) {
                    guard !appSettings.isNetworkConnected else { return }
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

    // MARK: - Downsampling

    /// Target size handed to Kingfisher, in points. Kingfisher multiplies it by the
    /// scale factor, so the result is sized in device pixels.
    private var downsampleSize: CGSize? {
        guard let maxDimension = sizing.maxDimension, maxDimension > 0 else { return nil }
        return CGSize(width: maxDimension, height: maxDimension)
    }

    // MARK: - Online Mode

    private func onlineImageView(url: URL) -> some View {
        KFImage(url)
            .requestModifier(AuthenticatedImageRequestModifier())
            .cacheOriginalImage()
            .diskCacheExpiration(.never)
            .downsampled(to: downsampleSize, scale: displayScale)
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
            .downsampled(to: downsampleSize, scale: displayScale)
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
        if let cacheKey, await tryLoadFromCustomKey(cacheKey) {
            return
        }

        await checkStandardCache(for: url)
    }

    private func tryLoadFromCustomKey(_ key: String) async -> Bool {
        let image = await retrieveImageFromCache(key: key)
        let prepared = await downsampleIfNeeded(image)

        await MainActor.run {
            if let prepared {
                cachedImage = prepared
                isImageCached = true
                Logger.ui.debug("✅ Loaded image from cache using key: \(key)")
            } else {
                Logger.ui.debug("Image not found with cache key, trying URL-based cache")
            }
            hasCheckedCache = true
        }

        return prepared != nil
    }

    /// The offline hero cache stores the original image, so shrink it here too instead
    /// of handing a full-resolution bitmap to `Image(uiImage:)`.
    private func downsampleIfNeeded(_ image: UIImage?) async -> UIImage? {
        guard let image else { return nil }
        guard let size = downsampleSize else { return image }
        let scale = displayScale

        return await Task.detached(priority: .userInitiated) {
            let processor = DownsamplingImageProcessor(size: size)
            let options = KingfisherParsedOptionsInfo([.scaleFactor(scale)])
            return processor.process(item: .image(image), options: options) ?? image
        }.value
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

private extension KFImage {
    /// Decodes the image straight to `size` instead of decoding it in full and letting
    /// the GPU scale it down.
    ///
    /// The processor identifier carries the size, so every target size gets its own
    /// cache entry and no size can be served in place of another. `cacheOriginalImage`
    /// stays in effect, so the untouched original is still on disk: a second target
    /// size, and the offline path, are served from it without another download.
    func downsampled(to size: CGSize?, scale: CGFloat) -> KFImage {
        guard let size else { return self }
        return setProcessor(DownsamplingImageProcessor(size: size))
            .scaleFactor(scale)
    }
}

/// Request modifier that adds Authorization header and custom headers to image requests
struct AuthenticatedImageRequestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var modifiedRequest = request

        if let token = KeychainHelper.shared.loadToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        HTTPHeadersHelper.shared.applyCustomHeaders(to: &modifiedRequest)

        return modifiedRequest
    }
}
