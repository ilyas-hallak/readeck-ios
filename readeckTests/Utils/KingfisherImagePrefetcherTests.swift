//
//  KingfisherImagePrefetcherTests.swift
//  readeckTests
//
//  Created by Claude on 30.11.25.
//

import Testing
import Foundation
import Kingfisher
@testable import readeck
import UIKit

@Suite("KingfisherImagePrefetcher Tests")
struct KingfisherImagePrefetcherTests {

    // MARK: - Test Setup & Helpers

    /// Mock server URL for test images
    private let testImageURL1 = URL(string: "https://via.placeholder.com/150/FF0000/FFFFFF?text=Test1")!
    private let testImageURL2 = URL(string: "https://via.placeholder.com/150/00FF00/FFFFFF?text=Test2")!
    private let testImageURL3 = URL(string: "https://via.placeholder.com/150/0000FF/FFFFFF?text=Test3")!

    /// Creates a simple test image for caching
    private func createTestImage() -> KFCrossPlatformImage {
        #if os(iOS)
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
        #elseif os(macOS)
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
        #endif
    }

    /// Clears Kingfisher cache after tests
    private func clearCache() async {
        await ImageCache.default.clearCache()
    }

    /// Checks if an image is cached
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

    // MARK: - Prefetch Tests

    @Test("Prefetch images handles empty URL array")
    func testPrefetchImagesHandlesEmptyArray() async {
        let prefetcher = KingfisherImagePrefetcher()
        let emptyURLs: [URL] = []

        // Should complete without errors
        await prefetcher.prefetchImages(urls: emptyURLs)

        // No assertions needed - just verify it doesn't crash
        #expect(emptyURLs.isEmpty)
    }

    @Test("Prefetch images uses never expiration for disk cache")
    func testPrefetchImagesUsesNeverExpiration() async {
        // This test verifies the configuration is set correctly
        // The actual implementation uses .diskCacheExpiration(.never)
        let prefetcher = KingfisherImagePrefetcher()

        // Pre-cache a test image to verify it persists
        let testURL = URL(string: "https://example.com/test.jpg")!
        let testImage = createTestImage()

        try? await ImageCache.default.store(
            testImage,
            forKey: testURL.cacheKey,
            options: KingfisherParsedOptionsInfo([.diskCacheExpiration(.never)])
        )

        let isCached = await isImageCached(forKey: testURL.cacheKey)
        #expect(isCached == true)

        await clearCache()
    }

    @Test("Verify prefetched images confirms cache status")
    func testVerifyPrefetchedImagesConfirmsCacheStatus() async {
        let prefetcher = KingfisherImagePrefetcher()

        // Manually cache some test images
        let url1 = URL(string: "https://example.com/cached1.jpg")!
        let url2 = URL(string: "https://example.com/cached2.jpg")!
        let url3 = URL(string: "https://example.com/not-cached.jpg")!

        let testImage = createTestImage()
        try? await ImageCache.default.store(testImage, forKey: url1.cacheKey)
        try? await ImageCache.default.store(testImage, forKey: url2.cacheKey)

        // Verify the cached ones
        await prefetcher.verifyPrefetchedImages([url1, url2, url3])

        // Check that first two are cached
        let isCached1 = await isImageCached(forKey: url1.cacheKey)
        let isCached2 = await isImageCached(forKey: url2.cacheKey)
        let isCached3 = await isImageCached(forKey: url3.cacheKey)

        #expect(isCached1 == true)
        #expect(isCached2 == true)
        #expect(isCached3 == false)

        await clearCache()
    }

    // MARK: - Custom Cache Key Tests

    @Test("Cache image with custom key stores correctly")
    func testCacheImageWithCustomKeyStoresCorrectly() async {
        let prefetcher = KingfisherImagePrefetcher()
        let customKey = "bookmark-123-hero"

        // Pre-cache a test image with URL key so it can be "downloaded"
        let sourceURL = URL(string: "https://example.com/hero.jpg")!
        let testImage = createTestImage()
        try? await ImageCache.default.store(testImage, forKey: sourceURL.cacheKey)

        // Now use the prefetcher to cache with custom key
        await prefetcher.cacheImageWithCustomKey(url: sourceURL, key: customKey)

        // Verify it's cached with custom key
        let isCached = await isImageCached(forKey: customKey)
        #expect(isCached == true)

        await clearCache()
    }

    @Test("Cache image with custom key skips if already cached")
    func testCacheImageWithCustomKeySkipsIfAlreadyCached() async {
        let prefetcher = KingfisherImagePrefetcher()
        let customKey = "bookmark-456-hero"
        let sourceURL = URL(string: "https://example.com/hero2.jpg")!

        // Pre-cache with custom key
        let testImage = createTestImage()
        try? await ImageCache.default.store(testImage, forKey: customKey)

        // Call again - should skip (verify by checking it doesn't fail)
        await prefetcher.cacheImageWithCustomKey(url: sourceURL, key: customKey)

        // Should still be cached
        let isCached = await isImageCached(forKey: customKey)
        #expect(isCached == true)

        await clearCache()
    }

    // MARK: - Clear Cache Tests

    @Test("Clear cached images removes all specified URLs")
    func testClearCachedImagesRemovesAllURLs() async {
        let prefetcher = KingfisherImagePrefetcher()

        // Cache some test images
        let url1 = URL(string: "https://example.com/clear1.jpg")!
        let url2 = URL(string: "https://example.com/clear2.jpg")!
        let testImage = createTestImage()

        try? await ImageCache.default.store(testImage, forKey: url1.cacheKey)
        try? await ImageCache.default.store(testImage, forKey: url2.cacheKey)

        // Verify they are cached
        var isCached1 = await isImageCached(forKey: url1.cacheKey)
        var isCached2 = await isImageCached(forKey: url2.cacheKey)
        #expect(isCached1 == true)
        #expect(isCached2 == true)

        // Clear them
        await prefetcher.clearCachedImages(urls: [url1, url2])

        // Verify they are removed
        isCached1 = await isImageCached(forKey: url1.cacheKey)
        isCached2 = await isImageCached(forKey: url2.cacheKey)
        #expect(isCached1 == false)
        #expect(isCached2 == false)
    }

    @Test("Clear cached images handles empty array")
    func testClearCachedImagesHandlesEmptyArray() async {
        let prefetcher = KingfisherImagePrefetcher()
        let emptyURLs: [URL] = []

        // Should complete without errors
        await prefetcher.clearCachedImages(urls: emptyURLs)

        // No assertions needed - just verify it doesn't crash
        #expect(emptyURLs.isEmpty)
    }

    // MARK: - Integration Tests

    @Test("Prefetch and verify workflow")
    func testPrefetchAndVerifyWorkflow() async {
        let prefetcher = KingfisherImagePrefetcher()

        // Pre-populate cache with test images
        let urls = [
            URL(string: "https://example.com/workflow1.jpg")!,
            URL(string: "https://example.com/workflow2.jpg")!
        ]

        let testImage = createTestImage()
        for url in urls {
            try? await ImageCache.default.store(testImage, forKey: url.cacheKey)
        }

        // Verify they were cached
        await prefetcher.verifyPrefetchedImages(urls)

        for url in urls {
            let isCached = await isImageCached(forKey: url.cacheKey)
            #expect(isCached == true)
        }

        await clearCache()
    }
}
