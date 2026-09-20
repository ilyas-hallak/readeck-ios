//
//  ServerCapabilities.swift
//  readeck
//
//  Created by Ilyas Hallak on 04.09.26.
//

import Foundation

/// What a concrete Readeck server can do, derived from its reported version.
///
/// This is the single source of truth for version gating. Everything the app
/// or the share extension wants to know about a server ("may I send HTML?",
/// "does password login still exist?") is answered here instead of comparing
/// version strings at the call site.
///
/// ## Why the version and not `features`
///
/// `/api/info` exposes a `features` array, but it is unusable as a capability
/// source:
/// - "oauth" is hardcoded in the server and always present from 0.21.0 on. It
///   only tells us "server >= 0.21", not whether OAuth is actually usable.
/// - "email" is permission dependent. It only shows up when the calling
///   request holds `email:send`, so an unauthenticated `/api/info` never
///   reports it.
///
/// So `version.canonical` carries the mapping, `features` is consulted for
/// "email" alone, and OAuth availability comes from the
/// `/.well-known/oauth-authorization-server` document.
struct ServerCapabilities: Equatable, Sendable {
    /// The version boundaries behind the capability flags below, kept in one
    /// place so no magic literals end up spread across the code base.
    enum Boundary {
        /// `/api/info` itself only exists from 0.20.0 on, earlier servers 404.
        static let infoEndpoint = SemanticVersion(major: 0, minor: 20)
        /// Conditional requests (ETag / If-None-Match) honor token auth from 0.20.0 on.
        static let conditionalRequests = SemanticVersion(major: 0, minor: 20)
        /// Label details moved from `/labels/{label}` to `?name=` in 0.20.0.
        static let labelsNameQuery = SemanticVersion(major: 0, minor: 20)
        /// `PATCH` on annotations (highlight colors) landed in 0.17.0.
        static let annotationPatch = SemanticVersion(major: 0, minor: 17)
        /// `POST /api/auth` (password login) was removed in 0.22.0.
        static let passwordLoginRemoval = SemanticVersion(major: 0, minor: 22)
        /// Sending `html` when creating a bookmark works from 0.22.0 on.
        static let htmlBookmarkUpload = SemanticVersion(major: 0, minor: 22)
        /// The sync API exists from 0.20.0, but sorting and date bugs make it
        /// unusable until 0.22.0.
        static let syncAPI = SemanticVersion(major: 0, minor: 22)
        /// Annotations gained a `note` field in 0.22.0.
        static let annotationNotes = SemanticVersion(major: 0, minor: 22)
        /// Bookmarks gained a user note in 0.23.0.
        static let bookmarkNotes = SemanticVersion(major: 0, minor: 23)
        /// The `has_notes` filter arrived together with bookmark notes in 0.23.0.
        static let notesFilter = SemanticVersion(major: 0, minor: 23)
        /// Invalid filters return 422 with a machine-readable error object from 0.21.4 on.
        static let validationErrors = SemanticVersion(major: 0, minor: 21, patch: 4)
        /// Oldest version the app supports. 0.20.0 and 0.20.1 ship a CSRF
        /// regression that breaks every writing request, so the floor is the fix.
        static let supportFloor = SemanticVersion(major: 0, minor: 20, patch: 2)
    }

    /// Server versions whose CSRF handling rejects writing requests with 403.
    private static let versionsBrokenForWrites: Set<SemanticVersion> = [
        SemanticVersion(major: 0, minor: 20),
        SemanticVersion(major: 0, minor: 20, patch: 1)
    ]

    /// Feature name reported by `/api/info` when the caller may send mails.
    private static let emailFeature = "email"

    /// The parsed server version, or `nil` when it is unknown. Unknown means
    /// either a server below 0.20.0 (no `/api/info` at all) or an unreachable
    /// or unparsable response.
    let version: SemanticVersion?

    /// The `features` array as reported by `/api/info`, normalized to a set.
    /// Empty when the server did not send one.
    let features: Set<String>

    /// Whether `/.well-known/oauth-authorization-server` could be retrieved.
    let hasOAuthMetadata: Bool

    // swiftlint:disable:next discouraged_optional_collection
    init(version: SemanticVersion?, features: [String]? = nil, hasOAuthMetadata: Bool = false) {
        self.version = version
        self.features = Set(features ?? [])
        self.hasOAuthMetadata = hasOAuthMetadata
    }

