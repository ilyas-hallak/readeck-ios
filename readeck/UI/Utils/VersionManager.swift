import Foundation

class VersionManager {
    static let shared = VersionManager()

    private let lastSeenVersionKey = "lastSeenAppVersion"
    private let userDefaults = UserDefaults.standard

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var fullVersion: String {
        "\(currentVersion) (\(currentBuild))"
    }

    var lastSeenVersion: String? {
        userDefaults.string(forKey: lastSeenVersionKey)
    }

    var isNewVersion: Bool {
        guard let lastSeen = lastSeenVersion else {
            // First launch
            return true
        }
        return lastSeen != currentVersion
    }

    func markVersionAsSeen() {
        userDefaults.set(currentVersion, forKey: lastSeenVersionKey)
    }

    private init() {}
}
