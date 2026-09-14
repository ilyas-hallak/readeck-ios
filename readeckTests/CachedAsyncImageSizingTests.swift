import Testing
import CoreGraphics
@testable import readeck

@Suite("CachedAsyncImage Sizing Tests")
struct CachedAsyncImageSizingTests {

    @Test("Original keeps the source resolution")
    func original_hasNoLimit() {
        #expect(CachedAsyncImage.Sizing.original.maxDimension == nil)
    }

    @Test("Fit is bounded by the longer box edge")
    func fit_usesLongerEdge() {
        let sizing = CachedAsyncImage.Sizing.fit(CGSize(width: 393, height: 360))

        #expect(sizing.maxDimension == 393)
    }

    @Test("Fill budgets for the shorter edge being covered")
    func fill_budgetsForCropping() {
        // A 393x140 magazine header crops a landscape image, so the longer edge of the
        // box is still the limit here.
        #expect(CachedAsyncImage.Sizing.fill(CGSize(width: 393, height: 140)).maxDimension == 393)

        // A square thumbnail has no longer edge to fall back on, so the budget doubles.
        #expect(CachedAsyncImage.Sizing.fill(CGSize(width: 80, height: 80)).maxDimension == 160)
    }

    @Test("Width allows for a portrait image")
    func width_allowsTallerThanWide() {
        #expect(CachedAsyncImage.Sizing.width(300).maxDimension == 450)
    }

    @Test("A zero sized box carries no usable limit")
    func zeroBox_hasNoUsableLimit() {
        #expect(CachedAsyncImage.Sizing.fit(.zero).maxDimension == 0)
    }
}
