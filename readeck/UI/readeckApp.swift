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
    @State private var appViewModel = AppViewModel()
    @StateObject private var appSettings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showDebugMenu = false

    var body: some Scene {
        WindowGroup {
            Group {
                if appViewModel.hasFinishedSetup {
                    MainTabView()
                } else {
                    OnboardingServerView()
                        .padding()
                }
            }
            .environmentObject(appSettings)
            .environment(\.managedObjectContext, CoreDataManager.shared.context)
            .preferredColorScheme(appSettings.theme.colorScheme)
            .onShake {
                // Only show debug menu in non-production builds (DEBUG + TestFlight)
                if !Bundle.main.isProduction {
                    showDebugMenu = true
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
                    .environmentObject(appSettings)
            }
            .onAppear {
                // Start NetFox in non-production builds
                if !Bundle.main.isProduction {
                    // Disable NetFox shake gesture since we use it for our debug menu
                    NFX.sharedInstance().setGesture(.custom)
                    NFX.sharedInstance().start()
                }
                Task {
                    await loadAppSettings()
                }
                appViewModel.bindNetworkStatus(to: appSettings)
            }
            .onReceive(NotificationCenter.default.publisher(for: .settingsChanged)) { _ in
                Task {
                    await loadAppSettings()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await appViewModel.onAppResume()
                    }
                }
            }
        }
    }

    private func loadAppSettings() async {
        let settingsRepository = DefaultUseCaseFactory.shared.makeSettingsRepository()
        let settings = try? await settingsRepository.loadSettings()
        await MainActor.run {
            appSettings.settings = settings
        }
    }
}
