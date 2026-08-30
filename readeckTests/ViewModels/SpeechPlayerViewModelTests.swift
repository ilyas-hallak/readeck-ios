import Testing
import Foundation
import Observation
@testable import readeck

/// Guards the wiring the @Observable migration replaced: the player view model
/// no longer mirrors state through Combine, it reads TTSManager and SpeechQueue
/// through computed properties.
@Suite("SpeechPlayerViewModel Tests", .serialized)
@MainActor
struct SpeechPlayerViewModelTests {

    private func makeItem(id: String) -> SpeechQueueItem {
        SpeechQueueItem(
            id: id,
            title: "Title \(id)",
            content: "Some spoken content",
            url: "https://example.com/\(id)",
            labels: nil,
            imageUrl: nil,
            language: "en",
            lastCharacterIndex: 0,
            totalCharacters: 20
        )
    }

    @Test("Queue changes are visible through the view model")
    func queueChangesArrive() async {
        let vm = SpeechPlayerViewModel()
        await vm.setup()
        SpeechQueue.shared.clear()

        SpeechQueue.shared.enqueue(makeItem(id: "1"))

        #expect(vm.queueCount == 1)
        #expect(vm.hasItems == true)
        #expect(vm.currentItem?.id == "1")

        SpeechQueue.shared.clear()
    }

    @Test("Clearing through the view model empties the shared queue")
    func clearQueueReachesTheQueue() async {
        let vm = SpeechPlayerViewModel()
        await vm.setup()
        SpeechQueue.shared.enqueue(makeItem(id: "1"))
        #expect(vm.queueCount == 1)

        vm.clearQueue()

        #expect(SpeechQueue.shared.queueItems.isEmpty)
        #expect(vm.queueCount == 0)
    }

    @Test("Observation fires for a SwiftUI-style read of the computed properties")
    func observationTracksComputedProperties() async {
        let vm = SpeechPlayerViewModel()
        await vm.setup()
        SpeechQueue.shared.clear()

        var didFire = false
        // Mirrors what SwiftUI does when a view body reads viewModel.queueCount.
        withObservationTracking {
            _ = vm.queueCount
        } onChange: {
            didFire = true
        }

        SpeechQueue.shared.enqueue(makeItem(id: "1"))

        #expect(didFire == true)

        SpeechQueue.shared.clear()
    }
}
