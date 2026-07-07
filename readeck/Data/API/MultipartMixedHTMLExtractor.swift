//
//  MultipartMixedHTMLExtractor.swift
//  readeck
//

import Foundation

/// Extracts the `Type: html` part for a given bookmark from a Readeck `POST /api/bookmarks/sync` body (`multipart/mixed`).
enum MultipartMixedHTMLExtractor {

    enum ExtractError: Error {
        case noBoundary
        case invalidEncoding
        case noHTMLPart
    }

    static func extractHTML(data: Data, contentTypeValue: String?, bookmarkId: String) throws -> String {
        guard let contentTypeValue else { throw ExtractError.noBoundary }
        guard let boundary = parseBoundary(from: contentTypeValue) else { throw ExtractError.noBoundary }
        guard let string = String(data: data, encoding: .utf8) else { throw ExtractError.invalidEncoding }
        return try extractHTML(string: string, boundary: boundary, bookmarkId: bookmarkId)
    }

    static func parseBoundary(from contentType: String) -> String? {
        let lower = contentType.lowercased()
        guard let r = lower.range(of: "boundary=") else { return nil }
        var tail = String(contentType[r.upperBound...]).trimmingCharacters(in: .whitespaces)
        if tail.hasPrefix("\"") {
            tail.removeFirst()
            if let endQuote = tail.firstIndex(of: "\"") {
                return String(tail[..<endQuote])
            }
        }
        if let semi = tail.firstIndex(of: ";") {
            tail = String(tail[..<semi])
        }
        return tail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractHTML(string: String, boundary: String, bookmarkId: String) throws -> String {
        let opening = "--\(boundary)\r\n"
        let openingLF = "--\(boundary)\n"
        var inner = string
        if inner.hasPrefix(opening) {
            inner.removeFirst(opening.count)
        } else if inner.hasPrefix(openingLF) {
            inner.removeFirst(openingLF.count)
        } else {
            throw ExtractError.noBoundary
        }

        let partSeparator = "\r\n--\(boundary)\r\n"
        var segments = inner.components(separatedBy: partSeparator)
        let closingOnly = "--\(boundary)--"
        let closingWithCRLF = "\r\n--\(boundary)--"

        for (index, var segment) in segments.enumerated() {
            segment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            if index == segments.count - 1 {
                if segment.hasSuffix(closingWithCRLF) {
                    segment = String(segment.dropLast(closingWithCRLF.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if segment.hasSuffix(closingOnly) {
                    segment = String(segment.dropLast(closingOnly.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            guard let headerEnd = segment.range(of: "\r\n\r\n") else { continue }
            let headerString = String(segment[..<headerEnd.lowerBound])
            var body = String(segment[headerEnd.upperBound...])
            body = body.trimmingCharacters(in: .whitespacesAndNewlines)

            let headers = parsePartHeaders(headerString)
            let typeValue = headers["type"]?.lowercased()
            let idValue = headers["bookmark-id"]

            if typeValue == "html", idValue == bookmarkId {
                return body
            }
        }

        throw ExtractError.noHTMLPart
    }

    private static func parsePartHeaders(_ block: String) -> [String: String] {
        var out: [String: String] = [:]
        let lines = block.components(separatedBy: "\r\n")
        for line in lines where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            out[name] = value
        }
        return out
    }
}
