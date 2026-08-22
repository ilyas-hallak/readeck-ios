//
//  AuthRepositoryTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

@Suite("AuthRepository Tests")
struct AuthRepositoryTests {

    private func makeRepository(
        tokenProvider: RecordingTokenProvider = RecordingTokenProvider(),
        settings: RecordingSettingsRepository = RecordingSettingsRepository(),
        profile: StubGetUserProfileUseCase = StubGetUserProfileUseCase()
    ) -> (AuthRepository, StubAPI, RecordingTokenProvider, RecordingSettingsRepository) {
        let api = StubAPI()
        api.tokenProvider = tokenProvider
        let repository = AuthRepository(
            api: api,
            settingsRepository: settings,
            getUserProfileUseCase: profile
        )
        return (repository, api, tokenProvider, settings)
    }

    // MARK: - Classic Login

    @Test("login returns the user and switches the auth method to apiToken")
    func loginSucceeds() async throws {
        let (repository, api, tokenProvider, _) = makeRepository()
        api.loginHandler = { _, _, _ in UserDto(id: "u1", token: "tok-1") }

        let user = try await repository.login(
            endpoint: "https://readeck.example.com", username: "ilyas", password: "pw"
        )

        #expect(user.id == "u1")
        #expect(user.token == "tok-1")
        #expect(tokenProvider.authMethod == .apiToken)
    }

    @Test("login passes the credentials through to the API")
    func loginForwardsCredentials() async throws {
        let (repository, api, _, _) = makeRepository()
        var received: (endpoint: String, username: String, password: String)?
        api.loginHandler = { endpoint, username, password in
            received = (endpoint, username, password)
            return UserDto(id: "u1", token: "tok-1")
        }

        _ = try await repository.login(
            endpoint: "https://readeck.example.com", username: "ilyas", password: "secret"
        )

        #expect(received?.endpoint == "https://readeck.example.com")
        #expect(received?.username == "ilyas")
        #expect(received?.password == "secret")
    }

    @Test("login propagates an API error and leaves the auth method untouched")
    func loginPropagatesError() async throws {
        let (repository, api, tokenProvider, _) = makeRepository()
        api.loginHandler = { _, _, _ in throw APIError.serverError(401) }

        await #expect(throws: APIError.serverError(401)) {
            _ = try await repository.login(endpoint: "https://x", username: "a", password: "b")
        }
        #expect(tokenProvider.authMethod == nil)
    }

    // MARK: - Logout

    @Test("logout clears the token and resets the auth method")
    func logoutClearsToken() async throws {
        let (repository, _, tokenProvider, _) = makeRepository()

        try await repository.logout()

        #expect(tokenProvider.clearTokenCallCount == 1)
        #expect(tokenProvider.token == nil)
        #expect(tokenProvider.authMethod == .apiToken)
    }

    // MARK: - OAuth Login

    @Test("loginWithOAuth persists token, method, client id and endpoint")
    func oauthPersistsCredentials() async throws {
        let (repository, _, tokenProvider, _) = makeRepository()
        let token = OAuthToken.fixture()

        try await repository.loginWithOAuth(
            endpoint: "https://readeck.example.com", token: token, clientId: "client-1"
        )

        #expect(tokenProvider.oauthToken?.accessToken == "access-123")
        #expect(tokenProvider.authMethod == .oauth)
        #expect(tokenProvider.oauthClientId == "client-1")
        #expect(tokenProvider.endpoint == "https://readeck.example.com")
    }

    @Test("loginWithOAuth writes endpoint and username into the settings")
    func oauthUpdatesSettings() async throws {
        let settings = RecordingSettingsRepository(storedSettings: Settings())
        let (repository, _, _, _) = makeRepository(
            settings: settings, profile: StubGetUserProfileUseCase(username: "ilyas")
        )

        try await repository.loginWithOAuth(
            endpoint: "https://readeck.example.com", token: .fixture(), clientId: "client-1"
        )

        #expect(settings.savedSettings.count == 1)
        #expect(settings.savedSettings.first?.endpoint == "https://readeck.example.com")
        #expect(settings.savedSettings.first?.username == "ilyas")
    }

    @Test("loginWithOAuth skips the settings write when none are stored yet")
    func oauthWithoutExistingSettings() async throws {
        let settings = RecordingSettingsRepository(storedSettings: nil)
        let (repository, _, tokenProvider, _) = makeRepository(settings: settings)

        try await repository.loginWithOAuth(
            endpoint: "https://readeck.example.com", token: .fixture(), clientId: "client-1"
        )

        // Der Token-Teil muss trotzdem persistiert sein.
        #expect(tokenProvider.authMethod == .oauth)
        #expect(settings.savedSettings.isEmpty)
    }

    @Test("loginWithOAuth propagates a failing profile fetch")
    func oauthPropagatesProfileError() async throws {
        let profile = StubGetUserProfileUseCase()
        profile.result = .failure(APIError.serverError(403))
        let (repository, _, _, settings) = makeRepository(profile: profile)

        await #expect(throws: APIError.serverError(403)) {
            try await repository.loginWithOAuth(
                endpoint: "https://x", token: .fixture(), clientId: "c"
            )
        }
        #expect(settings.savedSettings.isEmpty)
    }

    // MARK: - Auth Method / Switching

    @Test("getAuthenticationMethod reads through to the token provider")
    func getAuthenticationMethod() async throws {
        let tokenProvider = RecordingTokenProvider()
        await tokenProvider.setAuthMethod(.oauth)
        let (repository, _, _, _) = makeRepository(tokenProvider: tokenProvider)

        #expect(await repository.getAuthenticationMethod() == .oauth)
    }

    @Test("switchToClassicAuth clears the old token before logging in again")
    func switchToClassicAuth() async throws {
        let tokenProvider = RecordingTokenProvider()
        await tokenProvider.setAuthMethod(.oauth)
        let (repository, api, provider, _) = makeRepository(tokenProvider: tokenProvider)
        api.loginHandler = { _, _, _ in UserDto(id: "u2", token: "tok-2") }

        let user = try await repository.switchToClassicAuth(
            endpoint: "https://x", username: "a", password: "b"
        )

        #expect(user.id == "u2")
        #expect(provider.clearTokenCallCount == 1)
        #expect(provider.authMethod == .apiToken)
    }

    // MARK: - getCurrentSettings

    @Test("getCurrentSettings reads through to the settings repository")
    func getCurrentSettings() async throws {
        var stored = Settings()
        stored.endpoint = "https://stored.example.com"
        let (repository, _, _, _) = makeRepository(
            settings: RecordingSettingsRepository(storedSettings: stored)
        )

        let settings = try await repository.getCurrentSettings()

        #expect(settings?.endpoint == "https://stored.example.com")
    }
}
