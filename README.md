# ReadKeep iOS

A native iOS client for [readeck](https://readeck.org) bookmark management.

## Features

- Browse and manage bookmarks (Unread, Favorites, Archive)
- Share Extension for adding URLs from Safari and other apps
- Swipe actions for quick bookmark management
- Native iOS design with Dark Mode support
- Offline sync with Core Data

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone http://192.168.188.150:3000/admin/ReadKeep.git
cd ReadKeep
```

2. Open `readeck.xcodeproj` in Xcode

3. Build and run

4. Configure your readeck server in the app's Settings tab

## Configuration

After installing the app:

1. Open the readeck app
2. Go to the **Settings** tab
3. Enter your readeck server URL and credentials
4. The app will automatically sync your bookmarks

## Architecture

- **SwiftUI** for UI
- **Core Data** for local storage
- **MVVM** architecture pattern
- **Repository pattern** for data access

## Share Extension

The app includes a Share Extension that allows adding bookmarks directly from Safari:

1. Share any webpage in Safari
2. Select "readeck" from the share sheet
3. The bookmark is automatically added to your collection

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Planned Features
- [ ] Add support for tags
- [ ] Add support for bookmark filtering and sorting options
- [ ] Implement search functionality
- [ ] Add support for collection management
- [ ] Add support for multiple readeck servers
- [ ] Add offline sync capabilities
- [ ] Add support for custom themes
- [ ] Implement push notifications for new bookmarks
- [ ] Support for iPad multitasking
- [ ] Implement a dark mode toggle in settings
- [ ] Implement a tutorial for first-time users
