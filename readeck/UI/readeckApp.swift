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
    @State private var appSettings = AppSettings()
    @State private var deepLinkRouter = DeepLinkRouter()
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
            .environment(appSettings)
            .environment(deepLinkRouter)
            .environment(\.managedObjectContext, CoreDataManager.shared.context)
            .preferredColorScheme(appSettings.theme.colorScheme)
            .oledTheme(appSettings.theme.isOLED)
            .onOpenURL { url in
                deepLinkRouter.handle(url: url)
            }
            .onShake {
                // Only show debug menu in non-production builds (DEBUG + TestFlight)
                if !Bundle.main.isProduction {
                    showDebugMenu = true
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
                    .environment(appSettings)
            }
            .onAppear {
                // Start NetFox in non-production builds
                if !Bundle.main.isProduction {
                    // Disable NetFox shake gesture since we use it for our debug menu
                    NFX.sharedInstance().setGesture(.custom)
                    NFX.sharedInstance().start()
                }
                Task {
                    // Repair stored values before anything reads settings.
                    await DataMigrator().runPending()
                    await loadAppSettings()
                }
                Task {
                    // Enforce the configured image-cache size limit at launch so the
                    // cache doesn't grow past the maximum across app restarts (Codeberg #44).
                    try? await DefaultUseCaseFactory.shared.makeApplyCacheSizeLimitUseCase().execute()
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
                } else if newPhase == .background {
                    Task {
                        await appViewModel.refreshBadge()
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
