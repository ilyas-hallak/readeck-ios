//
//  SettingsGeneralView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsGeneralView: View {
    @State private var viewModel: SettingsGeneralViewModel        
    
    init(viewModel: SettingsGeneralViewModel = SettingsGeneralViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "General Settings", icon: "gear")
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
            
            // Sync Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Sync Settings")
                    .font(.headline)
                Toggle("Automatic sync", isOn: $viewModel.autoSyncEnabled)
                    .toggleStyle(SwitchToggleStyle())
                if viewModel.autoSyncEnabled {
                    HStack {
                        Text("Sync interval")
                        Spacer()
                        Stepper("\(viewModel.syncInterval) minutes", value: $viewModel.syncInterval, in: 1...60)
                    }
                }
            }
            
            // Reading Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Reading Settings")
                    .font(.headline)
                Toggle("Safari Reader Mode", isOn: $viewModel.enableReaderMode)
                    .toggleStyle(SwitchToggleStyle())
                Toggle("Open external links in in-app Safari", isOn: $viewModel.openExternalLinksInApp)
                    .toggleStyle(SwitchToggleStyle())
                Toggle("Automatically mark articles as read", isOn: $viewModel.autoMarkAsRead)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            // Data Management
            VStack(alignment: .leading, spacing: 12) {
                Text("Data Management")
                    .font(.headline)
                Button(role: .destructive) {
                    Task {
                        // await viewModel.clearCache()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear cache")
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
                        Text("Reset settings")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 12) {
                Text("About the App")
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
                    Text("Developer: \(viewModel.developerName)")
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
                    await viewModel.saveGeneralSettings()
                }
            }) {
                HStack {
                    Text("Save settings")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
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
        .task {
            await viewModel.loadGeneralSettings()
        }
    }
}

enum Theme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}


#Preview {
    SettingsGeneralView(viewModel: .init(
        MockUseCaseFactory()
    ))
}
