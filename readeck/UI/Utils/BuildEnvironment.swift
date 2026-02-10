//
//  BuildEnvironment.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

// MARK: - Build Environment Detection

extension Bundle {
    /// Returns true if running in DEBUG build (Xcode development)
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Returns true if running in TestFlight (beta distribution)
    var isTestFlightBuild: Bool {
        #if DEBUG
        return false
        #else
        guard let path = self.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
        #endif
    }

    /// Returns true if running in Production (App Store release)
    var isProduction: Bool {
        #if DEBUG
        return false
        #else
        guard let path = self.appStoreReceiptURL?.path else {
            return true
        }
        return !path.contains("sandboxReceipt")
        #endif
    }
}
