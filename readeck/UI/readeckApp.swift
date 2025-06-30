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
    @State private var hasFinishedSetup = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasFinishedSetup {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    SettingsContainerView()
                }
            }
            .onOpenURL { url in
                handleIncomingURL(url)
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

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "readeck",
              url.host == "add-bookmark" else {
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems
        
        let urlToAdd = queryItems?.first(where: { $0.name == "url" })?.value
        let title = queryItems?.first(where: { $0.name == "title" })?.value
        let notes = queryItems?.first(where: { $0.name == "notes" })?.value
        
        // Öffne AddBookmarkView mit den Daten
        // Hier kannst du eine Notification posten oder einen State ändern
        NotificationCenter.default.post(
            name: NSNotification.Name("AddBookmarkFromShare"),
            object: nil,
            userInfo: [
                "url": urlToAdd ?? "",
                "title": title ?? "",
                "notes": notes ?? ""
            ]
        )
    }
}
