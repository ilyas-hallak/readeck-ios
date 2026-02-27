//
//  EndpointValidatorTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 05.12.25.
//

import XCTest
@testable import readeck

final class EndpointValidatorTests: XCTestCase {

    // MARK: - Standard HTTPS URLs

    func testNormalize_FullHTTPSURL() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com"),
            "https://example.com"
        )
    }

    func testNormalize_DomainWithoutScheme_AddsHTTPS() {
        XCTAssertEqual(
            EndpointValidator.normalize("example.com"),
            "https://example.com"
        )
    }

    func testNormalize_DomainWithSubdomain() {
        XCTAssertEqual(
            EndpointValidator.normalize("api.example.com"),
            "https://api.example.com"
        )
    }

    func testNormalize_DomainWithWWW() {
        XCTAssertEqual(
            EndpointValidator.normalize("www.example.com"),
            "https://www.example.com"
        )
    }

    // MARK: - HTTP URLs (Critical for Tailscale)

    func testNormalize_ExplicitHTTP_PreservesHTTP() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://example.com"),
            "http://example.com"
        )
    }

    func testNormalize_HTTPWithTailscaleIP() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.80.0.1"),
            "http://100.80.0.1"
        )
    }

    func testNormalize_HTTPWithTailscaleIPAndPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.80.0.1:8080"),
            "http://100.80.0.1:8080"
        )
    }

    // MARK: - Custom Ports (Critical!)

    func testNormalize_HTTPSWithCustomPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com:8443"),
            "https://example.com:8443"
        )
    }

    func testNormalize_HTTPWithCustomPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://example.com:8080"),
            "http://example.com:8080"
        )
    }

    func testNormalize_DomainWithPortNoScheme_AddsHTTPS() {
        XCTAssertEqual(
            EndpointValidator.normalize("example.com:3000"),
            "https://example.com:3000"
        )
    }

    func testNormalize_PortOnly8080() {
        XCTAssertEqual(
            EndpointValidator.normalize("localhost:8080"),
            "https://localhost:8080"
        )
    }

    func testNormalize_PortOnly9090() {
        XCTAssertEqual(
            EndpointValidator.normalize("server:9090"),
            "https://server:9090"
        )
    }

    // MARK: - Tailscale IP Addresses

    func testNormalize_TailscaleIPNoScheme_AddsHTTPS() {
        XCTAssertEqual(
            EndpointValidator.normalize("100.80.0.1"),
            "https://100.80.0.1"
        )
    }

    func testNormalize_TailscaleIPWithPortNoScheme() {
        XCTAssertEqual(
            EndpointValidator.normalize("100.80.0.1:8080"),
            "https://100.80.0.1:8080"
        )
    }

    func testNormalize_TailscaleIPWithHTTPAndPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.95.200.50:3000"),
            "http://100.95.200.50:3000"
        )
    }

    func testNormalize_TailscaleIPWithHTTPSAndPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://100.120.10.5:8443"),
            "https://100.120.10.5:8443"
        )
    }

    // MARK: - Private IP Addresses

    func testNormalize_PrivateIPv4NoScheme() {
        XCTAssertEqual(
            EndpointValidator.normalize("192.168.1.100"),
            "https://192.168.1.100"
        )
    }

    func testNormalize_PrivateIPv4WithPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("192.168.1.100:9090"),
            "https://192.168.1.100:9090"
        )
    }

    func testNormalize_PrivateIPv4WithHTTPAndPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://192.168.1.100:8080"),
            "http://192.168.1.100:8080"
        )
    }

    func testNormalize_LocalhostWithHTTP() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://localhost:8080"),
            "http://localhost:8080"
        )
    }

    // MARK: - Trailing Slashes

    func testNormalize_RemovesTrailingSlash() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com/"),
            "https://example.com"
        )
    }

    func testNormalize_RemovesTrailingSlashFromPath() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com/api/"),
            "https://example.com/api"
        )
    }

    func testNormalize_RemovesTrailingSlashWithPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.80.0.1:8080/"),
            "http://100.80.0.1:8080"
        )
    }

    // MARK: - Query Parameters and Fragments

    func testNormalize_RemovesQueryParameters() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com?query=test"),
            "https://example.com"
        )
    }

    func testNormalize_RemovesFragment() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com#section"),
            "https://example.com"
        )
    }

    func testNormalize_RemovesQueryAndFragment() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com?query=test#section"),
            "https://example.com"
        )
    }

    func testNormalize_RemovesQueryWithPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://192.168.1.100:9090?debug=true"),
            "http://192.168.1.100:9090"
        )
    }

    func testNormalize_ComplexQueryParameters() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com/path?param1=value1&param2=value2"),
            "https://example.com/path"
        )
    }

    // MARK: - Paths

    func testNormalize_PreservesPath() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com/readeck"),
            "https://example.com/readeck"
        )
    }

    func testNormalize_PreservesNestedPath() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com/api/v1"),
            "https://example.com/api/v1"
        )
    }

    func testNormalize_PathWithPortNoScheme() {
        XCTAssertEqual(
            EndpointValidator.normalize("example.com:8080/readeck"),
            "https://example.com:8080/readeck"
        )
    }

    func testNormalize_HTTPWithPathAndPort() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.80.0.1:3000/api"),
            "http://100.80.0.1:3000/api"
        )
    }

    // MARK: - Whitespace Handling

    func testNormalize_TrimsLeadingWhitespace() {
        XCTAssertEqual(
            EndpointValidator.normalize("  https://example.com"),
            "https://example.com"
        )
    }

    func testNormalize_TrimsTrailingWhitespace() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com  "),
            "https://example.com"
        )
    }

    func testNormalize_TrimsBothWhitespace() {
        XCTAssertEqual(
            EndpointValidator.normalize("  https://example.com  "),
            "https://example.com"
        )
    }

    func testNormalize_TrimsWhitespaceFromComplexURL() {
        XCTAssertEqual(
            EndpointValidator.normalize("  http://100.80.0.1:8080/api  "),
            "http://100.80.0.1:8080/api"
        )
    }

    // MARK: - Edge Cases

    func testNormalize_EmptyString() {
        XCTAssertEqual(
            EndpointValidator.normalize(""),
            ""
        )
    }

    func testNormalize_OnlyWhitespace() {
        XCTAssertEqual(
            EndpointValidator.normalize("   "),
            ""
        )
    }

    func testNormalize_StandardPort80_Preserved() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://example.com:80"),
            "http://example.com:80"
        )
    }

    func testNormalize_StandardPort443_Preserved() {
        XCTAssertEqual(
            EndpointValidator.normalize("https://example.com:443"),
            "https://example.com:443"
        )
    }

    // MARK: - Complex Real-World Scenarios

    func testNormalize_TailscaleWithPathQueryAndTrailingSlash() {
        XCTAssertEqual(
            EndpointValidator.normalize("http://100.80.0.1:8080/readeck/?setup=true"),
            "http://100.80.0.1:8080/readeck"
        )
    }

    func testNormalize_UserInputWithEverything() {
        XCTAssertEqual(
            EndpointValidator.normalize("  http://192.168.1.50:9090/api/v1/?debug=true#main  "),
            "http://192.168.1.50:9090/api/v1"
        )
    }

    func testNormalize_InvalidScheme_ConvertsToHTTPS() {
        XCTAssertEqual(
            EndpointValidator.normalize("ftp://example.com"),
            "https://example.com"
        )
    }

    // MARK: - isValid Tests

    func testIsValid_ValidHTTPSURL() {
        XCTAssertTrue(EndpointValidator.isValid("https://example.com"))
    }

    func testIsValid_ValidHTTPURL() {
        XCTAssertTrue(EndpointValidator.isValid("http://example.com"))
    }

    func testIsValid_ValidDomainWithoutScheme() {
        XCTAssertTrue(EndpointValidator.isValid("example.com"))
    }

    func testIsValid_ValidTailscaleIP() {
        XCTAssertTrue(EndpointValidator.isValid("100.80.0.1:8080"))
    }

    func testIsValid_ValidIPWithPort() {
        XCTAssertTrue(EndpointValidator.isValid("192.168.1.100:9090"))
    }

    func testIsValid_EmptyString() {
        XCTAssertFalse(EndpointValidator.isValid(""))
    }

    func testIsValid_OnlyWhitespace() {
        XCTAssertFalse(EndpointValidator.isValid("   "))
    }

    func testIsValid_ValidWithPath() {
        XCTAssertTrue(EndpointValidator.isValid("https://example.com/api"))
    }

    func testIsValid_ValidHTTPWithPortAndPath() {
        XCTAssertTrue(EndpointValidator.isValid("http://100.80.0.1:3000/readeck"))
    }
}
