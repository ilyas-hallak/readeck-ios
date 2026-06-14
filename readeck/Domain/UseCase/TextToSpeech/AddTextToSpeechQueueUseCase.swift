import Foundation

protocol PAddTextToSpeechQueueUseCase {
    func execute(bookmarkDetail: BookmarkDetail)
}

final class AddTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase {
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
