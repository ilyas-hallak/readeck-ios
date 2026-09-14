import Testing
@testable import readeck

@Suite("ArticleReaderAvailability")
struct ArticleReaderAvailabilityTests {

    // MARK: - Device support

    @Test("iOS 26 without macOS supports the native reader")
    func supportedOnIOS26() {
        #expect(ArticleReaderAvailability.isNativeReaderSupported(isOS26OrNewer: true, isiOSAppOnMac: false))
    }

    @Test("Below iOS 26 the native reader is unsupported")
    func unsupportedBelowIOS26() {
        #expect(!ArticleReaderAvailability.isNativeReaderSupported(isOS26OrNewer: false, isiOSAppOnMac: false))
    }

    @Test("iOS app on macOS never supports the native reader (issue #24 crash)")
    func unsupportedOnMac() {
        #expect(!ArticleReaderAvailability.isNativeReaderSupported(isOS26OrNewer: true, isiOSAppOnMac: true))
        #expect(!ArticleReaderAvailability.isNativeReaderSupported(isOS26OrNewer: false, isiOSAppOnMac: true))
    }

    // MARK: - Reader selection

    @Test("Supported device plus user preference selects the native reader")
    func nativeWhenSupportedAndPreferred() {
        #expect(ArticleReaderAvailability.reader(isNativeReaderSupported: true, prefersNativeReader: true) == .native)
    }

    @Test("User preference off falls back to the legacy reader")
    func legacyWhenNotPreferred() {
        #expect(ArticleReaderAvailability.reader(isNativeReaderSupported: true, prefersNativeReader: false) == .legacy)
    }

    @Test("Unsupported device always uses the legacy reader")
    func legacyWhenUnsupported() {
        #expect(ArticleReaderAvailability.reader(isNativeReaderSupported: false, prefersNativeReader: true) == .legacy)
        #expect(ArticleReaderAvailability.reader(isNativeReaderSupported: false, prefersNativeReader: false) == .legacy)
    }
}
