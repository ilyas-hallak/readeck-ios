import Foundation

class ReadBookmarkUseCase {
    private let addToSpeechQueue: AddTextToSpeechQueueUseCase

    init(addToSpeechQueue: AddTextToSpeechQueueUseCase = AddTextToSpeechQueueUseCase()) {
        self.addToSpeechQueue = addToSpeechQueue
    }

    func execute(bookmarkDetail: BookmarkDetail) {
        addToSpeechQueue.execute(bookmarkDetail: bookmarkDetail)
    }
} 
