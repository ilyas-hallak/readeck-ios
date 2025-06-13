//
//  ShareViewController.swift
//  URLShare
//
//  Created by Ilyas Hallak on 11.06.25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    private var extractedURL: String?
    private var extractedTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extractSharedContent()
        
        // Automatisch die Haupt-App öffnen, sobald URL extrahiert wurde
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.openParentApp()
        }
    }
    
    override func isContentValid() -> Bool {
        return true // Immer true, damit der Button funktioniert
    }
    
    override func didSelectPost() {
        openMainApp()
    }
    
    // MARK: - Private Methods
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext else { return }
        
        print("=== DEBUG: Starting content extraction ===")
        print("Input items count: \(extensionContext.inputItems.count)")
        
        for (itemIndex, item) in extensionContext.inputItems.enumerated() {
            guard let inputItem = item as? NSExtensionItem else { continue }
            
            print("Item \(itemIndex) - attachments: \(inputItem.attachments?.count ?? 0)")
            
            // Versuche alle verfügbaren Type Identifiers
            for (attachmentIndex, provider) in (inputItem.attachments ?? []).enumerated() {
                print("Attachment \(attachmentIndex) - registered types: \(provider.registeredTypeIdentifiers)")
                
                // Iteriere durch alle registrierten Type Identifiers
                for typeIdentifier in provider.registeredTypeIdentifiers {
                    print("Trying type identifier: \(typeIdentifier)")
                    
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, error in
                        if let error = error {
                            print("Error loading \(typeIdentifier): \(error)")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self?.processLoadedItem(item, typeIdentifier: typeIdentifier, inputItem: inputItem)
                        }
                    }
                }
            }
        }
    }
    
    private func processLoadedItem(_ item: Any?, typeIdentifier: String, inputItem: NSExtensionItem) {
        print("Processing item of type \(typeIdentifier): \(type(of: item))")
        
        // URL direkt
        if let url = item as? URL {
            print("Found URL: \(url.absoluteString)")
            extractedURL = url.absoluteString
            extractedTitle = inputItem.attributedTitle?.string ?? inputItem.attributedContentText?.string
            return
        }
        
        // NSURL
        if let nsurl = item as? NSURL {
            print("Found NSURL: \(nsurl.absoluteString ?? "nil")")
            extractedURL = nsurl.absoluteString
            extractedTitle = inputItem.attributedTitle?.string ?? inputItem.attributedContentText?.string
            return
        }
        
        // String (könnte URL sein)
        if let text = item as? String {
            print("Found String: \(text)")
            if URL(string: text) != nil {
                extractedURL = text
                extractedTitle = inputItem.attributedTitle?.string ?? inputItem.attributedContentText?.string
                return
            }
            
            // Versuche URL aus Text zu extrahieren
            if let extractedURL = extractURLFromText(text) {
                self.extractedURL = extractedURL
                self.extractedTitle = text != extractedURL ? text : nil
                return
            }
        }
        
        // Dictionary (Property List)
        if let dictionary = item as? [String: Any] {
            print("Found Dictionary: \(dictionary)")
            handlePropertyList(dictionary)
            return
        }
        
        // NSData - versuche als String zu interpretieren
        if let data = item as? Data {
            if let text = String(data: data, encoding: .utf8) {
                print("Found Data as String: \(text)")
                if URL(string: text) != nil {
                    extractedURL = text
                    return
                }
            }
        }
        
        print("Could not process item of type: \(type(of: item))")
    }
    
    private func extractURLFromText(_ text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        if let match = detector?.firstMatch(in: text, options: [], range: range),
           let url = match.url {
            return url.absoluteString
        }
        
        return nil
    }
    
    private func handlePropertyList(_ dictionary: [String: Any]) {
        // Safari und andere Browser verwenden oft Property Lists
        if let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] {
            if let url = results["URL"] as? String {
                extractedURL = url
                extractedTitle = results["title"] as? String
                return
            }
        }
        
        // Direkte URL im Dictionary
        if let url = dictionary["URL"] as? String {
            extractedURL = url
            extractedTitle = dictionary["title"] as? String
            return
        }
        
        // Andere mögliche Keys
        for key in dictionary.keys {
            if let value = dictionary[key] as? String, URL(string: value) != nil {
                extractedURL = value
                return
            }
        }
    }
    
    private func openMainApp() {
        let url = extractedURL ?? "https://example.com"
        let title = extractedTitle ?? ""
        
        print("Opening main app with URL: \(url)")
        
        // Verwende NSUserActivity anstatt URL-Schema
        let userActivity = NSUserActivity(activityType: "de.ilyas.readeck")
        userActivity.userInfo = [
            "url": url,
            "title": title
        ]
        userActivity.webpageURL = URL(string: url)
        
        // Extension schließen und Activity übergeben
        extensionContext?.completeRequest(returningItems: [userActivity], completionHandler: nil)
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func openParentApp() {
        guard let extensionContext = extensionContext else { return }
        
        let url = extractedURL ?? "https://example.com"
        let title = extractedTitle ?? ""
        
        print("Opening parent app with URL: \(url)")
        
        // URL für die Haupt-App erstellen mit Parametern
        var urlComponents = URLComponents(string: "readeck://add-bookmark")
        urlComponents?.queryItems = [
            URLQueryItem(name: "url", value: url)
        ]
        
        if !title.isEmpty {
            urlComponents?.queryItems?.append(URLQueryItem(name: "title", value: title))
        }
        
        guard let finalURL = urlComponents?.url else {
            print("Failed to create final URL")
            return
        }
        
        print("Final URL: \(finalURL)")
        
        var responder: UIResponder? = self
        
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(finalURL)
                break
            }
            responder = responder?.next
        }
    }
}
