# CLAUDE.md - readeck iOS Project Documentation

## Project Overview

**readeck iOS** is a native iOS client for [readeck](https://readeck.org) bookmark management. The app provides a clean, native iOS interface for managing bookmarks with features like swipe actions, search, tagging, and reading progress tracking.

### Key Information
- **Platform:** iOS (iPhone + iPad)
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM + Clean Architecture (3-layer: UI/Domain/Data)
- **Database:** CoreData
- **Dependencies:** Swift Package Manager
- **License:** MIT

## Architecture Summary

The project follows Clean Architecture with custom dependency injection:

```
UI Layer (SwiftUI Views + ViewModels)
    ↓
Domain Layer (Use Cases + Repository Protocols + Models)  
    ↓
Data Layer (Repository Implementations + API + CoreData)
```

### Core Components
- **Custom DI:** Protocol-based factory pattern (no external frameworks)
- **MVVM Pattern:** ViewModels handle business logic, Views handle presentation
- **Use Cases:** Single-responsibility business logic encapsulation
- **Repository Pattern:** Data access abstraction with protocols

## Project Structure

```
readeck/
├── UI/                           # SwiftUI Views & ViewModels
│   ├── Bookmarks/               # Main bookmark list
│   ├── BookmarkDetail/          # Article reader
│   ├── AddBookmark/             # Create new bookmarks
│   ├── Search/                  # Search functionality
│   ├── Settings/                # App configuration
│   ├── Labels/                  # Tag management
│   ├── Menu/                    # Navigation & tabs
│   ├── SpeechPlayer/            # Text-to-speech
│   └── Components/              # Reusable UI components
├── Domain/
│   ├── Model/                   # Core business models
│   ├── UseCase/                 # Business logic
│   ├── Protocols/               # Repository interfaces
│   └── Error/                   # Custom error types
├── Data/
│   ├── API/                     # Network layer & DTOs
│   ├── Repository/              # Data access implementations
│   ├── CoreData/                # Local database
│   └── Utils/                   # Helper utilities
└── Localizations/               # i18n strings
    ├── Base.lproj/
    ├── en.lproj/
    └── de.lproj/
```

## Key Features

### Implemented Features
- ✅ Browse bookmarks (All, Unread, Favorites, Archive by type)
- ✅ Share Extension for adding URLs from Safari/other apps
- ✅ Swipe actions for quick bookmark management
- ✅ Native iOS design with Dark Mode support
- ✅ Full iPad Support with Multi-Column Split View
- ✅ Font customization in reader
- ✅ Article view with reading time and word count
- ✅ Search functionality
- ✅ Tag/label management
- ✅ Reading progress tracking
- ✅ Offline support with auto-sync when reconnected
- ✅ Text-to-speech (Read Aloud feature)

### Planned Features (v1.1.0)
- ⏳ Bookmark filtering and sorting options
- ⏳ Collection management
- ⏳ Custom themes
- ⏳ Text highlighting in articles
- ⏳ Multiple selection for bulk actions

## Development Setup

### Requirements
- Xcode 15.0+
- iOS 17.0+ deployment target
- Swift Package Manager (dependencies auto-resolved)

### Key Dependencies
- **netfox:** Network debugging (debug builds only)
- **RswiftLibrary:** Resource management

### Build Configurations
- **Debug:** Includes netfox for network debugging
- **Release:** Production-ready build
- **URLShare Extension:** Share extension target

## Localization (Weblate Integration)

### Current Setup
The project has been converted from Apple's String Catalog (.xcstrings) to traditional .strings format for Weblate compatibility:

```
readeck/Localizations/
├── Base.lproj/Localizable.strings    # Source language (English)
├── en.lproj/Localizable.strings      # English localization
└── de.lproj/Localizable.strings      # German localization
```

### Weblate Configuration
When setting up Weblate:
- **File mask:** `readeck/Localizations/*.lproj/Localizable.strings`
- **Monolingual base:** `readeck/Localizations/Base.lproj/Localizable.strings`  
- **File format:** "iOS Strings (UTF-8)"
- **Repository:** Connect to main Git repository

### Adding New Languages
1. Create new `.lproj` directory (e.g., `fr.lproj/`)
2. Copy `Base.lproj/Localizable.strings` to new directory
3. Weblate will automatically detect and manage translations

## App State Management & Navigation

### Setup Flow & Authentication
The app uses a sophisticated setup and authentication system:

**Initial Setup Detection:**
- `AppViewModel.hasFinishedSetup` controls the main app flow
- `readeckApp.swift:19` determines whether to show setup or main app
- Setup status is persisted via `SettingsRepository.hasFinishedSetup`

**Authentication & Keychain Management:**
- `KeychainHelper` (singleton) securely stores sensitive credentials:
  - Server endpoint (`readeck_endpoint`)
  - Username (`readeck_username`) 
  - Password (`readeck_password`)
  - Authentication token (`readeck_token`)
- Access Group: `8J69P655GN.de.ilyashallak.readeck` for app group sharing
- Automatic logout on 401 responses via `AppViewModel.handleUnauthorizedResponse()`

**Device-Specific Navigation:**
The app automatically adapts its navigation structure based on device type:

```swift
// MainTabView.swift determines layout
if UIDevice.isPhone {
    PhoneTabView()           // Tab-based navigation
} else {
    PadSidebarView()         // Sidebar + split view navigation
}
```

**Navigation Patterns:**
- **iPhone:** `PhoneTabView` - Traditional tab bar with "More" tab for additional features
- **iPad:** `PadSidebarView` - NavigationSplitView with sidebar, content, and detail panes
- Both share the same underlying ViewModels and business logic

**Key Navigation Components:**
- `SidebarTab` enum defines all available sections
- Main tabs: `.all`, `.unread`, `.favorite`, `.archived`
- More tabs: `.search`, `.article`, `.videos`, `.pictures`, `.tags`, `.settings`
- Consistent routing through `tabView(for:)` methods in both variants

## Key Architectural Decisions

### 1. Custom Dependency Injection
- **Why:** Avoid external framework dependencies, full control
- **How:** Protocol-based factory pattern in `DefaultUseCaseFactory`
- **Benefit:** Easy testing with mock implementations

### 2. Repository Pattern
- **Domain Layer:** Defines protocols (e.g., `PBookmarksRepository`)
- **Data Layer:** Implements protocols (e.g., `BookmarksRepository`)
- **Benefit:** Clean separation between business logic and data access

### 3. Use Cases
- Single-responsibility classes for each business operation
- Examples: `CreateBookmarkUseCase`, `GetBookmarksUseCase`
- **Benefit:** Testable, reusable business logic

### 4. SwiftUI + MVVM
- ViewModels as `@ObservableObject` classes
- Views are pure presentation layer
- State management through ViewModels

## Testing Strategy

### Current Test Coverage
- **Unit Tests:** `readeckTests/` (basic coverage)
- **UI Tests:** `readeckUITests/` (smoke tests)

### Testing Philosophy
- Protocol-based DI enables easy mocking
- Use Cases can be tested in isolation
- Repository implementations tested with real/mock data sources

## Distribution

### TestFlight Beta
- Public beta available via TestFlight
- Link: `https://testflight.apple.com/join/cV55mKsR`
- Regular updates with new features

### Release Process
- Uses fastlane for build automation
- Automated screenshot generation
- Version management in Xcode project

## API Integration

### readeck Server API
- RESTful API communication
- DTOs in `Data/API/DTOs/`
- Authentication via username/password
- Token management with automatic refresh
- Support for local network addresses (development)

### Key API Operations
- User authentication
- Bookmark CRUD operations
- Tag/label management
- Article content fetching
- Progress tracking

## Offline Support

### Local Storage
- CoreData for offline bookmark storage
- Automatic sync when connection restored
- Queue system for offline operations
- Conflict resolution strategies

### Sync Strategy
- Background sync when app becomes active
- User-initiated sync option
- Visual indicators for sync status

## Performance Considerations

### Memory Management
- Lazy loading of bookmark content
- Image caching for article thumbnails
- Proper SwiftUI view lifecycle management

### Network Optimization
- Background download of article content
- Request batching where possible
- Retry logic for failed requests

## Contributing Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain separation of concerns between layers

### New Feature Development
1. Define domain models in `Domain/Model/`
2. Create use case in `Domain/UseCase/`
3. Implement repository in `Data/Repository/`
4. Create ViewModel in appropriate UI folder
5. Build SwiftUI view
6. Update factory for DI wiring

### Git Workflow
- Main branch: `main`
- Development branch: `develop`
- Feature branches: `feature/feature-name`
- Commit format: `feat:`, `fix:`, `docs:`, etc.

## Troubleshooting

### Common Issues
1. **Build Errors:** Ensure Xcode 15.0+ and clean build folder
2. **Network Issues:** Check server URL and credentials
3. **CoreData Migrations:** May need to reset data during development
4. **Localization:** Ensure .strings files are properly formatted

### Development Tips
- Use netfox in debug builds to monitor API calls
- Check logging configuration in debug settings
- Test both iPhone and iPad layouts
- Verify share extension functionality

## Security Considerations

### Data Protection
- Keychain storage for user credentials
- No sensitive data in UserDefaults
- Secure network communication (HTTPS enforced for external domains)

### Privacy
- No analytics or tracking libraries
- Local data storage only
- User controls all data sync

---

*This documentation is maintained alongside the codebase. Update this file when making architectural changes or adding new features.*