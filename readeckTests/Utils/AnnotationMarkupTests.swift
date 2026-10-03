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
}
