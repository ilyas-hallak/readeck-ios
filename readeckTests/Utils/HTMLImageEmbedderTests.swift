//
//  HTMLImageEmbedderTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Testing
import Foundation
import Kingfisher
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import readeck

@Suite("HTMLImageEmbedder Tests")
struct HTMLImageEmbedderTests {

    // MARK: - Test Data

    private let htmlWithImages = """
    <html>
        <body>
            <img src="https://example.com/image1.jpg" alt="Image 1">
            <img src="https://example.com/image2.png">
        </body>
    </html>
    """

    private let htmlWithoutImages = """
    <html>
        <body>
            <p>Just text, no images here.</p>
        </body>
    </html>
    """

    private let htmlWithDataURI = """
    <html>
        <body>
            <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2w==">
            <img src="https://example.com/new-image.jpg">
        </body>
    </html>
    """

    // MARK: - Helper Methods

    /// Creates a test image and caches it in Kingfisher for testing
    private func cacheTestImage(url: URL) async {
        // Create a simple 1x1 pixel red image for testing
        #if os(iOS)
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        #elseif os(macOS)
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        image.unlockFocus()
        #endif

        if let image = image {
            // Store both in memory and on disk for testing
            let options = KingfisherParsedOptionsInfo([
                .cacheOriginalImage,
                .diskCacheExpiration(.never)
            ])
            try? await ImageCache.default.store(image, forKey: url.cacheKey, options: options)

            // Small delay to ensure cache write completes
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    /// Clears all cached images after tests
    private func clearTestCache() async {
        // Clear both memory and disk cache
        await ImageCache.default.clearMemoryCache()
        await ImageCache.default.clearDiskCache()

        // Small delay to ensure cache clear completes
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    // MARK: - Basic Functionality Tests

    @Test("Embed Base64 images converts URLs to data URIs")
    func testEmbedBase64ImagesConvertsURLs() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()

        // Cache test images first
        let url1 = URL(string: "https://example.com/image1.jpg")!
        let url2 = URL(string: "https://example.com/image2.png")!

        await cacheTestImage(url: url1)
        await cacheTestImage(url: url2)

        let result = await embedder.embedBase64Images(in: htmlWithImages)

        // Verify images were embedded as Base64
        #expect(result.contains("data:image/jpeg;base64,"))
        #expect(!result.contains("https://example.com/image1.jpg"))
        #expect(!result.contains("https://example.com/image2.png"))

        await clearTestCache()
    }

    @Test("Embed Base64 images skips images not in cache")
    func testEmbedBase64ImagesSkipsUncachedImages() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()

        // Don't cache any images - all should be skipped
        let result = await embedder.embedBase64Images(in: htmlWithImages)

        // Original URLs should remain unchanged
        #expect(result.contains("https://example.com/image1.jpg"))
        #expect(result.contains("https://example.com/image2.png"))
        #expect(!result.contains("data:image/jpeg;base64,"))
    }

    @Test("Embed Base64 images increases HTML size")
    func testEmbedBase64ImagesIncreasesHTMLSize() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()

        // Cache one test image
        let url1 = URL(string: "https://example.com/image1.jpg")!
        await cacheTestImage(url: url1)

        let originalSize = htmlWithImages.utf8.count
        let result = await embedder.embedBase64Images(in: htmlWithImages)
        let newSize = result.utf8.count

        // Base64 encoded images should make HTML larger
        #expect(newSize > originalSize)

        await clearTestCache()
    }

    @Test("Embed Base64 images uses JPEG format with quality 0.85")
    func testEmbedBase64ImagesUsesJPEGFormat() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()

        let url = URL(string: "https://example.com/image1.jpg")!
        await cacheTestImage(url: url)

        let result = await embedder.embedBase64Images(in: htmlWithImages)

        // Verify data URI uses JPEG format
        #expect(result.contains("data:image/jpeg;base64,"))

