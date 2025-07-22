import Foundation

class SimpleAPI {
    // MARK: - API Methods
    static func addBookmark(title: String, url: String, labels: [String]? = nil, showStatus: @escaping (String, Bool) -> Void) async {
        guard let token = KeychainHelper.shared.loadToken() else {
            showStatus("No token found. Please log in via the main app.", true)
            return
        }
        guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("No server endpoint found.", true)
            return
        }
        let requestDto = CreateBookmarkRequestDto(url: url, title: title, labels: labels)
        guard let requestData = try? JSONEncoder().encode(requestDto) else {
            showStatus("Failed to encode request.", true)
            return
        }
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks") else {
            showStatus("Invalid server endpoint.", true)
            return
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                showStatus("Invalid server response.", true)
                return
            }
            guard 200...299 ~= httpResponse.statusCode else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                showStatus("Server error: \(httpResponse.statusCode)\n\(msg)", true)
                return
            }
            if let resp = try? JSONDecoder().decode(CreateBookmarkResponseDto.self, from: data) {
                showStatus("Saved: \(resp.message)", false)
            } else {
                showStatus("Bookmark saved!", false)
            }
        } catch {
            showStatus("Network error: \(error.localizedDescription)", true)
        }
    }
    
    static func getBookmarkLabels(showStatus: @escaping (String, Bool) -> Void) async -> [BookmarkLabelDto]? {
        guard let token = KeychainHelper.shared.loadToken() else {
            showStatus("No token found. Please log in via the main app.", true)
            return nil
        }
        guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("No server endpoint found.", true)
            return nil
        }
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks/labels") else {
            showStatus("Invalid server endpoint.", true)
            return nil
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                showStatus("Invalid server response.", true)
                return nil
            }
            guard 200...299 ~= httpResponse.statusCode else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                showStatus("Server error: \(httpResponse.statusCode)\n\(msg)", true)
                return nil
            }
            let labels = try JSONDecoder().decode([BookmarkLabelDto].self, from: data)
            return labels
        } catch {
            showStatus("Network error: \(error.localizedDescription)", true)
            return nil
        }
    }
} 
