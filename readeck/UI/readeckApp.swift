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
    let persistenceController = PersistenceController.shared
    @State private var hasFinishedSetup = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasFinishedSetup {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    SettingsServerView()
                        .padding()
                }
            }
            .onAppear {
                #if DEBUG
                NFX.sharedInstance().start()
                #endif
                loadSetupStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetupStatusChanged"))) { _ in
                loadSetupStatus()
            }
        }
    }
    
    private func loadSetupStatus() {
        let settingsRepository = SettingsRepository()
        hasFinishedSetup = settingsRepository.hasFinishedSetup
    }
}
