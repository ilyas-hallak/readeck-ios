import Testing
@testable import readeck

@Suite("AnnotationMarkup Tests")
struct AnnotationMarkupTests {

    @Test("Collects each highlight ID once, even when it spans several tags")
    func collectsUniqueIds() {
        let html = """
        <p><rd-annotation id="annotation-a" data-annotation-id-value="a" data-annotation-color="yellow">one</rd-annotation></p>
        <p><rd-annotation data-annotation-id-value="a" data-annotation-color="yellow">two</rd-annotation></p>
        <p><rd-annotation data-annotation-color="green" data-annotation-id-value="b">three</rd-annotation></p>
        """

        #expect(AnnotationMarkup.annotationIds(in: html) == ["a", "b"])
    }

    @Test("Returns no IDs for HTML without highlights")
    func noHighlights() {
        let html = #"<p data-annotation-id-value="x">plain</p>"#

        #expect(AnnotationMarkup.annotationIds(in: html).isEmpty)
    }

    @Test("Unwraps a single highlight span, keeping its text")
    func removesSingleSpan() {
        let html = #"<p><rd-annotation data-annotation-id-value="a">hello</rd-annotation> world</p>"#

        #expect(AnnotationMarkup.removingAnnotation(id: "a", from: html) == "<p>hello world</p>")
    }

    @Test("Unwraps every tag of a multi paragraph highlight sharing the same ID")
    func removesAllSpansOfTheSameId() {
        let html = """
        <p><rd-annotation data-annotation-id-value="a">one</rd-annotation></p>
        <p><rd-annotation data-annotation-id-value="a">two</rd-annotation></p>
        """

        let result = AnnotationMarkup.removingAnnotation(id: "a", from: html)

        #expect(result == "<p>one</p>\n<p>two</p>")
    }

    @Test("Leaves highlights with a different ID untouched")
    func leavesOtherIdsUntouched() {
        let html = #"<p><rd-annotation data-annotation-id-value="a">one</rd-annotation></p><p><rd-annotation data-annotation-id-value="b">two</rd-annotation></p>"#

        let result = AnnotationMarkup.removingAnnotation(id: "a", from: html)

        #expect(result == #"<p>one</p><p><rd-annotation data-annotation-id-value="b">two</rd-annotation></p>"#)
    }
}
