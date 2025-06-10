//
//  readeckApp.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//

import SwiftUI

@main
struct readeckApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
