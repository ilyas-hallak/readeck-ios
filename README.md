<div align="center">

<img src="readeck/Assets.xcassets/AppIcon.appiconset/512.png" width="128" alt="Readeck for iOS app icon" />

# Readeck for iOS

**Your read-it-later library, native on iPhone and iPad.**

A client for [Readeck](https://readeck.org), the self-hosted bookmark manager.
Save articles from anywhere, read them distraction free, and take them offline.

[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D5866?style=for-the-badge&logo=appstore&logoColor=white)](https://apps.apple.com/app/readeck/id6748764703)
[![Join the TestFlight beta](https://img.shields.io/badge/TestFlight-Join%20the%20beta-4AB7D6?style=for-the-badge&logo=apple&logoColor=white)](https://testflight.apple.com/join/cV55mKsR)

[![App Store version](https://img.shields.io/itunes/v/6748764703?label=App%20Store&color=4AB7D6)](https://apps.apple.com/app/readeck/id6748764703)
[![Platform](https://img.shields.io/badge/iPhone%20%7C%20iPad-iOS%2018.1%2B-000000?logo=apple&logoColor=white)](#getting-started)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white)](#getting-started)
[![Readeck](https://img.shields.io/badge/Readeck-self--hosted-0D5866)](https://readeck.org)
[![MIT License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

<br />

<img src="screenshots/iphone_1.png" width="160" alt="See all your bookmarks" />
<img src="screenshots/iphone_3.png" width="160" alt="Read articles and track your progress" />
<img src="screenshots/iphone_4.png" width="160" alt="Save from any app with the share extension" />
<img src="screenshots/iphone_5.png" width="160" alt="Personalize the app" />
<img src="screenshots/iphone_6.png" width="160" alt="Sync and read offline" />

</div>

## Why Readeck for iOS

- **Made for reading.** A clean reader with your font, size, margins and color theme, and progress that follows you.
- **Save from anywhere.** The share extension adds a page from Safari or any other app in two taps.
- **Works offline.** Articles are cached on the device, so the train or the plane is no problem.
- **Your server, your data.** The app only talks to your own Readeck server, no tracking, no third party account.

## Features

**Reading**
- Classic and modern reader, with progress as a line, a ring around the Dynamic Island or a percent pill
- Fonts, text size, margins, line height, 7 color themes and custom CSS
- Highlights and annotations, tap a highlight to remove it, shake to undo
- Export any article as PDF, share a public Readeck link or have your server send it by email
- Choose what happens after archiving: stay, open the next article or go back to the list

**Library**
- All, Unread, Favorites, Archive, Articles, Videos and Pictures
- Search, labels and swipe actions, fast even with thousands of labels
- Optional unread count on the app icon
- Full iPad support with a multi column split view

**Sync and offline**
- Offline reading with cached images, saved articles open instantly
- Bookmarks saved while the server is unreachable sync once it is back
- OAuth login, VPN and private network support (for example Tailscale), self-signed certificates
- Custom HTTP headers for setups behind an auth proxy

Available in English, German and Swedish.
See the [release notes](readeck/UI/Resources/RELEASE_NOTES.md) for what landed in each version.

<details>
<summary><b>iPad screenshots</b></summary>

<br />

<img src="screenshots/ipad_1.jpg" width="400" alt="iPad Screenshot 1" />
<img src="screenshots/ipad_2.jpg" width="400" alt="iPad Screenshot 2" />
<img src="screenshots/ipad_3.jpg" width="400" alt="iPad Screenshot 3" />
<img src="screenshots/ipad_4.jpg" width="400" alt="iPad Screenshot 4" />

</details>

## Getting started

1. Install the app from the [App Store](https://apps.apple.com/app/readeck/id6748764703), or join the [TestFlight beta](https://testflight.apple.com/join/cV55mKsR) for early access to new features
2. Enter the URL of your Readeck server and sign in
3. Your bookmarks load right away

To save a page, share it from Safari or any other app and pick Readeck in the share sheet.

<details>
<summary><b>Server setup notes</b></summary>

<br />

Local network and VPN addresses (for example Tailscale) also work over plain HTTP and with self-signed certificates.
For a public domain, your Readeck server needs HTTPS, since iOS does not allow plain HTTP there.

Custom HTTP headers are sent with every API request, which helps when Readeck runs behind a proxy like Pangolin.
`Content-Type` and `Authorization` are managed by the app and cannot be overridden.

</details>

## Feedback and contributing

Bugs, crashes and ideas are welcome through TestFlight, as an issue, or by email at hi@ilyashallak.de.
Pull requests too, see [Contribute.md](Contribute.md) for how to get started.

The Readeck server itself lives on [Codeberg](https://codeberg.org/readeck/readeck).

## License

MIT, see [LICENSE](LICENSE).

Made by [Ilyas Hallak](https://ilyashallak.de).
More about the app on [ilyashallak.de/readeck](https://ilyashallak.de/readeck/).
