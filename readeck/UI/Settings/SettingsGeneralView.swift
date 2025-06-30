//
//  SettingsGeneralView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI
// SectionHeader wird jetzt zentral importiert

struct SettingsGeneralView: View {
    @State var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Allgemeine Einstellungen", icon: "gear")
                .padding(.bottom, 4)
            
            // Theme
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Font Settings
            FontSettingsView()
                .padding(.vertical, 4)
            
            // Sync Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Sync-Einstellungen")
                    .font(.headline)
                Toggle("Automatischer Sync", isOn: $viewModel.autoSyncEnabled)
                    .toggleStyle(SwitchToggleStyle())
                if viewModel.autoSyncEnabled {
                    HStack {
                        Text("Sync-Intervall")
                        Spacer()
                        Stepper("\(viewModel.syncInterval) Minuten", value: $viewModel.syncInterval, in: 1...60)
                    }
                }
            }
            
            // Reading Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Leseeinstellungen")
                    .font(.headline)
                Toggle("Safari Reader Modus", isOn: $viewModel.enableReaderMode)
                    .toggleStyle(SwitchToggleStyle())
                Toggle("Externe Links in In-App Safari öffnen", isOn: $viewModel.openExternalLinksInApp)
                    .toggleStyle(SwitchToggleStyle())
                Toggle("Artikel automatisch als gelesen markieren", isOn: $viewModel.autoMarkAsRead)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            // Data Management
            VStack(alignment: .leading, spacing: 12) {
                Text("Datenmanagement")
                    .font(.headline)
                Button(role: .destructive) {
                    Task {
                        // await viewModel.clearCache()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Cache leeren")
                            .foregroundColor(.red)
                        Spacer()
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
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Über die App")
                    .font(.headline)
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Version \(viewModel.appVersion)")
                    Spacer()
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.secondary)
                    Text("Entwickler: \(viewModel.developerName)")
                    Spacer()
                }
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    Link("Website", destination: URL(string: "https://example.com")!)
                    Spacer()
                }
            }
            
            // Save Button
            Button(action: {
                Task {
                    await viewModel.saveSettings()
                }
            }) {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(viewModel.isSaving ? "Speichere..." : "Einstellungen speichern")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSave ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canSave || viewModel.isSaving)
            
            // Messages
            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    SettingsGeneralView(viewModel: SettingsViewModel())
} 
