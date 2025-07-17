//
//  SettingsServerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsServerView: View {
    @State private var viewModel = SettingsServerViewModel()
    @State private var showingLogoutAlert = false
    
    init(viewModel: SettingsServerViewModel = SettingsServerViewModel(), showingLogoutAlert: Bool = false) {
        self.viewModel = viewModel
        self.showingLogoutAlert = showingLogoutAlert
    }
    
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
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.headline)
                    TextField("Your Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.username) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.headline)
                    SecureField("Your Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.password) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
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
            
            if viewModel.isSetupMode {
                VStack(spacing: 10) {
                    Button(action: {
                        Task {
                            await viewModel.saveServerSettings()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isLoading ? "Speichern..." : (viewModel.isLoggedIn ? "Erneut anmelden & speichern" : "Anmelden & speichern"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canLogin ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canLogin || viewModel.isLoading)
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
        .task {
            await viewModel.loadServerSettings()
        }
    }
}

#Preview {
    SettingsServerView(viewModel: .init(
        MockUseCaseFactory()
    ))
}
