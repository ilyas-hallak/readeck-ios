# Release Notes

Thanks for using the Readeck iOS app! Below are the release notes for each version.

**AppStore:** The App is now in the App Store! [Get it here](https://apps.apple.com/de/app/readeck/id6748764703) for all TestFlight users. If you wish a more stable Version, please download it from there. Or you can continue using TestFlight for the latest features.

## Version 2.0.0

### Offline Reading

- **Read your articles without internet connection** - the feature you've been waiting for!
- Automatic background sync keeps your favorite articles cached
- Choose how many articles to cache (up to 200)
- Cache syncs automatically every 4 hours
- Manual sync button for instant updates
- Smart FIFO cleanup automatically removes old cached articles
- Article images are pre-downloaded for offline viewing
- Cached articles load instantly, even without network

### Smart Network Monitoring

- **Automatic offline detection** with reliable network monitoring
- Visual indicator shows when you're offline
- App automatically loads cached articles when offline
- Cache-first loading for instant article access
- Improved VPN handling without false-positives
- Network status checks interface availability for accuracy

### Offline Settings

- **New dedicated offline settings screen**
- Enable or disable offline mode
- Adjust number of cached articles with slider
- View last sync timestamp
- Manual sync button
- Toggle settings work instantly

### Performance & Architecture

- Clean architecture with dedicated cache repository layer
- Efficient CoreData integration for cached content
- Kingfisher image prefetching for smooth offline experience
- Background sync doesn't block app startup
- Reactive updates with Combine framework

### Developer Features (DEBUG)

- Offline mode simulation toggle for testing
- Detailed sync logging for troubleshooting
- Visual debug banner (green=online, red=offline)

---

## Version 1.2.0

### Annotations & Highlighting

- **Highlight important passages** directly in your articles
- Select text to bring up a beautiful color picker overlay
- Choose from four distinct colors: yellow, green, blue, and red
- Your highlights are saved and synced across devices
- Tap on annotations in the list to jump directly to that passage in the article
- Glass morphism design for a modern, elegant look

### Performance Improvements

- **Dramatically faster label loading** - especially with 1000+ labels
- Labels now load instantly, even without internet connection
- Share Extension loads much faster
- Better performance when working with many labels
- Improved overall app stability

### Settings Redesign

- **Completely redesigned settings screen** with native iOS style
- Font settings moved to dedicated screen with larger preview
- Reorganized sections for better overview
- Inline explanations directly under settings
- Cleaner app info footer with muted styling
- Combined legal, privacy and support into one section

### Tag Management Improvements

- **Handles 1000+ tags smoothly** - no more lag or slowdowns
- **Tags now load from local database** - no internet required
- Choose your preferred tag sorting: by usage count or alphabetically
- Tags sync automatically in the background
- Share Extension shows your 150 most-used tags instantly
- Better offline support for managing tags
- Faster and more responsive tag selection

### Fixes & Improvements

- Better color consistency throughout the app
- Improved text selection in articles
- Better formatted release notes
- Various bug fixes and stability improvements

---

## Version 1.1.0

There is a lot of feature reqeusts and improvements in this release which are based on your feedback. Thank you so much for that! If you like the new features, please consider leaving a review on the App Store to support further development.

### Modern Reading Experience (iOS 26+)

- **Completely rebuilt article view** for the latest iOS version
- Smoother scrolling and faster page loading
- Better battery life and memory usage
- Native iOS integration for the best experience

### Quick Actions

- **Smart action buttons** appear automatically when you're almost done reading
- Beautiful, modern design that blends with your content
- Quickly favorite or archive articles without scrolling back up
- Buttons fade away elegantly when you scroll back
- Your progress bar now reflects the entire article length

### Beautiful Article Images

- **Article header images now display properly** without awkward cropping
- Full images with a subtle blurred background
- Tap to view images in full screen

### Smoother Performance

- **Dramatically improved scrolling** - no more stuttering or lag
- Faster article loading times
- Better handling of long articles with many images
- Overall snappier app experience

### Open Links Your Way

- **Choose your preferred browser** for opening links
- Open in Safari or in-app browser
- Thanks to christian-putzke for this contribution!

### Fixes & Improvements

- Articles no longer overflow the screen width
- Fixed spacing issues in article view
- Improved progress calculation accuracy
- Better handling of article content
- Fixed issues with label names containing spaces

---

## Version 1.0 (Initial Release)

### Core Features

- Browse and read saved articles
- Bookmark management with labels
- Full article view with custom fonts
- Text-to-speech support (Beta)
- Archive and favorite functionality
- Choose different Layouts (Compact, Magazine, Natural)

### Reading Experience

- Clean, distraction-free reading interface
- Customizable font settings
- Header Image viewer with zoom support
- Progress tracking per article
- Dark mode support

### Organization

- Label system for categorization (multi-select)
- Search
- Archive completed articles
- Jump to last read position

### Share Extension

- Save articles from other apps
- Quick access to save and label bookmarks
- Save Bookmarks offline if your server is not reachable and sync later


