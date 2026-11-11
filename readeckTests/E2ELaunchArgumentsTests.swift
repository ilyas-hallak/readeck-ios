import Testing
@testable import readeck

struct E2ELaunchArgumentsTests {
    @Test func parsesTheRequiredFlags() {
        let arguments = [
            "/path/to/readeck.app",
            "-e2eEndpoint", "https://readeck.example.com",
            "-e2eOAuthAccessToken", "token-123",
            "-e2eOAuthClientId", "client-456"
        ]

        let parsed = E2ELaunchArguments.parse(arguments)

        #expect(parsed == E2ELaunchArguments(
            endpoint: "https://readeck.example.com",
            accessToken: "token-123",
            clientId: "client-456",
            refreshToken: nil,
            expiresIn: nil
        ))
    }

    @Test func parsesTheOptionalFlags() {
        let arguments = [
            "-e2eEndpoint", "https://readeck.example.com",
            "-e2eOAuthAccessToken", "token-123",
            "-e2eOAuthClientId", "client-456",
            "-e2eOAuthRefreshToken", "refresh-789",
            "-e2eOAuthExpiresIn", "3600"
        ]

        let parsed = E2ELaunchArguments.parse(arguments)

        #expect(parsed?.refreshToken == "refresh-789")
        #expect(parsed?.expiresIn == 3600)
    }

    @Test func ignoresUnrelatedArguments() {
        let arguments = [
            "-SomeOtherFlag", "value",
            "-e2eEndpoint", "https://readeck.example.com",
            "-e2eOAuthAccessToken", "token-123",
            "-e2eOAuthClientId", "client-456"
        ]

        let parsed = E2ELaunchArguments.parse(arguments)

        #expect(parsed?.endpoint == "https://readeck.example.com")
    }

    @Test func returnsNilWhenARequiredFlagIsMissing() {
        let arguments = [
            "-e2eEndpoint", "https://readeck.example.com",
            "-e2eOAuthAccessToken", "token-123"
        ]

        #expect(E2ELaunchArguments.parse(arguments) == nil)
    }

    @Test func returnsNilWithoutAnyE2EFlags() {
        #expect(E2ELaunchArguments.parse(["/path/to/readeck.app"]) == nil)
    }
}
