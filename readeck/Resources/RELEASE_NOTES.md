# Release Notes

## Version 1.1 (Build 1)

### iOS 26+ Native WebView
- **New native SwiftUI WebView implementation** for iOS 26 and later
- Improved performance with native WebKit integration
- Better memory management and rendering

### Floating Action Buttons
- **Contextual action buttons** appear when reaching 90% of article
- Beautiful glass effect design with liquid interactions
- Smooth slide-up animation
- Quick access to favorite and archive actions

### Reading Progress Improvements
- **Accurate progress tracking** using optimized PreferenceKey approach
- Progress bar reflects entire article length (header, content, metadata)
- Automatic progress sync every 3% to reduce API calls
- Progress locked at 100% to prevent fluctuations

### Image Header Enhancement
- **Better image display** with aspect fit and blurred background
- No more random cropping - full image visibility
- Maintains header space while showing complete images

### Performance Optimizations
- Replaced onScrollGeometryChange with PreferenceKey for smoother scrolling
- Reduced state updates during scroll
- Optimized WebView height detection
- Improved CSS rendering for web content

### Bug Fixes
- Fixed content width overflow in native WebView
- Fixed excessive spacing between header and content
- Fixed read progress calculation to include all content sections
- Fixed JavaScript height detection with simplified approach

---

## Version 1.0 (Initial Release)

### Core Features
- Browse and read saved articles
- Bookmark management with labels
- Full article view with custom fonts
- Text-to-speech support (Beta)
- Archive and favorite functionality

### Reading Experience
- Clean, distraction-free reading interface
- Customizable font settings
- Image viewer with zoom support
- Progress tracking per article
- Dark mode support

### Organization
- Label system for categorization
- Search and filter bookmarks
- Archive completed articles
- Jump to last read position

### Share Extension
- Save articles from other apps
- Quick access to save and label bookmarks
- Save Bookmarks offline if your server is not reachable and sync later


