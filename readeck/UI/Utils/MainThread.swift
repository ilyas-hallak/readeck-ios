import Foundation

enum MainThread {
    /// Runs `action` right away on the main thread and hops there from any other thread.
    /// For system callbacks that do not promise a thread, so they never trip the main actor check.
    static func run(_ action: @escaping @MainActor @Sendable () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(action)
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
