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
    @State private var hasFinishedSetup = true
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasFinishedSetup {
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
                    await loadSetupStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetupStatusChanged"))) { _ in
                Task {
                    await loadSetupStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))) { _ in
                Task {
                    await loadSetupStatus()
                }
            }
        }
    }

    private func loadSetupStatus() async {
        let settingsRepository = SettingsRepository()
        hasFinishedSetup = settingsRepository.hasFinishedSetup
        let settings = try? await settingsRepository.loadSettings()
        await MainActor.run {
            appSettings.settings = settings
        }
    }
}
