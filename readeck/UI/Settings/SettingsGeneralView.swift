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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("General")
                    .font(.headline)
                Toggle("Read Aloud Feature", isOn: $viewModel.enableTTS)
                    .toggleStyle(.switch)
                    .onChange(of: viewModel.enableTTS) {
                        Task {
                            await viewModel.saveGeneralSettings()
                        }
                    }
                Text("Activate the Read Aloud Feature to read aloud your articles. This is a really early preview and might not work perfectly.")
                    .font(.footnote)
            }
            
            #if DEBUG
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
            #endif
            
        }
        .task {
            await viewModel.loadGeneralSettings()
        }
    }
}

#Preview {
    SettingsGeneralView(viewModel: .init(
        MockUseCaseFactory()
    ))
}
