# OAuth 2.0 Authentication - Implementation Plan

**Date:** December 19, 2025
**Status:** In Progress (Phase 1-4 Complete ✅)
**Goal:** Add OAuth 2.0 authentication support as an alternative to API token authentication

---

## 📋 Overview

### Current Situation (Updated)

- ✅ **Phase 1-4 Complete:** ServerInfo extended, OAuth core implemented, browser integration done, token management working
- ✅ **Direct OAuth Flow:** No login method selection - OAuth is tried automatically if server supports it
- ✅ **Fallback to Classic:** If OAuth fails or is not supported, classic username/password login is shown
- ✅ **Endpoint Storage:** Endpoint is now saved in both TokenProvider and Settings
- ❌ **API Integration:** API calls don't yet use OAuth tokens properly
- ❌ **Testing:** Manual and integration testing not complete

### What's Implemented ✅

**Phase 1: ServerInfo Extended**
- ✅ `ServerInfoDto` with nested `VersionInfo` struct (canonical, release, build)
- ✅ `ServerInfo` model with `features: [String]?` and `supportsOAuth` computed property
- ✅ `GetServerInfoUseCase` with optional endpoint parameter
- ✅ `InfoApiClient` with endpoint parameter logic (custom endpoint vs TokenProvider)
- ✅ Unit tests for ServerInfo and feature detection
- ✅ Backward compatibility with old servers

**Phase 2: OAuth Core**
- ✅ `PKCEGenerator` with verifier/challenge generation
- ✅ OAuth DTOs: `OAuthClientCreateDto`, `OAuthClientResponseDto`, `OAuthTokenRequestDto`, `OAuthTokenResponseDto`
- ✅ Domain models: `OAuthClient`, `OAuthToken`, `AuthenticationMethod`
- ✅ `API.swift` extended with OAuth methods (`registerOAuthClient`, `exchangeOAuthToken`)
- ✅ `OAuthRepository` + `POAuthRepository` protocol
- ✅ `OAuthManager` orchestrates OAuth flow
- ✅ Unit tests for PKCEGenerator

**Phase 3: Browser Integration**
- ✅ `OAuthSession` wraps `ASWebAuthenticationSession`
- ✅ `OAuthFlowCoordinator` manages 5-phase OAuth flow
- ✅ `readeck://` URL scheme registered in Info.plist
- ✅ State verification for CSRF protection
- ✅ Error handling for user cancellation

**Phase 4: Token Management**
- ✅ `AuthenticationMethod` enum (apiToken, oauth)
- ✅ `TokenProvider` extended with OAuth methods (`getOAuthToken`, `setOAuthToken`, `getAuthMethod`, `setAuthMethod`)
- ✅ `setEndpoint(_ endpoint: String)` added to TokenProvider
- ✅ `KeychainHelper` extended with OAuth token storage
- ✅ `KeychainTokenProvider` handles both token types
- ✅ `AuthRepository` extended with `loginWithOAuth`, `getAuthenticationMethod`, `switchToClassicAuth`
- ✅ Endpoint now saved in TokenProvider (was missing before)

**Phase 5: UI & UX (Partially Complete)**
- ✅ `OnboardingServerView` refactored with 2-phase flow:
  - Phase 1: Only endpoint field + Readeck logo
  - Phase 2a: OAuth attempted automatically if server supports it
  - Phase 2b: Username/Password fields shown if OAuth not supported or fails
- ✅ `SettingsServerViewModel` extended with `checkServerOAuthSupport()` and `loginWithOAuth()`
- ✅ `LoginWithOAuthUseCase` created
- ✅ Factories updated (DefaultUseCaseFactory, MockUseCaseFactory)
- ❌ LoginMethodSelectionView removed (no longer needed - OAuth is automatic)

**Removed/Changed:**
- ❌ All `#if os(iOS) && !APP_EXTENSION` checks removed
- ❌ `LoginMethodSelectionView` removed - OAuth is now attempted automatically
- ❌ `showLoginMethodSelection` flag removed
- ✅ Direct OAuth attempt with fallback to classic login on error

---

## 🎯 Updated Goals

