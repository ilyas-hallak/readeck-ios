import Testing
@testable import readeck

@Suite("ReaderSwitchTip upgrade detection")
struct ReaderSwitchTipTests {

    @Test("A fresh install is not an upgrade")
    func freshInstall() {
        #expect(!ReaderSwitchTip.isUpgrade(lastSeenVersion: nil, currentVersion: "3.2.0"))
    }

    @Test("Coming from an older version is an upgrade")
    func comingFromOlderVersion() {
        #expect(ReaderSwitchTip.isUpgrade(lastSeenVersion: "3.1.0", currentVersion: "3.2.0"))
    }

    @Test("Relaunching the same version is not an upgrade")
    func sameVersion() {
        #expect(!ReaderSwitchTip.isUpgrade(lastSeenVersion: "3.2.0", currentVersion: "3.2.0"))
    }

    @Test("Any version change counts, including a downgrade")
    func downgrade() {
        #expect(ReaderSwitchTip.isUpgrade(lastSeenVersion: "3.3.0", currentVersion: "3.2.0"))
    }
}
