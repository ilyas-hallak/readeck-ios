import Testing
import Foundation
@testable import readeck

@Suite("AnnotationsListViewModel Tests")
@MainActor
struct AnnotationsListViewModelTests {

    private func createSUT() -> (AnnotationsListViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = AnnotationsListViewModel(factory)
        return (vm, factory)
    }

    @Test("A successful delete notifies the callback with the annotation ID")
    func deleteSuccessNotifiesCallback() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteAnnotation.result = .success(())
        var notifiedId: String?
        vm.onAnnotationDeleted = { notifiedId = $0 }

        await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(notifiedId == "annotation-1")
        #expect(vm.errorMessage == nil)
    }

    @Test("A failed delete does not notify the callback")
    func deleteFailureDoesNotNotifyCallback() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteAnnotation.result = .failure(TestError.networkError)
        var callbackInvoked = false
        vm.onAnnotationDeleted = { _ in callbackInvoked = true }

        await vm.deleteAnnotation(bookmarkId: "456", annotationId: "annotation-1")

        #expect(callbackInvoked == false)
        #expect(vm.errorMessage != nil)
    }
}