1. ~~**User Choice**~~ **Automatic OAuth**: OAuth is attempted automatically if server supports it
2. **Auto-Detection**: ✅ Automatically detect if server supports OAuth via `/info` endpoint
3. **Security**: ✅ OAuth 2.0 Authorization Code Flow with PKCE (S256)
4. **UX**: ✅ Seamless browser-based authentication using `ASWebAuthenticationSession`
5. **Fallback**: ✅ Graceful fallback to username/password if OAuth fails or is not supported
6. **Migration Path**: ❌ Not yet implemented for existing users

---

## 🔍 API Analysis

### Server Info Response (Actual Format)

```json
{
  "version": {
    "canonical": "0.21.4",
    "release": "0.21.4",
    "build": ""
  },
  "features": ["oauth"]
}
```

**Changes from Original Plan:**
- `version` is now an object, not a string
- `buildDate` and `userAgent` removed (not in actual response)
- `features` is optional (only in newer servers)

### OAuth Endpoints

1. **Feature Detection**: `GET /api/info` (no auth)
2. **Client Registration**: `POST /api/oauth/client` (no auth)
3. **Authorization**: `GET /authorize` (browser, web page)
4. **Token Exchange**: `POST /api/oauth/token` (application/x-www-form-urlencoded)

---

## 🏗️ Architecture (Updated)

### Data Flow

```
User Input → OnboardingServerView
  ↓
SettingsServerViewModel.checkServerOAuthSupport()
  ↓
GetServerInfoUseCase.execute(endpoint: normalizedEndpoint)
  ↓
ServerInfoRepository.getServerInfo(endpoint: normalizedEndpoint)
  ↓
InfoApiClient.getServerInfo(endpoint: normalizedEndpoint)
  ↓
GET {endpoint}/api/info (no auth token)
  ↓
Response: { version: {...}, features: ["oauth"] }
  ↓
serverSupportsOAuth = true
  ↓
SettingsServerViewModel.loginWithOAuth()
  ↓
LoginWithOAuthUseCase.execute(endpoint)
  ↓
OAuthFlowCoordinator.executeOAuthFlow(endpoint)
  ↓
[OAuth flow: client registration → browser → token exchange]
  ↓
AuthRepository.loginWithOAuth(endpoint, token)
  ↓
TokenProvider saves: OAuthToken, AuthMethod, Endpoint
  ↓
User logged in ✅
```

### Key Components

**Domain Layer:**
- `ServerInfo` (version, features, supportsOAuth)
- `OAuthClient` (clientId, clientSecret, redirectUris, etc.)
- `OAuthToken` (accessToken, tokenType, scope, expiresIn, refreshToken, createdAt)
- `AuthenticationMethod` enum (apiToken, oauth)

**Data Layer:**
- `InfoApiClient` - handles `/api/info` with optional endpoint parameter
- `API` - extended with OAuth client registration and token exchange
- `OAuthRepository` - orchestrates OAuth API calls
- `OAuthManager` - business logic for OAuth flow
- `OAuthSession` - wraps ASWebAuthenticationSession
- `OAuthFlowCoordinator` - coordinates complete 5-phase flow

**Use Cases:**
- `GetServerInfoUseCase(endpoint: String?)` - get server info with optional custom endpoint
- `LoginWithOAuthUseCase` - execute OAuth login flow
- `CheckServerReachabilityUseCase` - check if server is reachable (existing)

**UI Layer:**
- `OnboardingServerView` - 2-phase onboarding (endpoint → OAuth or classic)
- `SettingsServerViewModel` - extended with OAuth support

---

## 🎨 User Experience Flow (Updated)

### New User Onboarding

```
1. User opens app
   ↓
2. Screen shows:
   - Readeck logo (green circle)
   - "Enter your Readeck server"
   - Endpoint text field
   - Chips: http://, https://, 192.168., :8000
   - "Continue" button
   ↓
3. User enters endpoint (e.g., https://readeck.example.com)
   ↓
4. User taps "Continue"
   ↓
5. App normalizes endpoint and calls /api/info
   ↓
6a. If OAuth supported:
    ↓
    App automatically starts OAuth flow
    ↓
    Browser opens with /authorize page
    ↓
    User logs in with username/password on server
    ↓
    User approves permissions
    ↓
    Redirect to readeck://oauth-callback?code=...
    ↓
    App exchanges code for token
    ↓
    Token + endpoint saved
    ↓
    User logged in ✅

6b. If OAuth NOT supported OR OAuth fails:
    ↓
    Username and Password fields appear
    ↓
    Text changes to "Enter your credentials"
    ↓
    Button changes to "Login & Save"
    ↓
    User enters credentials
    ↓
    Classic API token login
    ↓
    User logged in ✅
```

