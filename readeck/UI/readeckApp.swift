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

    #if DEBUG
    @State private var showDebugMenu = false
    #endif

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
            #if DEBUG
            .onShake {
                showDebugMenu = true
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
                    .environmentObject(appSettings)
            }
            #endif
            .onAppear {
                #if DEBUG
                NFX.sharedInstance().start()
                #endif
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    Task {
                        await appViewModel.onAppResume()
                    }
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
