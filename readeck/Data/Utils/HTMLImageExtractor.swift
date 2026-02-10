//
//  HTMLImageExtractor.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Foundation

/// Utility for extracting image URLs from HTML content
struct HTMLImageExtractor {

    /// Extracts all image URLs from HTML using regex
    /// - Parameter html: The HTML string to parse
    /// - Returns: Array of absolute image URLs (http/https only)
    func extract(from html: String) -> [String] {
        var imageURLs: [String] = []

        // Simple regex pattern for img tags
        let pattern = #"<img[^>]+src="([^"]+)""#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return imageURLs
        }

        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

        for result in results {
            if result.numberOfRanges >= 2 {
                let urlRange = result.range(at: 1)
                if let url = nsString.substring(with: urlRange) as String?,
                   url.hasPrefix("http") { // Only include absolute URLs
                    imageURLs.append(url)
                }
            }
        }

        Logger.sync.debug("Extracted \(imageURLs.count) image URLs from HTML")
        return imageURLs
    }

    /// Extracts image URLs from HTML and optionally prepends hero/thumbnail image
    /// - Parameters:
    ///   - html: The HTML string to parse
    ///   - heroImageURL: Optional hero image URL to prepend
    ///   - thumbnailURL: Optional thumbnail URL to prepend if no hero image
    /// - Returns: Array of image URLs with hero/thumbnail first if provided
    func extract(from html: String, heroImageURL: String? = nil, thumbnailURL: String? = nil) -> [String] {
        var imageURLs = extract(from: html)

        // Prepend hero or thumbnail image if available
        if let heroURL = heroImageURL {
            imageURLs.insert(heroURL, at: 0)
            Logger.sync.debug("Added hero image: \(heroURL)")
        } else if let thumbURL = thumbnailURL {
            imageURLs.insert(thumbURL, at: 0)
            Logger.sync.debug("Added thumbnail image: \(thumbURL)")
        }

        return imageURLs
    }
}
