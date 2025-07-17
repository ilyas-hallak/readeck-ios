import Foundation

protocol PReadBookmarkUseCase {
    func execute(bookmarkDetail: BookmarkDetail)
}

class ReadBookmarkUseCase: PReadBookmarkUseCase {
    private let addToSpeechQueue: AddTextToSpeechQueueUseCase

    init(addToSpeechQueue: AddTextToSpeechQueueUseCase = AddTextToSpeechQueueUseCase()) {
        self.addToSpeechQueue = addToSpeechQueue
    }

    func execute(bookmarkDetail: BookmarkDetail) {
        addToSpeechQueue.execute(bookmarkDetail: bookmarkDetail)
    }
} 
