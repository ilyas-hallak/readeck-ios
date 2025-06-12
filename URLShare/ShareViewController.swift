//
//  ShareViewController.swift
//  URLShare
//
//  Created by Ilyas Hallak on 11.06.25.
//

import UIKit
import Social
import UniformTypeIdentifiers
import CoreData

class ShareViewController: SLComposeServiceViewController {
    
    private var extractedURL: String?
    private var extractedTitle: String?
    private var isProcessing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extractSharedContent()
        setupUI()
    }
    
    override func isContentValid() -> Bool {
        guard let url = extractedURL, 
              !url.isEmpty,
              !isProcessing,
              URL(string: url) != nil else {
            return false
        }
        return true
    }
    
    override func didSelectPost() {
        guard let url = extractedURL else {
            completeRequest()
            return
        }
        
        isProcessing = true
        let title = textView.text != extractedTitle ? textView.text : extractedTitle
        
        // UI Feedback zeigen
        let loadingAlert = UIAlertController(title: "Speichere Bookmark", message: "Bitte warten...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        Task {
            do {
                let response = try await createBookmark(url: url, title: title)
                
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                    
                    if response.status == 0 {
                        // Erfolg
                        let successAlert = UIAlertController(title: "Erfolg", message: "Bookmark wurde hinzugefügt!", preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            self?.completeRequest()
                        })
                        present(successAlert, animated: true)
                    } else {
                        // Fehler vom Server
                        let errorAlert = UIAlertController(title: "Fehler", message: response.message, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            self?.completeRequest()
                        })
                        present(errorAlert, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                    let errorAlert = UIAlertController(title: "Fehler", message: error.localizedDescription, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.completeRequest()
                    })
                    present(errorAlert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Core Data Token Retrieval
    
    private func getCurrentToken() -> String? {
        let context = CoreDataManager.shared.context
        let request: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest() // Anpassen an deine Entity
        
        do {
            let tokens = try context.fetch(request)
            return tokens.first?.token // Anpassen an dein Token-Attribut
        } catch {
            print("Failed to fetch token from Core Data: \(error)")
            return nil
        }
    }
    
    // MARK: - API Implementation
    
    private func createBookmark(url: String, title: String?) async throws -> CreateBookmarkResponseDto {
        let requestDto = CreateBookmarkRequestDto(labels: nil, title: title, url: url)
        
        // Die Server-URL
        let baseURL = "https://keep.mnk.any64.de"
        let endpoint = "/api/bookmarks"
        
        guard let requestURL = URL(string: "\(baseURL)\(endpoint)") else {
            throw RequestError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Token aus Core Data holen
        guard let token = getCurrentToken() else {
            throw RequestError.noToken
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestDto)
        
        // Request durchführen
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw RequestError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Response dekodieren und zurückgeben
        let decoder = JSONDecoder()
        return try decoder.decode(CreateBookmarkResponseDto.self, from: data)
    }
    
    // MARK: - Support Methods
    
    private func setupUI() {
        self.title = "Zu readeck hinzufügen"
        self.placeholder = "Optional: Titel anpassen..."
        
        // Zeige URL oder Titel als Kontext
        if let title = extractedTitle {
            self.textView.text = title
        } else if let url = extractedURL {
            self.textView.text = URL(string: url)?.host ?? url
        }
    }
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext else { return }
        
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            
            for provider in inputItem.attachments ?? [] {
                // URL direkt
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                self?.extractedURL = url.absoluteString
                                self?.extractedTitle = inputItem.attributedTitle?.string ?? inputItem.attributedContentText?.string
                                self?.setupUI()
                            }
                        }
                    }
                }
                // Text (könnte URL enthalten)
                else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                        if let text = item as? String {
                            DispatchQueue.main.async {
                                self?.handleTextContent(text)
                            }
                        }
                    }
                }
                // Property List (Safari teilt so)
                else if provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { [weak self] item, error in
                        if let dictionary = item as? [String: Any] {
                            DispatchQueue.main.async {
                                self?.handlePropertyList(dictionary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func handleTextContent(_ text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let url = match.url {
            extractedURL = url.absoluteString
            extractedTitle = text != url.absoluteString ? text : nil
        } else if URL(string: text) != nil {
            extractedURL = text
        }
        
        setupUI()
    }
    
    private func handlePropertyList(_ dictionary: [String: Any]) {
        if let urlString = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any],
           let url = urlString["URL"] as? String {
            extractedURL = url
            extractedTitle = urlString["title"] as? String
        } else if let url = dictionary["URL"] as? String {
            extractedURL = url
            extractedTitle = dictionary["title"] as? String
        }
        
        setupUI()
    }
    
    private func completeRequest() {
        isProcessing = false
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - DTOs und Error Handling

struct CreateBookmarkRequestDto: Codable {
    let labels: [String]?
    let title: String?
    let url: String
}

struct CreateBookmarkResponseDto: Codable {
    let message: String
    let status: Int
}

enum RequestError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case noToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Server-Antwort"
        case .serverError(let code):
            return "Server-Fehler: \(code)"
        case .decodingError:
            return "Fehler beim Dekodieren der Antwort"
        case .noToken:
            return "Kein Authentifizierungs-Token gefunden"
        }
    }
}
