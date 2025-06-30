//
//  SettingsServerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI
// SectionHeader wird jetzt zentral importiert

struct SettingsServerView: View {
    @State var viewModel = SettingsViewModel()
    @State private var isTesting: Bool = false
    @State private var connectionTestSuccess: Bool = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: viewModel.isSetupMode ? "Server-Einstellungen" : "Server-Verbindung", icon: "server.rack")
                .padding(.bottom, 4)
            
            Text(viewModel.isSetupMode ?
                 "Geben Sie Ihre Readeck-Server-Details ein, um zu beginnen." :
                 "Ihre aktuelle Server-Verbindung und Anmeldedaten.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Server-Endpunkt")
                        .font(.headline)
                    TextField("https://readeck.example.com", text: $viewModel.endpoint)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.endpoint) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                                connectionTestSuccess = false
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Benutzername")
                        .font(.headline)
                    TextField("Ihr Benutzername", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.username) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                                connectionTestSuccess = false
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passwort")
                        .font(.headline)
                    SecureField("Ihr Passwort", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.password) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                                connectionTestSuccess = false
                            }
                        }
                }
            }
            
            // Connection Status
            if viewModel.isLoggedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Erfolgreich angemeldet")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Messages
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Action Buttons
            if viewModel.isSetupMode {
                VStack(spacing: 10) {
                    Button(action: {
                        Task {
                            await testConnection()
                        }
                    }) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isTesting ? "Teste Verbindung..." : "Verbindung testen")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canLogin ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canLogin || isTesting || viewModel.isLoading)
                    
                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isLoading ? "Anmelde..." : (viewModel.isLoggedIn ? "Erneut anmelden" : "Anmelden"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((viewModel.canLogin && connectionTestSuccess) ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canLogin || !connectionTestSuccess || viewModel.isLoading || isTesting)
                    
                    Button("Debug-Anmeldung") {
                        viewModel.username = "admin"
                        viewModel.password = "Diggah123"
                        viewModel.endpoint = "https://readeck.mnk.any64.de"
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Abmelden")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .alert("Abmelden", isPresented: $showingLogoutAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Abmelden", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("Möchten Sie sich wirklich abmelden? Dies wird alle Ihre Anmeldedaten löschen und Sie zur Einrichtung zurückführen.")
        }
    }
    
    private func testConnection() async {
        guard viewModel.canLogin else {
            viewModel.errorMessage = "Bitte füllen Sie alle Felder aus."
            return
        }
        
        isTesting = true
        viewModel.clearMessages()
        connectionTestSuccess = false
        
        do {
            // Test login without saving settings
            let _ = try await viewModel.loginUseCase.execute(
                username: viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: viewModel.password
            )
            
            // If we get here, the test was successful
            connectionTestSuccess = true
            viewModel.successMessage = "Verbindung erfolgreich getestet! ✓"
            
        } catch {
            connectionTestSuccess = false
            viewModel.errorMessage = "Verbindungstest fehlgeschlagen: \(error.localizedDescription)"
        }
        
        isTesting = false
    }
}

#Preview {
    SettingsServerView(viewModel: SettingsViewModel())
}