**Key UX Changes:**
- No login method selection screen (removed)
- OAuth is attempted automatically
- Fallback to classic is seamless
- User sees endpoint field first, login fields only if needed

---

## 🚀 Implementation Status

### ✅ Phase 1: ServerInfo Extended (COMPLETE)
- ✅ `ServerInfoDto` with `VersionInfo` nested struct
- ✅ `ServerInfo.features` optional array
- ✅ `supportsOAuth` computed property
- ✅ `GetServerInfoUseCase` with endpoint parameter
- ✅ Backward compatibility tests
- ✅ Mock implementations updated

### ✅ Phase 2: OAuth Core (COMPLETE)
- ✅ PKCEGenerator (verifier + challenge)
- ✅ All OAuth DTOs created
- ✅ Domain models created
- ✅ API methods implemented
- ✅ OAuthRepository created
- ✅ OAuthManager created
- ✅ Unit tests for PKCE

### ✅ Phase 3: Browser Integration (COMPLETE)
- ✅ OAuthSession wraps ASWebAuthenticationSession
- ✅ OAuthFlowCoordinator manages complete flow
- ✅ URL scheme registered (readeck://)
- ✅ State verification
- ✅ Error handling

### ✅ Phase 4: Token Management (COMPLETE)
- ✅ AuthenticationMethod enum
- ✅ TokenProvider extended with OAuth methods
- ✅ `setEndpoint()` added to TokenProvider
- ✅ KeychainHelper extended
- ✅ Token type detection in getToken()
- ✅ AuthRepository extended
- ✅ Endpoint saved in both TokenProvider and Settings

### 🟡 Phase 5: Use Cases & ViewModels (MOSTLY COMPLETE)
- ✅ LoginWithOAuthUseCase created
- ✅ AuthRepository extended
- ✅ SettingsServerViewModel extended
- ✅ Factories updated
- ❌ LoginMethodSelectionView removed (design change)
- ❌ Integration tests not complete

### 🟡 Phase 6: UI Implementation (MOSTLY COMPLETE)
- ✅ OnboardingServerView refactored (2-phase flow)
- ✅ Readeck logo with green background
- ✅ Dynamic text based on phase
- ✅ Conditional login fields
- ✅ OAuth auto-attempt logic
- ❌ Settings migration UI not implemented
- ❌ OAuth token info display not implemented

### ❌ Phase 7: Testing & Polish (NOT STARTED)
- ❌ Manual testing checklist
- ❌ Integration tests
- ❌ Performance testing
- ❌ Code review

### ❌ Phase 8: Migration & Documentation (NOT STARTED)
- ❌ Migration flow for existing users
- ❌ Release notes
- ❌ Documentation

---

## 🐛 Known Issues & TODOs

### Critical Issues

1. **API Calls Don't Use OAuth Token Properly**
   - Problem: When using OAuth, API calls may not be sending the Bearer token correctly
   - The `TokenProvider.getToken()` checks auth method and returns OAuth access token
   - But need to verify API calls actually use it in Authorization header
   - Check if API.swift properly uses `await tokenProvider.getToken()` for all authenticated requests

2. **Endpoint Parameter Flow Needs Verification**
   - `GetServerInfoUseCase.execute(endpoint:)` receives endpoint parameter
   - `ServerInfoRepository.getServerInfo(endpoint:)` passes it through
   - `InfoApiClient.getServerInfo(endpoint:)` uses it OR falls back to TokenProvider
   - Need to verify this chain works correctly

### Minor Issues

3. **No Migration UI for Existing Users**
   - Users with API tokens can't migrate to OAuth yet
   - Settings screen needs "Switch to OAuth" button

4. **No OAuth Token Display**
   - Can't see which auth method is active
   - Can't see token expiry or scopes

5. **All `#if` Checks Removed**
   - Removed all `#if os(iOS) && !APP_EXTENSION` conditionals
   - May cause issues with URLShare extension (needs verification)

---

## ✅ Updated TODO List

### 🔴 IMMEDIATE (Critical for functionality)

- [ ] **Verify API Integration with OAuth Token**
  - [ ] Check that `API.swift` uses `await tokenProvider.getToken()` in all authenticated requests
  - [ ] Verify Bearer token is sent correctly in Authorization header
  - [ ] Test actual API call (e.g., fetch bookmarks) with OAuth token
  - [ ] Add logging to confirm which token type is being used

- [ ] **Test Complete OAuth Flow End-to-End**
  - [ ] Fresh install → OAuth server → OAuth login → fetch data
  - [ ] Fresh install → non-OAuth server → classic login → fetch data
  - [ ] OAuth login failure → fallback to classic login
  - [ ] Verify endpoint is saved correctly in TokenProvider

### 🟡 HIGH PRIORITY (Important for UX)

- [ ] **Settings Screen Migration**
  - [ ] Show current authentication method (OAuth vs API Token)
  - [ ] Add "Switch to OAuth" button (if server supports it and user has API token)
  - [ ] Add "Switch to Classic Login" option
  - [ ] Show OAuth token info (scopes, expiry if available)

- [ ] **Error Handling & Messages**
  - [ ] Better error messages for OAuth failures
  - [ ] Network error handling
  - [ ] Token expiry handling
  - [ ] Server not reachable scenarios

### 🟢 MEDIUM PRIORITY (Nice to have)

- [ ] **Testing**
  - [ ] Manual testing on real device
  - [ ] Integration tests for OAuth flow
  - [ ] Test on different iOS versions
  - [ ] Test with different server versions

- [ ] **Documentation**
  - [ ] Update README with OAuth instructions
  - [ ] Add inline code documentation
  - [ ] Create user guide for OAuth setup

### ⚪ LOW PRIORITY (Future enhancements)

- [ ] Token refresh support (if server implements it)
- [ ] Revoke token on logout
- [ ] Multiple account support
- [ ] Biometric re-authentication

---

## 📚 Implementation Notes

### Design Decisions

1. **No Login Method Selection Screen**
   - Original plan had LoginMethodSelectionView
   - Removed in favor of automatic OAuth attempt
   - Rationale: Better UX, fewer clicks, OAuth is preferred
   - Fallback to classic login happens automatically on error

2. **Endpoint in TokenProvider**
   - Endpoint now saved in BOTH TokenProvider (Keychain) and Settings
   - Rationale: InfoApiClient needs endpoint from TokenProvider for /api/info calls
   - Ensures endpoint is available for all API calls

3. **Removed All `#if os(iOS) && !APP_EXTENSION`**
   - Original code had many conditional compilation checks
   - All removed for cleaner code
   - May need to revisit if URLShare extension has issues

4. **ServerInfoDto Structure Changed**
   - Original plan had flat version string
   - Actual API returns nested VersionInfo object
   - Adapted to match real API response

### Code Patterns

**Endpoint Resolution:**
```swift
// InfoApiClient
func getServerInfo(endpoint: String? = nil) async throws -> ServerInfoDto {
    let baseEndpoint = try await resolveEndpoint(endpoint)
    // Uses provided endpoint OR falls back to tokenProvider.getEndpoint()
}
```

**Token Type Detection:**
```swift
// KeychainTokenProvider
func getToken() async -> String? {
    if let method = await getAuthMethod(), method == .oauth {
        return await getOAuthToken()?.accessToken
    }
    return keychainHelper.loadToken() // API token
}
```

**OAuth Flow:**
```swift
// 5-phase flow in OAuthFlowCoordinator
1. Register client + generate PKCE
2. Build authorization URL
3. Open browser (ASWebAuthenticationSession)
4. Parse callback URL
5. Exchange code for token
```

---

## 🎯 Next Steps

### For Next Development Session

1. **Verify API Integration** (Most Critical)
   - Add logging to see which token is being used
   - Test actual API call with OAuth token
   - Confirm Bearer token in Authorization header

2. **Manual Testing**
   - Test OAuth flow end-to-end
   - Test fallback to classic login
   - Test on real device

3. **Settings Screen**
   - Show current auth method
   - Add migration button

4. **Error Handling**
   - Better error messages
   - Handle all failure scenarios

---

**Last Updated:** December 19, 2025
**Status:** Phase 1-4 Complete, Phase 5-6 Mostly Complete, Testing Needed
