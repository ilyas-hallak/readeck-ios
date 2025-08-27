//
//  readeckApp.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//

import SwiftUI
import netfox

@main
struct readeckApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            Group {
                if appViewModel.hasFinishedSetup {
                    MainTabView()
                } else {
                    SettingsServerView()
                        .padding()
                }
            }
            .environmentObject(appSettings)
            .preferredColorScheme(appSettings.theme.colorScheme)
            .onAppear {
                #if DEBUG
                NFX.sharedInstance().start()
                #endif
                // Initialize server connectivity monitoring
                _ = ServerConnectivity.shared
                Task {
                    await loadAppSettings()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))) { _ in
                Task {
                    await loadAppSettings()
                }
            }
        }
    }

    private func loadAppSettings() async {
        let settingsRepository = SettingsRepository()
        let settings = try? await settingsRepository.loadSettings()
        await MainActor.run {
            appSettings.settings = settings
        }
    }
}
