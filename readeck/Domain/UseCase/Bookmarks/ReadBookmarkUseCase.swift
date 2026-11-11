import Foundation

@MainActor
protocol PReadBookmarkUseCase {
    func execute(bookmarkDetail: BookmarkDetail)
}

@MainActor
final class ReadBookmarkUseCase: PReadBookmarkUseCase {
    private let addToSpeechQueue: AddTextToSpeechQueueUseCase

    init(addToSpeechQueue: AddTextToSpeechQueueUseCase = AddTextToSpeechQueueUseCase()) {
        self.addToSpeechQueue = addToSpeechQueue
    }

    func execute(bookmarkDetail: BookmarkDetail) {
        addToSpeechQueue.execute(bookmarkDetail: bookmarkDetail)
    }
}
