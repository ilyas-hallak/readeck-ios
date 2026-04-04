import Testing
@testable import readeck

@Suite("AnnotationMapper Tests")
struct AnnotationMapperTests {

    @Test("AnnotationDto.toDomain() maps all fields correctly")
    func annotationMapping() {
        let dto = AnnotationDto(
            id: "ann-789",
            text: "This is a highlighted passage from the article.",
            created: "2025-11-30T14:22:00Z",
            startOffset: 120,
            endOffset: 167,
            startSelector: "p[3]",
            endSelector: "p[3]"
        )

        let annotation = dto.toDomain()

        #expect(annotation.id == "ann-789")
        #expect(annotation.text == "This is a highlighted passage from the article.")
        #expect(annotation.created == "2025-11-30T14:22:00Z")
        #expect(annotation.startOffset == 120)
        #expect(annotation.endOffset == 167)
        #expect(annotation.startSelector == "p[3]")
        #expect(annotation.endSelector == "p[3]")
    }
}
