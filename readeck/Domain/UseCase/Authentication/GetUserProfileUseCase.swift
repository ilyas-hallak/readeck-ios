//
//  GetUserProfileUseCase.swift
//  readeck
//
//  Created by Claude on 19.12.25.
//

import Foundation

protocol PGetUserProfileUseCase {
    func execute() async throws -> String
}

final class GetUserProfileUseCase: PGetUserProfileUseCase {
    private let profileApiClient: PProfileApiClient

    init(profileApiClient: PProfileApiClient) {
        self.profileApiClient = profileApiClient
    }

    func execute() async throws -> String {
        let profile = try await profileApiClient.getProfile()
        return profile.user.username
    }
}
