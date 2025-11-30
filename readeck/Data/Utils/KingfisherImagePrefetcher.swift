//
//  KingfisherImagePrefetcher.swift
//  readeck
//
//  Created by Claude on 30.11.25.
//

import Foundation
import Kingfisher

/// Wrapper around Kingfisher for prefetching and caching images for offline use
class KingfisherImagePrefetcher {

    // MARK: - Public Methods

    /// Prefetches images and stores them in Kingfisher cache for offline access
    /// - Parameter urls: Array of image URLs to prefetch
    func prefetchImages(urls: [URL]) async {
        guard !urls.isEmpty else { return }

        Logger.sync.info("🔄 Starting Kingfisher prefetch for \(urls.count) images")
        logPrefetchURLs(urls)

        let options = buildOfflineCachingOptions()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let prefetcher = ImagePrefetcher(
                urls: urls,
                options: options,
                progressBlock: { [weak self] skippedResources, failedResources, completedResources in
                    self?.logPrefetchProgress(
                        total: urls.count,
                        completed: completedResources.count,
                        failed: failedResources.count,
                        skipped: skippedResources.count
                    )
                },
                completionHandler: { [weak self] skippedResources, failedResources, completedResources in
                    self?.logPrefetchCompletion(
                        total: urls.count,
                        completed: completedResources.count,
                        failed: failedResources.count,
                        skipped: skippedResources.count
                    )

                    // Verify cache after prefetch
                    Task {
                        await self?.verifyPrefetchedImages(urls)
                        continuation.resume()
                    }
                }
            )
            prefetcher.start()
        }
    }

    /// Caches an image with a custom key for offline retrieval
    /// - Parameters:
    ///   - url: The image URL to download
    ///   - key: Custom cache key
    func cacheImageWithCustomKey(url: URL, key: String) async {
        Logger.sync.debug("Caching image with custom key: \(key)")

        // Check if already cached
        if await isImageCached(forKey: key) {
            Logger.sync.debug("Image already cached with key: \(key)")
            return
        }

        // Download and cache with custom key
        let image = await downloadImage(from: url)

        if let image = image {
            try? await ImageCache.default.store(image, forKey: key)
            Logger.sync.info("✅ Cached image with custom key: \(key)")
        } else {
            Logger.sync.warning("❌ Failed to cache image with key: \(key)")
        }
    }

    /// Clears cached images from Kingfisher cache
    /// - Parameter urls: Array of image URLs to clear
    func clearCachedImages(urls: [URL]) async {
        guard !urls.isEmpty else { return }

        Logger.sync.info("Clearing Kingfisher cache for \(urls.count) images")

        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try? await KingfisherManager.shared.cache.removeImage(forKey: url.cacheKey)
                }
            }
        }

        Logger.sync.info("✅ Kingfisher cache cleared for \(urls.count) images")
    }

    /// Verifies that images are present in cache
    /// - Parameter urls: Array of URLs to verify
    func verifyPrefetchedImages(_ urls: [URL]) async {
        Logger.sync.info("🔍 Verifying prefetched images in cache...")

        var cachedCount = 0
        var missingCount = 0

        for url in urls {
            let isCached = await isImageCached(forKey: url.cacheKey)

            if isCached {
                cachedCount += 1
                Logger.sync.debug("✅ Verified in cache: \(url.absoluteString)")
            } else {
                missingCount += 1
                Logger.sync.warning("❌ NOT in cache after prefetch: \(url.absoluteString)")
            }
        }

        Logger.sync.info("📊 Cache verification: \(cachedCount) cached, \(missingCount) missing out of \(urls.count) total")
    }

    // MARK: - Private Helper Methods

    private func buildOfflineCachingOptions() -> KingfisherOptionsInfo {
        [
            .cacheOriginalImage,
            .diskCacheExpiration(.never), // Keep images as long as article is cached
            .backgroundDecode,
        ]
    }

    private func logPrefetchURLs(_ urls: [URL]) {
        for (index, url) in urls.enumerated() {
            Logger.sync.debug("[\(index + 1)/\(urls.count)] Prefetching: \(url.absoluteString)")
            Logger.sync.debug("   Cache key: \(url.cacheKey)")
        }
    }

    private func logPrefetchProgress(
        total: Int,
        completed: Int,
        failed: Int,
        skipped: Int
    ) {
        let progress = completed + failed + skipped
        Logger.sync.debug("Prefetch progress: \(progress)/\(total) - completed: \(completed), failed: \(failed), skipped: \(skipped)")
    }

    private func logPrefetchCompletion(
        total: Int,
        completed: Int,
        failed: Int,
        skipped: Int
    ) {
        Logger.sync.info("✅ Prefetch completed: \(completed)/\(total) images cached")

        if failed > 0 {
            Logger.sync.warning("❌ Failed to cache \(failed) images")
        }

        if skipped > 0 {
            Logger.sync.info("⏭️ Skipped \(skipped) images (already cached)")
        }
    }

    private func isImageCached(forKey key: String) async -> Bool {
        await withCheckedContinuation { continuation in
            ImageCache.default.retrieveImage(forKey: key) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image != nil)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func downloadImage(from url: URL) async -> KFCrossPlatformImage? {
        await withCheckedContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    Logger.sync.error("Failed to download image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
