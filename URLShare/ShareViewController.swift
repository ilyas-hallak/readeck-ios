//
//  ShareViewController.swift
//  URLShare
//
//  Created by Ilyas Hallak on 11.06.25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var extractedURL: String?
    private var extractedTitle: String?
    
    // UI Elements
    private var titleTextField: UITextField?
    private var urlLabel: UILabel?
    private var statusLabel: UILabel?
    private var saveButton: UIButton?
    private var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }
    

    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(named: "green") ?? UIColor.systemGroupedBackground
        
        // Add cancel button
        let cancelButton = UIBarButtonItem(title: "Abbrechen", style: .plain, target: self, action: #selector(cancelButtonTapped))
        cancelButton.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = cancelButton
        
        // Ensure navigation bar is visible
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = UIColor(named: "green") ?? UIColor.systemGreen
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // Add logo
        let logoImageView = UIImageView(image: UIImage(named: "readeck"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.alpha = 0.9
        view.addSubview(logoImageView)
        
        // Add custom cancel button
        let customCancelButton = UIButton(type: .system)
        customCancelButton.translatesAutoresizingMaskIntoConstraints = false
        customCancelButton.setTitle("Abbrechen", for: .normal)
        customCancelButton.setTitleColor(UIColor.white, for: .normal)
        customCancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        customCancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(customCancelButton)
        

        
        // URL Container View
        let urlContainerView = UIView()
        urlContainerView.translatesAutoresizingMaskIntoConstraints = false
        urlContainerView.backgroundColor = UIColor.white
        urlContainerView.layer.cornerRadius = 12
        urlContainerView.layer.shadowColor = UIColor.black.cgColor
        urlContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        urlContainerView.layer.shadowRadius = 4
        urlContainerView.layer.shadowOpacity = 0.1
        view.addSubview(urlContainerView)
        
        // URL Label
        urlLabel = UILabel()
        urlLabel?.translatesAutoresizingMaskIntoConstraints = false
        urlLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        urlLabel?.textColor = UIColor.label
        urlLabel?.numberOfLines = 0
        urlLabel?.text = "URL wird geladen..."
        urlLabel?.textAlignment = .left
        urlContainerView.addSubview(urlLabel!)
        
        // Title Container View
        let titleContainerView = UIView()
        titleContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleContainerView.backgroundColor = UIColor.white
        titleContainerView.layer.cornerRadius = 12
        titleContainerView.layer.shadowColor = UIColor.black.cgColor
        titleContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        titleContainerView.layer.shadowRadius = 4
        titleContainerView.layer.shadowOpacity = 0.1
        view.addSubview(titleContainerView)
        
        // Title TextField
        titleTextField = UITextField()
        titleTextField?.translatesAutoresizingMaskIntoConstraints = false
        titleTextField?.placeholder = "Titel eingeben..."
        titleTextField?.borderStyle = .none
        titleTextField?.font = UIFont.systemFont(ofSize: 16)
        titleTextField?.backgroundColor = UIColor.clear
        titleTextField?.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        titleContainerView.addSubview(titleTextField!)
        
        // Status Label
        statusLabel = UILabel()
        statusLabel?.translatesAutoresizingMaskIntoConstraints = false
        statusLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel?.numberOfLines = 0
        statusLabel?.textAlignment = .center
        statusLabel?.isHidden = true
        statusLabel?.layer.cornerRadius = 10
        statusLabel?.layer.masksToBounds = true
        view.addSubview(statusLabel!)
        
        // Save Button
        saveButton = UIButton(type: .system)
        saveButton?.translatesAutoresizingMaskIntoConstraints = false
        saveButton?.setTitle("Bookmark speichern", for: .normal)
        saveButton?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton?.backgroundColor = UIColor.white
        saveButton?.setTitleColor(UIColor(named: "green") ?? UIColor.systemGreen, for: .normal)
        saveButton?.layer.cornerRadius = 16
        saveButton?.layer.shadowColor = UIColor.black.cgColor
        saveButton?.layer.shadowOffset = CGSize(width: 0, height: 4)
        saveButton?.layer.shadowRadius = 8
        saveButton?.layer.shadowOpacity = 0.2
        saveButton?.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton?.isEnabled = false
        saveButton?.alpha = 0.6
        view.addSubview(saveButton!)
        

        
        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator?.hidesWhenStopped = true
        view.addSubview(activityIndicator!)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        guard let urlLabel = urlLabel,
              let titleTextField = titleTextField,
              let statusLabel = statusLabel,
              let saveButton = saveButton,
              let activityIndicator = activityIndicator else { return }
        
        // Find container views and logo
        let urlContainerView = urlLabel.superview!
        let titleContainerView = titleTextField.superview!
        let logoImageView = view.subviews.first { $0 is UIImageView }!
        let customCancelButton = view.subviews.first { $0 is UIButton && $0 != saveButton }!
        
        NSLayoutConstraint.activate([
            // Custom Cancel Button
            customCancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            customCancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            customCancelButton.heightAnchor.constraint(equalToConstant: 36),
            customCancelButton.widthAnchor.constraint(equalToConstant: 100),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 40),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            
            // URL Container
            urlContainerView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            urlContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // URL Label inside container
            urlLabel.topAnchor.constraint(equalTo: urlContainerView.topAnchor, constant: 16),
            urlLabel.leadingAnchor.constraint(equalTo: urlContainerView.leadingAnchor, constant: 16),
            urlLabel.trailingAnchor.constraint(equalTo: urlContainerView.trailingAnchor, constant: -16),
            urlLabel.bottomAnchor.constraint(equalTo: urlContainerView.bottomAnchor, constant: -16),
            
            // Title Container
            titleContainerView.topAnchor.constraint(equalTo: urlContainerView.bottomAnchor, constant: 20),
            titleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleContainerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title TextField inside container
            titleTextField.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor, constant: -16),
            titleTextField.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: -16),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor)
        ])
    }
    
    // MARK: - Content Extraction
    private func extractSharedContent() {
        guard let extensionContext = extensionContext else { return }
        
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            
            for attachment in inputItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        DispatchQueue.main.async {
                            if let url = url as? URL {
                                self?.extractedURL = url.absoluteString
                                self?.urlLabel?.text = url.absoluteString
                                self?.updateSaveButtonState()
                            }
                        }
                    }
                }
                
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                        DispatchQueue.main.async {
                            if let text = text as? String, let url = URL(string: text) {
                                self?.extractedURL = url.absoluteString
                                self?.urlLabel?.text = url.absoluteString
                                self?.updateSaveButtonState()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        updateSaveButtonState()
    }
    
    @objc private func saveButtonTapped() {
        guard let title = titleTextField?.text, !title.isEmpty else {
            showStatus("Bitte geben Sie einen Titel ein.", error: true)
            return
        }
        
        saveButton?.isEnabled = false
        activityIndicator?.startAnimating()
        
        Task {
            await addBookmarkViaAPI(title: title)
            await MainActor.run {
                self.saveButton?.isEnabled = true
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func updateSaveButtonState() {
        let isValid = !(titleTextField?.text?.isEmpty ?? true) && extractedURL != nil
        saveButton?.isEnabled = isValid
        saveButton?.alpha = isValid ? 1.0 : 0.6
    }
    
    // MARK: - API Call
    private func addBookmarkViaAPI(title: String) async {
        guard let url = extractedURL, !url.isEmpty else {
            showStatus("Keine URL gefunden.", error: true)
            return
        }
        
        // Token und Endpoint aus KeychainHelper
        guard let token = KeychainHelper.shared.loadToken() else {
            showStatus("Kein Token gefunden. Bitte in der Haupt-App einloggen.", error: true)
            return
        }
        
        guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("Kein Server-Endpunkt gefunden.", error: true)
            return
        }
        
        let requestDto = CreateBookmarkRequestDto(url: url, title: title, labels: [])
        guard let requestData = try? JSONEncoder().encode(requestDto) else {
            showStatus("Fehler beim Kodieren der Anfrage.", error: true)
            return
        }
        
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks") else {
            showStatus("Ungültiger Server-Endpunkt.", error: true)
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
                showStatus("Ungültige Server-Antwort.", error: true)
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let msg = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
                showStatus("Serverfehler: \(httpResponse.statusCode)\n\(msg)", error: true)
                return
            }
            
            // Optional: Response parsen
            if let resp = try? JSONDecoder().decode(CreateBookmarkResponseDto.self, from: data) {
                showStatus("Gespeichert: \(resp.message)", error: false)
            } else {
                showStatus("Lesezeichen gespeichert!", error: false)
            }
        } catch {
            showStatus("Netzwerkfehler: \(error.localizedDescription)", error: true)
        }
    }
    
    private func showStatus(_ message: String, error: Bool) {
        DispatchQueue.main.async {
            self.statusLabel?.text = message
            self.statusLabel?.textColor = error ? UIColor.systemRed : UIColor.systemGreen
            self.statusLabel?.backgroundColor = error ? UIColor.systemRed.withAlphaComponent(0.1) : UIColor.systemGreen.withAlphaComponent(0.1)
            self.statusLabel?.isHidden = false
            
            if !error {
                // Automatically dismiss after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
            }
        }
    }
        
    
    // MARK: - DTOs (kopiert)
    private struct CreateBookmarkRequestDto: Codable {
        let labels: [String]?
        let title: String?
        let url: String
        
        init(url: String, title: String? = nil, labels: [String]? = nil) {
            self.url = url
            self.title = title
            self.labels = labels
        }
    }
    
    private struct CreateBookmarkResponseDto: Codable {
        let message: String
        let status: Int
    }
}
