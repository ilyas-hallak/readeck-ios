//
//  SemanticVersion.swift
//  readeck
//
//  Created by Ilyas Hallak on 04.09.26.
//

import Foundation

/// A comparable major/minor/patch version.
///
/// Readeck reports its version in `/api/info` as `version.canonical`, which in
/// practice ranges from plain "0.23.2" over shortened "0.23" to development
/// builds like "0.23.2-rc1" or "0.23.2+build.5". Comparing those strings
/// lexicographically is wrong ("0.9.0" > "0.10.0"), so every capability check
/// goes through this type instead.
///
/// Pre-release and build metadata are parsed but deliberately ignored for
/// ordering: a release candidate of 0.23.2 already carries the features of
/// 0.23.2, and treating it as "less than" would disable them for testers.
struct SemanticVersion: Comparable, Equatable, Hashable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses a version string, returning `nil` when it cannot be understood.
    ///
    /// Accepted shapes: "1", "0.23", "0.23.2", "v0.23.2", "0.23.2-rc1",
    /// "0.23.2+build.5". A leading "v" is stripped, everything from the first
    /// "-" or "+" is dropped, and missing components default to 0.
    ///
    /// Returning `nil` instead of a default is intentional. The previous
    /// approach silently swallowed unparsable components, which turned a
    /// version like "0.23.2-rc1" into a server that appeared to support
    /// nothing.
    init?(_ string: String) {
        var text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if text.first == "v" || text.first == "V" {
            text.removeFirst()
        }

        // Build metadata first, then pre-release: "0.23.2-rc1+build.5".
        if let plusIndex = text.firstIndex(of: "+") {
            text = String(text[text.startIndex..<plusIndex])
        }
        if let dashIndex = text.firstIndex(of: "-") {
            text = String(text[text.startIndex..<dashIndex])
        }

        // Keep empty subsequences so that "0.23." is rejected instead of
        // quietly becoming 0.23.0.
        let components = text.split(separator: ".", omittingEmptySubsequences: false)
        guard !components.isEmpty else { return nil }

        // Only the first three components carry meaning. Anything beyond that
        // (some build pipelines append a revision) is tolerated and ignored.
        var numbers: [Int] = []
        for component in components.prefix(3) {
            guard !component.isEmpty,
                  component.allSatisfy(\.isNumber),
                  let number = Int(component) else { return nil }
            numbers.append(number)
        }

        self.major = numbers[0]
        self.minor = numbers.count > 1 ? numbers[1] : 0
        self.patch = numbers.count > 2 ? numbers[2] : 0
    }

    var description: String { "\(major).\(minor).\(patch)" }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
