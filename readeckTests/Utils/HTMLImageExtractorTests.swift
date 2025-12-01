//
//  HTMLImageExtractorTests.swift
//  readeckTests
//
//  Created by Claude on 30.11.25.
//

import Testing
import Foundation
@testable import readeck

@Suite("HTMLImageExtractor Tests")
struct HTMLImageExtractorTests {

    // MARK: - Test Data

    private let htmlWithImages = """
    <html>
        <body>
            <img src="https://example.com/image1.jpg" alt="Image 1">
            <img src="https://example.com/image2.png" />
            <img src="https://example.com/image3.gif">
        </body>
    </html>
    """

    private let htmlWithMixedURLs = """
    <html>
        <body>
            <img src="https://absolute.com/img.jpg">
            <img src="/relative/path.jpg">
            <img src="data:image/jpeg;base64,abc123">
            <img src="https://another.com/photo.png">
        </body>
    </html>
    """

    private let htmlWithoutImages = """
    <html>
        <body>
            <p>This is just text content with no images.</p>
            <div>Some more content</div>
        </body>
    </html>
    """

    private let htmlEmpty = ""

    // MARK: - Basic Functionality Tests

    @Test("Extract finds all absolute image URLs from HTML")
    func testExtractFindsAllImageURLs() {
        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlWithImages)

        #expect(imageURLs.count == 3)
        #expect(imageURLs.contains("https://example.com/image1.jpg"))
        #expect(imageURLs.contains("https://example.com/image2.png"))
        #expect(imageURLs.contains("https://example.com/image3.gif"))
    }

    @Test("Extract only includes absolute URLs with http or https")
    func testExtractOnlyIncludesAbsoluteURLs() {
        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlWithMixedURLs)

        #expect(imageURLs.count == 2)
        #expect(imageURLs.contains("https://absolute.com/img.jpg"))
        #expect(imageURLs.contains("https://another.com/photo.png"))

        // Verify relative and data URIs are NOT included
        #expect(!imageURLs.contains("/relative/path.jpg"))
        #expect(!imageURLs.contains(where: { $0.hasPrefix("data:") }))
    }

    @Test("Extract returns empty array when HTML has no images")
    func testExtractReturnsEmptyArrayWhenNoImages() {
        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlWithoutImages)

        #expect(imageURLs.isEmpty)
    }

    // MARK: - Edge Case Tests

    @Test("Extract ignores relative URLs without http prefix")
    func testExtractIgnoresRelativeURLs() {
        let htmlWithRelative = """
        <img src="/images/logo.png">
        <img src="./photos/pic.jpg">
        <img src="../assets/icon.svg">
        <img src="https://valid.com/image.jpg">
        """

        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlWithRelative)

        #expect(imageURLs.count == 1)
        #expect(imageURLs.first == "https://valid.com/image.jpg")
    }

    @Test("Extract handles empty HTML string")
    func testExtractHandlesEmptyHTML() {
        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlEmpty)

        #expect(imageURLs.isEmpty)
    }

    @Test("Extract ignores data URI images")
    func testExtractIgnoresDataURIs() {
        let htmlWithDataURI = """
        <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2w==">
        <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA">
        <img src="https://example.com/real-image.jpg">
        """

        let extractor = HTMLImageExtractor()
        let imageURLs = extractor.extract(from: htmlWithDataURI)

        #expect(imageURLs.count == 1)
        #expect(imageURLs.first == "https://example.com/real-image.jpg")

        // Verify no data URIs are included
        for url in imageURLs {
            #expect(!url.hasPrefix("data:"))
        }
    }

    // MARK: - Hero/Thumbnail Tests

    @Test("Extract with hero image prepends it to array")
    func testExtractWithHeroImagePrependsToArray() {
        let extractor = HTMLImageExtractor()
        let heroURL = "https://example.com/hero.jpg"

        let imageURLs = extractor.extract(
            from: htmlWithImages,
            heroImageURL: heroURL,
            thumbnailURL: nil
        )

        #expect(imageURLs.count == 4) // 3 from HTML + 1 hero
        #expect(imageURLs.first == heroURL) // Hero should be at position 0
        #expect(imageURLs.contains("https://example.com/image1.jpg"))
    }

    @Test("Extract with thumbnail prepends it when no hero image")
    func testExtractWithThumbnailPrependsWhenNoHero() {
        let extractor = HTMLImageExtractor()
        let thumbnailURL = "https://example.com/thumbnail.jpg"

        let imageURLs = extractor.extract(
            from: htmlWithImages,
            heroImageURL: nil,
            thumbnailURL: thumbnailURL
        )

        #expect(imageURLs.count == 4) // 3 from HTML + 1 thumbnail
        #expect(imageURLs.first == thumbnailURL) // Thumbnail should be at position 0
    }

    @Test("Extract prefers hero image over thumbnail when both provided")
    func testExtractPrefersHeroOverThumbnail() {
        let extractor = HTMLImageExtractor()
        let heroURL = "https://example.com/hero.jpg"
        let thumbnailURL = "https://example.com/thumbnail.jpg"

        let imageURLs = extractor.extract(
            from: htmlWithImages,
            heroImageURL: heroURL,
            thumbnailURL: thumbnailURL
        )

        #expect(imageURLs.count == 4) // 3 from HTML + 1 hero (thumbnail ignored)
        #expect(imageURLs.first == heroURL) // Hero takes precedence
        #expect(!imageURLs.contains(thumbnailURL)) // Thumbnail should NOT be added
    }

    @Test("Extract with hero and thumbnail but no HTML images")
    func testExtractWithHeroAndNoHTMLImages() {
        let extractor = HTMLImageExtractor()
        let heroURL = "https://example.com/hero.jpg"

        let imageURLs = extractor.extract(
            from: htmlWithoutImages,
            heroImageURL: heroURL,
            thumbnailURL: nil
        )

        #expect(imageURLs.count == 1)
        #expect(imageURLs.first == heroURL)
    }
}
