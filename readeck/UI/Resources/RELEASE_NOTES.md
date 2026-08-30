# Release Notes

Thanks for using the Readeck iOS app! Below are the release notes for each version.

**AppStore:** The App is now in the App Store! [Get it here](https://apps.apple.com/de/app/readeck/id6748764703) for all TestFlight users. If you wish a more stable Version, please download it from there. Or you can continue using TestFlight for the latest features.

## Version 3.1.0

This release is mostly about making what's already there work reliably. There are new features below, but the bulk of the work went into offline sync, reader performance, and error handling.

### Reader

- **New OLED theme** rendering true black instead of the system's dark gray, for OLED displays. Settings → Appearance → Theme
- **Reader color themes now cover the entire reader.** Sepia, Night Blue, Mint and the Solarized themes color the navigation bar and the safe areas too, so the article no longer sits in a gray frame
- **Archive from the reader menu**, without scrolling to the end of the article to reach the floating button
- **Delete from the reader menu**, so you can remove the current article without going back to the list
- **Long articles render noticeably faster.** The article used to be rebuilt from scratch on every view update
- Rubber-band scrolling is gone, which makes it easier to select text near the top and bottom edges
- Highlight labels now use the theme's text color and stay readable on dark backgrounds

### Favorites

- **Favorite status is now visible in the list**, as a heart on the bookmark image in all three card layouts
- The swipe menu's heart shows whether an article *is* a favorite, instead of only offering the action
- **Favorites stay in your Unread list.** Marking an article as a favorite used to remove it from Unread; it now behaves like the web app

### Share Extension

- **New "Open after save" toggle.** Turn it on before saving and the app opens the article right after it's stored
- It's off by default and deliberately not remembered, so saving a link and moving on stays the fast path
- The reader waits for the server to finish preparing a freshly saved article instead of showing a blank page

### Unread Count Badge

- **Optional app-icon badge** showing your number of unread articles
- Mirrors the Unread tab and refreshes when you open the app or archive/delete an article
- Turn it on in Settings → Reading Settings ("Show Unread Count on App Icon"); off by default

### "After Archiving" Options

- **Choose what happens when you archive or delete the article you're reading:** stay on it, open the next one in your list, or return to the list
- New picker in Settings → Reading Settings

### Reading Aloud

- **Queueing a new article while one has just finished now plays the new article.** The finished one used to stay at the front of the queue and get replayed instead
- The mini player's close button now actually stops playback, rather than hiding the player while the voice kept reading

### Swedish

- **The app is now available in Swedish**, alongside English and German
- Completed the German onboarding texts, which were falling back to English

### Hall of Fame

- New **Settings → Hall of Fame** screen crediting the Readeck project founder, the app maintainer, and everyone who has contributed
- Tap a person to open their GitHub or Codeberg profile

### Bug Fixes

- The reader's horizontal margin no longer collapses to 0 and pushes the text against the screen edge
- The reader font size is kept when you reopen the settings sheet
- The archive button in the reader stays in sync when you un-archive an article
- Server error messages are shown instead of failing silently
- The bookmark type filter (Articles/Videos/Pictures) is preserved when the list reloads
- Server URLs typed with smart punctuation (curly dashes, invisible characters) are cleaned up instead of failing with a format error
- More robust OAuth login, with clearer retries and a guard against double taps
- More defensive handling of the server info/version response, for older Readeck servers

### Stability & Performance

- **Offline sync no longer stops at the first failure.** Each item is retried on its own with a backoff, and items that fail stay queued for the next run
- **The image cache now honors its size limit** across app launches, instead of only when you moved the slider
- Large articles recover automatically from gateway errors (502/503/504 and Cloudflare 52x)
- Hardened Core Data threading, which removes a class of rare crashes and data races
- Errors in the storage layer are no longer swallowed, so problems surface instead of looking like missing data
- Network requests have proper timeouts
- Considerably more test coverage across the app, the repositories, and the share extension

## Version 3.0.0

### Granular Reader Styling

**Full control over your reading experience**
- Numeric font size slider (10-30px) for precise text sizing
- Adjustable horizontal margins (0-40px)
- Line height control (1.0-2.5) for comfortable line density
- Toggle to hide progress bar, word count/reading time, or hero image

**Color Themes**
- 7 built-in color themes: System, Sepia, Night Blue, Mint, Solarized Light, Solarized Dark, Gray
- Custom color picker for background and text color
- Colors apply to both the article content and the native UI (title, metadata)

**Metadata Cleanup**
- Compact author format without "Author:" prefix
- Author and date combined on one line
- Source URL moved to a safari icon next to the title

**Power User**
- Custom CSS injection for full styling control
- All reader settings accessible from both the article view and app settings

### Disable Back Swipe in Reader

- **New setting to disable the edge swipe back gesture** in the article reader
- Makes it easier to select and highlight text near the screen edges
- Toggle in Settings → Reading Settings
- Adds a dedicated back button in the navigation bar when enabled

---

## Version 2.1.0

### Bug Fixes & Improvements

- **Fix: Annotations now display correctly** when reopening articles (thanks @sibson)
- **New: Reset reading progress** via context menu (thanks @astratto)
- Improved error handling and stability fixes

---

## Version 2.0.0

### 📖 Offline Reading - The Feature You've Been Waiting For!

**Read your articles without internet connection**
- enable offline reading in settings, the default is off
- Automatic background sync keeps your unread articles cached and ready
- Cache syncs automatically every 4 hours when you open the app
- Manual sync button for instant updates anytime
- Article images are pre-downloaded for offline viewing (optional)
- Smart cleanup removes old cached articles automatically

**Smart offline experience**
- Visual offline banner shows when network is unavailable
- App automatically loads cached articles when offline
- Cache-first loading for instant article access and better performance
- Choose how many articles to cache (5-100 articles)
- Note: When using a VPN, the app will show as online even if you are in Flight Mode

**Offline settings & management**
- New dedicated offline settings screen
- Enable or disable offline mode with toggle
- View cache size and last sync timestamp
- **Preview cached articles**: see which articles are available offline
- Clear cache with one tap
- Monitor cache usage in settings

### Extended Font Selection

**10 new beautiful fonts for better reading**
- New serif fonts: Literata, Merriweather, Source Serif
- New sans-serif fonts: Lato, Montserrat, Source Sans
- Apple system fonts: SF Pro, New York, Charter
- All fonts are open-source (OFL 1.1 licensed)
- Improved font rendering in article reader
- Font changes take effect immediately

### Annotations & Highlighting Improvements

- **Localized highlight button** - now appears in your device language
- Improved annotation creation through API integration
- Better error handling for annotation sync

### Open Source Licenses

- **New licenses view** in settings
- View all open-source fonts and their licenses
- Direct links to license files
- Full transparency about used libraries

### Modern Login with OAuth 2.0

**Easier and more secure login**
- Login through your browser instead of username and password
- More secure authentication method
- Works automatically if your server supports it
- Seamless fallback to classic login for older servers
- No configuration needed - the app detects the best login method

### Improved Setup Experience

**Better onboarding and sharing**
- Smoother onboarding flow when setting up the app
- Share Extension shows helpful messages when you're not logged in
- Clearer error messages if your session has expired
- Prevents sync issues during initial setup

### ⚡️ Performance & Improvements

- **VPN & Private Network support** - Connect to your Readeck server via VPN (like Tailscale) or private networks. Supports HTTP connections and self-signed certificates for home/private server setups
- Various stability improvements


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


