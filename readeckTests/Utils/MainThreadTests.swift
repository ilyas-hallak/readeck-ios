import Testing
import Foundation
import Synchronization
@testable import readeck

@Suite("MainThread Tests")
struct MainThreadTests {

    @Test("Running from the main thread executes right away, not queued for later")
    @MainActor
    func runsSynchronouslyOnTheMainThread() {
        let ran = Mutex(false)
        MainThread.run { ran.withLock { $0 = true } }
        #expect(ran.withLock { $0 })
    }

    @Test("Running from a background thread hops to the main thread")
    func hopsToTheMainThreadFromTheBackground() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                MainThread.run {
                    continuation.resume()
                }
            }
        }
    }
}
