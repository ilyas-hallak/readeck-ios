//
//  EndpointValidatorTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 05.12.25.
//

import Testing
@testable import readeck

@Suite("Endpoint Validator Tests")
struct EndpointValidatorTests {

    // MARK: - Standard HTTPS URLs

    @Test("Normalize full HTTPS URL")
    func normalize_FullHTTPSURL() {
        #expect(
            EndpointValidator.normalize("https://example.com") ==
            "https://example.com"
        )
    }

    @Test("Normalize domain without scheme adds HTTPS")
    func normalize_DomainWithoutScheme_AddsHTTPS() {
        #expect(
            EndpointValidator.normalize("example.com") ==
            "https://example.com"
        )
    }

    @Test("Normalize domain with subdomain")
    func normalize_DomainWithSubdomain() {
        #expect(
            EndpointValidator.normalize("api.example.com") ==
            "https://api.example.com"
        )
    }

    @Test("Normalize domain with WWW")
    func normalize_DomainWithWWW() {
        #expect(
            EndpointValidator.normalize("www.example.com") ==
            "https://www.example.com"
        )
    }

    // MARK: - HTTP URLs (Critical for Tailscale)

    @Test("Normalize explicit HTTP preserves HTTP")
    func normalize_ExplicitHTTP_PreservesHTTP() {
        #expect(
            EndpointValidator.normalize("http://example.com") ==
            "http://example.com"
        )
    }

    @Test("Normalize HTTP with Tailscale IP")
    func normalize_HTTPWithTailscaleIP() {
        #expect(
            EndpointValidator.normalize("http://100.80.0.1") ==
            "http://100.80.0.1"
        )
    }

    @Test("Normalize HTTP with Tailscale IP and port")
    func normalize_HTTPWithTailscaleIPAndPort() {
        #expect(
            EndpointValidator.normalize("http://100.80.0.1:8080") ==
            "http://100.80.0.1:8080"
        )
    }

    // MARK: - Custom Ports (Critical!)

    @Test("Normalize HTTPS with custom port")
    func normalize_HTTPSWithCustomPort() {
        #expect(
            EndpointValidator.normalize("https://example.com:8443") ==
            "https://example.com:8443"
        )
    }

    @Test("Normalize HTTP with custom port")
    func normalize_HTTPWithCustomPort() {
        #expect(
            EndpointValidator.normalize("http://example.com:8080") ==
            "http://example.com:8080"
        )
    }

    @Test("Normalize domain with port and no scheme adds HTTPS")
    func normalize_DomainWithPortNoScheme_AddsHTTPS() {
        #expect(
            EndpointValidator.normalize("example.com:3000") ==
            "https://example.com:3000"
        )
    }

    @Test("Normalize port only 8080")
    func normalize_PortOnly8080() {
        #expect(
            EndpointValidator.normalize("localhost:8080") ==
            "https://localhost:8080"
        )
    }

    @Test("Normalize port only 9090")
    func normalize_PortOnly9090() {
        #expect(
            EndpointValidator.normalize("server:9090") ==
            "https://server:9090"
        )
    }

    // MARK: - Tailscale IP Addresses

    @Test("Normalize Tailscale IP without scheme adds HTTPS")
    func normalize_TailscaleIPNoScheme_AddsHTTPS() {
        #expect(
            EndpointValidator.normalize("100.80.0.1") ==
            "https://100.80.0.1"
        )
    }

    @Test("Normalize Tailscale IP with port and no scheme")
    func normalize_TailscaleIPWithPortNoScheme() {
        #expect(
            EndpointValidator.normalize("100.80.0.1:8080") ==
            "https://100.80.0.1:8080"
        )
    }

    @Test("Normalize Tailscale IP with HTTP and port")
    func normalize_TailscaleIPWithHTTPAndPort() {
        #expect(
            EndpointValidator.normalize("http://100.95.200.50:3000") ==
            "http://100.95.200.50:3000"
        )
    }

    @Test("Normalize Tailscale IP with HTTPS and port")
    func normalize_TailscaleIPWithHTTPSAndPort() {
        #expect(
            EndpointValidator.normalize("https://100.120.10.5:8443") ==
            "https://100.120.10.5:8443"
        )
    }

    // MARK: - Private IP Addresses

    @Test("Normalize private IPv4 without scheme")
    func normalize_PrivateIPv4NoScheme() {
        #expect(
            EndpointValidator.normalize("192.168.1.100") ==
            "https://192.168.1.100"
        )
    }

    @Test("Normalize private IPv4 with port")
    func normalize_PrivateIPv4WithPort() {
        #expect(
            EndpointValidator.normalize("192.168.1.100:9090") ==
            "https://192.168.1.100:9090"
        )
    }

    @Test("Normalize private IPv4 with HTTP and port")
    func normalize_PrivateIPv4WithHTTPAndPort() {
        #expect(
            EndpointValidator.normalize("http://192.168.1.100:8080") ==
            "http://192.168.1.100:8080"
        )
    }

    @Test("Normalize localhost with HTTP")
    func normalize_LocalhostWithHTTP() {
        #expect(
            EndpointValidator.normalize("http://localhost:8080") ==
            "http://localhost:8080"
        )
    }

    // MARK: - Trailing Slashes

    @Test("Normalize removes trailing slash")
    func normalize_RemovesTrailingSlash() {
        #expect(
            EndpointValidator.normalize("https://example.com/") ==
            "https://example.com"
        )
    }

    @Test("Normalize removes trailing slash from path")
    func normalize_RemovesTrailingSlashFromPath() {
        #expect(
            EndpointValidator.normalize("https://example.com/api/") ==
            "https://example.com/api"
        )
    }

    @Test("Normalize removes trailing slash with port")
    func normalize_RemovesTrailingSlashWithPort() {
        #expect(
            EndpointValidator.normalize("http://100.80.0.1:8080/") ==
            "http://100.80.0.1:8080"
        )
    }

    // MARK: - Query Parameters and Fragments

    @Test("Normalize removes query parameters")
    func normalize_RemovesQueryParameters() {
        #expect(
            EndpointValidator.normalize("https://example.com?query=test") ==
            "https://example.com"
        )
    }

    @Test("Normalize removes fragment")
    func normalize_RemovesFragment() {
        #expect(
            EndpointValidator.normalize("https://example.com#section") ==
            "https://example.com"
        )
    }

    @Test("Normalize removes query and fragment")
    func normalize_RemovesQueryAndFragment() {
        #expect(
            EndpointValidator.normalize("https://example.com?query=test#section") ==
            "https://example.com"
        )
    }

    @Test("Normalize removes query with port")
    func normalize_RemovesQueryWithPort() {
        #expect(
            EndpointValidator.normalize("http://192.168.1.100:9090?debug=true") ==
            "http://192.168.1.100:9090"
        )
    }

    @Test("Normalize complex query parameters")
    func normalize_ComplexQueryParameters() {
        #expect(
            EndpointValidator.normalize("https://example.com/path?param1=value1&param2=value2") ==
            "https://example.com/path"
        )
    }

    // MARK: - Paths

    @Test("Normalize preserves path")
    func normalize_PreservesPath() {
        #expect(
            EndpointValidator.normalize("https://example.com/readeck") ==
            "https://example.com/readeck"
        )
    }

    @Test("Normalize preserves nested path")
    func normalize_PreservesNestedPath() {
        #expect(
            EndpointValidator.normalize("https://example.com/api/v1") ==
            "https://example.com/api/v1"
        )
    }

    @Test("Normalize path with port and no scheme")
    func normalize_PathWithPortNoScheme() {
        #expect(
            EndpointValidator.normalize("example.com:8080/readeck") ==
            "https://example.com:8080/readeck"
        )
    }

    @Test("Normalize HTTP with path and port")
    func normalize_HTTPWithPathAndPort() {
        #expect(
            EndpointValidator.normalize("http://100.80.0.1:3000/api") ==
            "http://100.80.0.1:3000/api"
        )
    }

    // MARK: - Whitespace Handling

    @Test("Normalize trims leading whitespace")
    func normalize_TrimsLeadingWhitespace() {
        #expect(
            EndpointValidator.normalize("  https://example.com") ==
            "https://example.com"
        )
    }

    @Test("Normalize trims trailing whitespace")
    func normalize_TrimsTrailingWhitespace() {
        #expect(
            EndpointValidator.normalize("https://example.com  ") ==
            "https://example.com"
        )
    }

    @Test("Normalize trims both whitespace")
    func normalize_TrimsBothWhitespace() {
        #expect(
            EndpointValidator.normalize("  https://example.com  ") ==
            "https://example.com"
        )
    }

    @Test("Normalize trims whitespace from complex URL")
    func normalize_TrimsWhitespaceFromComplexURL() {
        #expect(
            EndpointValidator.normalize("  http://100.80.0.1:8080/api  ") ==
            "http://100.80.0.1:8080/api"
        )
    }

    // MARK: - Edge Cases

    @Test("Normalize empty string")
    func normalize_EmptyString() {
        #expect(
            EndpointValidator.normalize("") ==
            ""
        )
    }

    @Test("Normalize only whitespace")
    func normalize_OnlyWhitespace() {
        #expect(
            EndpointValidator.normalize("   ") ==
            ""
        )
    }

    @Test("Normalize standard port 80 preserved")
    func normalize_StandardPort80_Preserved() {
        #expect(
            EndpointValidator.normalize("http://example.com:80") ==
            "http://example.com:80"
        )
    }

    @Test("Normalize standard port 443 preserved")
    func normalize_StandardPort443_Preserved() {
        #expect(
            EndpointValidator.normalize("https://example.com:443") ==
            "https://example.com:443"
        )
    }

    // MARK: - Complex Real-World Scenarios

    @Test("Normalize Tailscale with path, query, and trailing slash")
    func normalize_TailscaleWithPathQueryAndTrailingSlash() {
        #expect(
            EndpointValidator.normalize("http://100.80.0.1:8080/readeck/?setup=true") ==
            "http://100.80.0.1:8080/readeck"
        )
    }

    @Test("Normalize user input with everything")
    func normalize_UserInputWithEverything() {
        #expect(
            EndpointValidator.normalize("  http://192.168.1.50:9090/api/v1/?debug=true#main  ") ==
            "http://192.168.1.50:9090/api/v1"
        )
    }

    @Test("Normalize invalid scheme converts to HTTPS")
    func normalize_InvalidScheme_ConvertsToHTTPS() {
        #expect(
            EndpointValidator.normalize("ftp://example.com") ==
            "https://example.com"
        )
    }

    // MARK: - isValid Tests

    @Test("isValid valid HTTPS URL")
    func isValid_ValidHTTPSURL() {
        #expect(EndpointValidator.isValid("https://example.com"))
    }

    @Test("isValid valid HTTP URL")
    func isValid_ValidHTTPURL() {
        #expect(EndpointValidator.isValid("http://example.com"))
    }

    @Test("isValid valid domain without scheme")
    func isValid_ValidDomainWithoutScheme() {
        #expect(EndpointValidator.isValid("example.com"))
    }

    @Test("isValid valid Tailscale IP")
    func isValid_ValidTailscaleIP() {
        #expect(EndpointValidator.isValid("100.80.0.1:8080"))
    }

    @Test("isValid valid IP with port")
    func isValid_ValidIPWithPort() {
        #expect(EndpointValidator.isValid("192.168.1.100:9090"))
    }

    @Test("isValid empty string")
    func isValid_EmptyString() {
        #expect(!EndpointValidator.isValid(""))
    }

    @Test("isValid only whitespace")
    func isValid_OnlyWhitespace() {
        #expect(!EndpointValidator.isValid("   "))
    }

    @Test("isValid valid with path")
    func isValid_ValidWithPath() {
        #expect(EndpointValidator.isValid("https://example.com/api"))
    }

    @Test("isValid valid HTTP with port and path")
    func isValid_ValidHTTPWithPortAndPath() {
        #expect(EndpointValidator.isValid("http://100.80.0.1:3000/readeck"))
    }
}
