import Foundation

class AddTextToSpeechQueueUseCase {
    private let speechQueue: SpeechQueue

    init(speechQueue: SpeechQueue = .shared) {
        self.speechQueue = speechQueue
    }

    func execute(bookmarkDetail: BookmarkDetail) {
        var text = bookmarkDetail.title + "\n"
        if let content = bookmarkDetail.content {
            text += content.stripHTML
        } else {
            text += bookmarkDetail.description.stripHTML
        }
        speechQueue.enqueue(bookmarkDetail.toSpeechQueueItem(text))
    }
} 
