import Foundation

extension Notification.Name {
    // MARK: - App Lifecycle
    static let settingsChanged = Notification.Name("SettingsChanged")
    static let setupStatusChanged = Notification.Name("SetupStatusChanged")
    
    // MARK: - Authentication
    static let unauthorizedAPIResponse = Notification.Name("UnauthorizedAPIResponse")
    
    // MARK: - Network
    static let serverDidBecomeAvailable = Notification.Name("ServerDidBecomeAvailable")
    
    // MARK: - UI Interactions
    static let dismissKeyboard = Notification.Name("DismissKeyboard")
    static let addBookmarkFromShare = Notification.Name("AddBookmarkFromShare")
    
    // MARK: - User Preferences
    static let cardLayoutChanged = Notification.Name("cardLayoutChanged")
}