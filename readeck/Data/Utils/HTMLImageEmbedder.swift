//
//  HTMLImageEmbedder.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Foundation
import Kingfisher

/// Utility for embedding images as Base64 data URIs in HTML
struct HTMLImageEmbedder {

    private let imageExtractor = HTMLImageExtractor()

    /// Embeds all images in HTML as Base64 data URIs for offline viewing
    /// - Parameter html: The HTML string containing image tags
    /// - Returns: Modified HTML with images embedded as Base64
    func embedBase64Images(in html: String) async -> String {
        Logger.sync.info("🔄 Starting Base64 image embedding for offline HTML")

        var modifiedHTML = html
        let imageURLs = imageExtractor.extract(from: html)

        Logger.sync.info("📊 Found \(imageURLs.count) images to embed")

        var stats = EmbedStatistics()

        for (index, imageURL) in imageURLs.enumerated() {
            Logger.sync.debug("Processing image \(index + 1)/\(imageURLs.count): \(imageURL)")

            guard let url = URL(string: imageURL) else {
                Logger.sync.warning("❌ Invalid URL: \(imageURL)")
                stats.failedCount += 1
                continue
            }

            // Try to get image from Kingfisher cache
            guard let image = await retrieveImageFromCache(url: url) else {
                Logger.sync.warning("❌ Image not found in cache: \(imageURL)")
                stats.failedCount += 1
                continue
            }

            // Convert to Base64 and embed
            if let base64DataURI = convertToBase64DataURI(image: image) {
                let beforeLength = modifiedHTML.count
                modifiedHTML = modifiedHTML.replacingOccurrences(of: imageURL, with: base64DataURI)
                let afterLength = modifiedHTML.count

                if afterLength > beforeLength {
                    Logger.sync.debug("✅ Embedded image \(index + 1) as Base64")
                    stats.successCount += 1
                } else {
                    Logger.sync.warning("⚠️ Image URL found but not replaced in HTML: \(imageURL)")
                    stats.failedCount += 1
                }
            } else {
                Logger.sync.warning("❌ Failed to convert image to Base64: \(imageURL)")
                stats.failedCount += 1
            }
        }

        logEmbedResults(stats: stats, originalSize: html.utf8.count, finalSize: modifiedHTML.utf8.count)
        return modifiedHTML
    }

    // MARK: - Private Helper Methods

    private func retrieveImageFromCache(url: URL) async -> KFCrossPlatformImage? {
        await withCheckedContinuation { continuation in
            KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image)
                case .failure(let error):
                    Logger.sync.error("❌ Kingfisher cache retrieval error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func convertToBase64DataURI(image: KFCrossPlatformImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }

    private func logEmbedResults(stats: EmbedStatistics, originalSize: Int, finalSize: Int) {
        let total = stats.successCount + stats.failedCount
        let growth = finalSize - originalSize

        Logger.sync.info("✅ Base64 embedding complete: \(stats.successCount) succeeded, \(stats.failedCount) failed out of \(total) images")
        Logger.sync.info("📈 HTML size: \(originalSize) → \(finalSize) bytes (growth: \(growth) bytes)")
    }
}

// MARK: - Helper Types

private struct EmbedStatistics {
    var successCount = 0
    var failedCount = 0
}