    /// Convenience entry point for the raw `version.canonical` string. An
    /// unparsable or empty string yields the conservative unknown state.
    // swiftlint:disable:next discouraged_optional_collection
    init(versionString: String?, features: [String]? = nil, hasOAuthMetadata: Bool = false) {
        self.init(
            version: versionString.flatMap { SemanticVersion($0) },
            features: features,
            hasOAuthMetadata: hasOAuthMetadata
        )
    }

    /// The state for a server we know nothing about: everything new is off,
    /// but password login stays available because pre-0.20 servers do have
    /// `/api/auth`.
    static let unknown = Self(version: nil)

    // MARK: - Authentication

    /// `POST /api/auth` exists below 0.22.0 only, it was removed in 0.22.0.
    /// Assumed available for unknown versions, since those are older servers.
    var canUsePasswordLogin: Bool {
        guard let version else { return true }
        return version < Boundary.passwordLoginRemoval
    }

    /// OAuth2 is usable when the authorization server metadata is reachable.
    /// Deliberately not derived from `features`, where "oauth" is hardcoded
    /// from 0.21.0 on and says nothing about actual availability.
    var canUseOAuth: Bool {
        hasOAuthMetadata
    }

    // MARK: - Bookmarks

    /// Sending pre-rendered `html` with a bookmark create requires 0.22.0.
    var supportsHTMLBookmarkUpload: Bool {
        isAtLeast(Boundary.htmlBookmarkUpload)
    }

    /// Bookmarks carry a user note from 0.23.0 on.
    var supportsBookmarkNotes: Bool {
        isAtLeast(Boundary.bookmarkNotes)
    }

    /// The `has_notes` bookmark filter exists from 0.23.0 on.
    var supportsNotesFilter: Bool {
        isAtLeast(Boundary.notesFilter)
    }

    // MARK: - Annotations

    /// `PATCH` on annotations, used for highlight colors, exists from 0.17.0 on.
    var supportsAnnotationPatch: Bool {
        isAtLeast(Boundary.annotationPatch)
    }

    /// Annotations have a `note` field from 0.22.0 on.
    var supportsAnnotationNotes: Bool {
        isAtLeast(Boundary.annotationNotes)
    }

    // MARK: - Sync and transport

    /// The sync API is only trustworthy from 0.22.0 on, earlier releases have
    /// sorting and date bugs.
    var supportsSyncAPI: Bool {
        isAtLeast(Boundary.syncAPI)
    }

    /// ETag based conditional requests work with token auth from 0.20.0 on.
    var supportsConditionalRequests: Bool {
        isAtLeast(Boundary.conditionalRequests)
    }

    /// Label details are queried via `?name=` instead of `/labels/{label}`
    /// from 0.20.0 on.
    var supportsLabelsNameQuery: Bool {
        isAtLeast(Boundary.labelsNameQuery)
    }

    /// Invalid filter values come back as 422 with a structured error object
    /// from 0.21.4 on, so the app can surface the offending field.
    var supportsValidationErrors: Bool {
        isAtLeast(Boundary.validationErrors)
    }

    // MARK: - Feature flags

    /// Mail sharing is the one capability that has to come from `features`.
    /// It only appears when the request that asked for `/api/info` was
    /// authenticated and holds the `email:send` permission.
    var supportsEmailSharing: Bool {
        features.contains(Self.emailFeature)
    }

    // MARK: - Health

    /// 0.20.0 and 0.20.1 reject every writing request with 403 because of a
    /// CSRF regression, fixed in 0.20.2.
    var isKnownBrokenForWrites: Bool {
        guard let version else { return false }
        return Self.versionsBrokenForWrites.contains(version)
    }

    /// Below the supported floor of 0.20.2, which includes servers whose
    /// version we could not determine at all.
    var isBelowSupportFloor: Bool {
        guard let version else { return true }
        return version < Boundary.supportFloor
    }

    // MARK: - Helpers

    /// Version gate that stays conservative when the version is unknown.
    private func isAtLeast(_ boundary: SemanticVersion) -> Bool {
        guard let version else { return false }
        return version >= boundary
    }
}
