import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    @State var selectedTheme: Theme = .system
    @State var selectedFontSize: FontSize = .medium
    
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
                    
                    Button("Debug-Anmeldung") {
                        viewModel.username = "admin"
                        viewModel.password = "Diggah123"
                    }
                    
                    if viewModel.isLoggedIn {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Erfolgreich angemeldet")
                        }
                    }
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

                
                 Section("Erscheinungsbild") {
                     Picker("Theme", selection: $viewModel.selectedTheme) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                     }
                    
                    // Font Settings with Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schrift-Einstellungen")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Schriftart", selection: $viewModel.selectedFontFamily) {
                                    ForEach(FontFamily.allCases, id: \.self) { family in
                                        Text(family.displayName).tag(family)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.selectedFontFamily) {
                                    Task {
                                        await viewModel.saveFontSettings()
                                    }
                                }
                                
                                Picker("Schriftgröße", selection: $viewModel.selectedFontSize) {
                                    ForEach(FontSize.allCases, id: \.self) { size in
                                        Text(size.displayName).tag(size)
                                    }
                                }                                
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: viewModel.selectedFontSize) {
                                    Task {
                                        await viewModel.saveFontSettings()
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Font Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vorschau")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("readeck Bookmark Title")
                                    .font(viewModel.previewTitleFont)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                
                                Text("This is how your bookmark descriptions and article text will appear in the app. The quick brown fox jumps over the lazy dog.")
                                    .font(viewModel.previewBodyFont)
                                    .lineLimit(3)
                                
                                Text("12 min • Today • example.com")
                                    .font(viewModel.previewCaptionFont)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Sync-Einstellungen") {
                    Toggle("Automatischer Sync", isOn: $viewModel.autoSyncEnabled)
                        .toggleStyle(SwitchToggleStyle())
                    
                    if viewModel.autoSyncEnabled {
                        Stepper("Sync-Intervall: \(viewModel.syncInterval) Minuten", value: $viewModel.syncInterval, in: 1...60)
                            .padding(.vertical, 8)
                    }                   
                }

                Section("Leseeinstellungen") {
                    Toggle("Safari Reader Modus", isOn: $viewModel.enableReaderMode)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("Externe Links in In-App Safari öffnen", isOn: $viewModel.openExternalLinksInApp)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("Artikel automatisch als gelesen markieren", isOn: $viewModel.autoMarkAsRead)
                        .toggleStyle(SwitchToggleStyle())
                }

                Section("Datenmanagement") {
                    Button(role: .destructive) {
                        Task {
                            // await viewModel.clearCache()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Cache leeren")
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            // await viewModel.resetSettings()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.red)
                            Text("Einstellungen zurücksetzen")
                        }
                    }
                }

                Section("Über die App") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Version \(viewModel.appVersion)")
                    }
                    
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Entwickler: \(viewModel.developerName)")
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                        Link("Website", destination: URL(string: "https://example.com")!)
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
