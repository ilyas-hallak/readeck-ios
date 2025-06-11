import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Server-Einstellungen") {
                    TextField("Endpoint URL", text: $viewModel.endpoint)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Benutzername", text: $viewModel.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Passwort", text: $viewModel.password)
                        .textContentType(.password)
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.saveSettings()
                        }
                    } label: {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Einstellungen speichern")
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
                
                Section("Anmeldung") {
                    Button {
                        Task {
                            await viewModel.login()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoggedIn ? "Erneut anmelden" : "Anmelden")
                        }
                    }
                    .disabled(!viewModel.canLogin || viewModel.isLoading)
                    
                    if viewModel.isLoggedIn {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Erfolgreich angemeldet")
                        }
                    }
                }
                
                // Success/Error Messages
                if let successMessage = viewModel.successMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadSettings()
            }
        }
    }
}

#Preview {
    SettingsView()
}
