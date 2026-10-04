import Foundation

@Observable
final class ShareByEmailViewModel {
    private let bookmarkId: String
    private let shareByEmailUseCase: PShareByEmailUseCase

    var email = ""
    var format: EmailShareFormat = .html
    var isSending = false
    var errorMessage: String?

    /// A light check only, the server validates the address properly.
    var canSend: Bool {
        !isSending && trimmedEmail.contains("@") && !trimmedEmail.contains(" ")
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(bookmarkId: String, factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.bookmarkId = bookmarkId
        self.shareByEmailUseCase = factory.makeShareByEmailUseCase()
    }

    @MainActor
    func send() async -> Bool {
        guard canSend else { return false }

        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            try await shareByEmailUseCase.execute(bookmarkId: bookmarkId, email: trimmedEmail, format: format)
            return true
        } catch {
            Logger.viewModel.error("❌ Sending by email failed: \(error.localizedDescription)")
            errorMessage = NSLocalizedString("Could not send the email", comment: "Share by email error")
            return false
        }
    }
}
