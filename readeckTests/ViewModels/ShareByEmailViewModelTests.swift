import Testing
import Foundation
@testable import readeck

@Suite("ShareByEmailViewModel Tests")
@MainActor
struct ShareByEmailViewModelTests {

    private func createSUT() -> (ShareByEmailViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        return (ShareByEmailViewModel(bookmarkId: "abc", factory: factory), factory)
    }

    @Test("Send is only possible with a plausible address", arguments: [
        ("", false),
        ("alice", false),
        ("alice @example.com", false),
        ("alice@example.com", true),
        ("  alice@example.com\n", true)
    ])
    func canSendValidation(email: String, expected: Bool) {
        let (vm, _) = createSUT()
        vm.email = email
        #expect(vm.canSend == expected)
    }

    @Test("Sending passes the trimmed address and chosen format")
    func sendSuccess() async {
        let (vm, factory) = createSUT()
        vm.email = " alice@example.com "
        vm.format = .epub

        let sent = await vm.send()

        #expect(sent)
        #expect(factory.mockShareByEmail.lastEmail == "alice@example.com")
        #expect(factory.mockShareByEmail.lastFormat == .epub)
        #expect(vm.errorMessage == nil)
        #expect(vm.isSending == false)
    }

    @Test("A failed send sets an error and resets the sending state")
    func sendFailure() async {
        let (vm, factory) = createSUT()
        factory.mockShareByEmail.result = .failure(TestError.networkError)
        vm.email = "alice@example.com"

        let sent = await vm.send()

        #expect(!sent)
        #expect(vm.errorMessage != nil)
        #expect(vm.isSending == false)
    }

    @Test("An invalid address never reaches the use case")
    func sendInvalidAddress() async {
        let (vm, factory) = createSUT()
        vm.email = "alice"

        let sent = await vm.send()

        #expect(!sent)
        #expect(factory.mockShareByEmail.executeCount == 0)
    }
}