        await clearTestCache()
    }

    // MARK: - Edge Case Tests

    @Test("Embed Base64 images handles empty HTML")
    func testEmbedBase64ImagesHandlesEmptyHTML() async {
        let embedder = HTMLImageEmbedder()
        let emptyHTML = ""

        let result = await embedder.embedBase64Images(in: emptyHTML)

        #expect(result.isEmpty)
        #expect(result == emptyHTML)
    }

    @Test("Embed Base64 images handles HTML without images")
    func testEmbedBase64ImagesHandlesHTMLWithoutImages() async {
        let embedder = HTMLImageEmbedder()

        let result = await embedder.embedBase64Images(in: htmlWithoutImages)

        // Should return unchanged HTML
        #expect(result == htmlWithoutImages)
        #expect(!result.contains("data:image"))
    }

    @Test("Embed Base64 images skips already embedded data URIs")
    func testEmbedBase64ImagesSkipsDataURIs() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()

        // Cache the non-data URI image
        let url = URL(string: "https://example.com/new-image.jpg")!
        await cacheTestImage(url: url)

        let result = await embedder.embedBase64Images(in: htmlWithDataURI)

        // Original data URI should remain
        #expect(result.contains("data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2w=="))

        // New image should be embedded
        #expect(!result.contains("https://example.com/new-image.jpg"))

        await clearTestCache()
    }

    @Test("Embed Base64 images processes multiple images correctly")
    func testEmbedBase64ImagesProcessesMultipleImages() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()
        let htmlMultiple = """
        <img src="https://example.com/img1.jpg">
        <img src="https://example.com/img2.jpg">
        <img src="https://example.com/img3.jpg">
        """

        // Cache all three images
        for i in 1...3 {
            let url = URL(string: "https://example.com/img\(i).jpg")!
            await cacheTestImage(url: url)
        }

        let result = await embedder.embedBase64Images(in: htmlMultiple)

        // All three should be embedded
        let dataURICount = result.components(separatedBy: "data:image/jpeg;base64,").count - 1
        #expect(dataURICount == 3)

        // None of the original URLs should remain
        #expect(!result.contains("https://example.com/img1.jpg"))
        #expect(!result.contains("https://example.com/img2.jpg"))
        #expect(!result.contains("https://example.com/img3.jpg"))

        await clearTestCache()
    }

    // MARK: - Statistics & Logging Tests

    @Test("Embed Base64 images tracks success and failure counts")
    func testEmbedBase64ImagesTracksStatistics() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()
        let htmlMixed = """
        <img src="https://cached.com/image.jpg">
        <img src="https://not-cached.com/image.jpg">
        """

        // Cache only the first image
        let cachedURL = URL(string: "https://cached.com/image.jpg")!
        await cacheTestImage(url: cachedURL)

        let result = await embedder.embedBase64Images(in: htmlMixed)

        // First image should be embedded
        #expect(result.contains("data:image/jpeg;base64,"))
        #expect(!result.contains("https://cached.com/image.jpg"))

        // Second image should remain as URL
        #expect(result.contains("https://not-cached.com/image.jpg"))

        await clearTestCache()
    }

    @Test("Embed Base64 images handles invalid URLs gracefully")
    func testEmbedBase64ImagesHandlesInvalidURLs() async {
        // Clear cache first to ensure clean state
        await clearTestCache()

        let embedder = HTMLImageEmbedder()
        let htmlInvalid = """
        <img src="not a valid url">
        <img src="https://valid.com/image.jpg">
        """

        let url = URL(string: "https://valid.com/image.jpg")!
        await cacheTestImage(url: url)

        let result = await embedder.embedBase64Images(in: htmlInvalid)

        // Invalid URL should remain unchanged
        #expect(result.contains("not a valid url"))

        // Valid URL should be embedded
        #expect(!result.contains("https://valid.com/image.jpg"))
        #expect(result.contains("data:image/jpeg;base64,"))

        await clearTestCache()
    }
}
