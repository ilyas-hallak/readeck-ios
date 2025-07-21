//
//  AppSettings.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//


//
//  AppSettings.swift
//  readeck
//
//  SPDX-License-Identifier: MIT
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var settings: Settings?
    
    var enableTTS: Bool {
        settings?.enableTTS ?? false
    }

    init(settings: Settings? = nil) {
        self.settings = settings
    }
}
