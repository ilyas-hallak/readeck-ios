//
//  BookmarkArticleRecoveryAPITests.swift
//  readeckTests
//

import XCTest
@testable import readeck

private final class ArticleRecoveryURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// `URLSession` may supply `httpBodyStream` instead of `httpBody` for POST requests.
    private static func requestBodyData(for request: URLRequest) -> Data {
        if let body = request.httpBody, !body.isEmpty { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 { break }
            if read == 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "mock.example.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            var canonical = request
            if canonical.httpBody == nil || canonical.httpBody?.isEmpty == true {
                let body = Self.requestBodyData(for: canonical)
                canonical.httpBody = body
            }
            let (response, data) = try handler(canonical)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class BookmarkArticleRecoveryAPITests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(ArticleRecoveryURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(ArticleRecoveryURLProtocol.self)
        ArticleRecoveryURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testGetBookmarkArticle_502_thenGzipRetryReturns200() async throws {
        ArticleRecoveryURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            XCTAssertTrue(path.contains("/article"))
            let enc = request.value(forHTTPHeaderField: "Accept-Encoding") ?? ""
            if !enc.contains("gzip") {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 502,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (response, Data("bad".utf8))
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/html; charset=utf-8"]
            )!
            return (response, "<p>ok</p>".data(using: .utf8)!)
        }

        let api = API(tokenProvider: TestMockTokenProvider())
        let html = try await api.getBookmarkArticle(id: "bm1")
        XCTAssertEqual(html, "<p>ok</p>")
    }

    func testGetBookmarkArticle_double502_thenSyncMultipartReturnsHTML() async throws {
        let boundary = "sep9"
        let multipartBody = [
            "--\(boundary)",
            "Type: html",
            "Bookmark-Id: bm1",
            "",
            "<article>x</article>",
            "--\(boundary)--",
            ""
        ].joined(separator: "\r\n")

        ArticleRecoveryURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            if path.hasSuffix("/article") {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 502,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (response, Data())
            }
            if path.hasSuffix("/sync") {
                XCTAssertEqual(request.httpMethod, "POST")
                let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                XCTAssertTrue(bodyString.contains("\"with_html\":true"))
                XCTAssertTrue(bodyString.contains("\"with_json\":false"))
                XCTAssertTrue(bodyString.contains("\"with_resources\":false"))
                XCTAssertTrue(bodyString.contains("bm1"))
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "multipart/mixed; boundary=\(boundary)"]
                )!
                return (response, Data(multipartBody.utf8))
            }
            XCTFail("Unexpected path: \(path)")
            throw URLError(.badURL)
        }

        let api = API(tokenProvider: TestMockTokenProvider())
        let html = try await api.getBookmarkArticle(id: "bm1")
        XCTAssertEqual(html, "<article>x</article>")
    }

    func testGetBookmarkArticle_allPathsFail_throws502() async throws {
        ArticleRecoveryURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 502,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        let api = API(tokenProvider: TestMockTokenProvider())
        do {
            _ = try await api.getBookmarkArticle(id: "bm1")
            XCTFail("Expected error")
        } catch let error as APIError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 502)
            } else {
                XCTFail("Wrong error \(error)")
            }
        }
    }
}
