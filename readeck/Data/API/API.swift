//
//  API.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case networkError
    case invalidResponse
    case authenticationFailed
}

protocol PAPI {
    func login(username: String, password: String) async throws -> UserDto
    func getBookmarks() async throws -> [BookmarkDto]
    func getBookmark(id: String) async throws -> BookmarkDetailDto
    func getBookmarkArticle(id: String) async throws -> String
    var authToken: String? { get set }
}

class API: PAPI {
    private let baseURL: String
    var authToken: String?
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func login(username: String, password: String) async throws -> UserDto {
        guard let url = URL(string: "\(baseURL)/auth") else {
            throw APIError.invalidURL
        }
        
        let credentials = [
            "username": username,
            "password": password,
            "application": "api doc"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = try? JSONSerialization.data(withJSONObject: credentials)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.authenticationFailed
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            self.authToken = token
            let decoder = JSONDecoder()
            return try decoder.decode(UserDto.self, from: data)
        }
        
        throw APIError.invalidResponse
    }
    
    // Bookmarks abrufen
    func getBookmarks() async throws -> [BookmarkDto] {
        guard let url = URL(string: "\(baseURL)/bookmarks") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([BookmarkDto].self, from: data)
    }
    
    func getBookmark(id: String) async throws -> BookmarkDetailDto {
        guard let url = URL(string: "\(baseURL)/bookmarks/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.networkError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(BookmarkDetailDto.self, from: data)
    }
    
    func getBookmarkArticle(id: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/bookmarks/\(id)/article") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/html", forHTTPHeaderField: "accept")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let htmlContent = String(data: data, encoding: .utf8) else {
            throw APIError.networkError
        }
        
        return htmlContent
    }
}
