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
            .onAppear {
                #if DEBUG
                NFX.sharedInstance().start()
                #endif
                Task {
                    await loadAppSettings()
                }
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


struct TestView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Text("hello")
                .toolbar {
                    ToolbarSpacer(.flexible)

                    ToolbarItem {
                        Button {
                            
                        } label: {
                            Label("Favorite", systemImage: "share")
                                .symbolVariant(.none)
                        }
                    }

                    ToolbarSpacer(.fixed)
                    
                    ToolbarItemGroup {
                        Button {
                            
                        } label: {
                            Label("Favorite", systemImage: "heart")
                                .symbolVariant(.none)
                        }
                        
                        Button("Info", systemImage: "info") {
                            
                        }
                    }
                    
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        Button {
                            
                        } label: {
                            Label("Favorite", systemImage: "heart")
                                .symbolVariant(.none)
                        }
                        
                        Button("Info", systemImage: "info") {
                            
                        }
                    }
                    
                }
                .toolbar(removing: .title)
                .ignoresSafeArea(edges: .top)
        } else {
            Text("hello1")
        }
    }
}
