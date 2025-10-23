# NIL App

A modern video-sharing platform built with Flutter, featuring full-length videos, short-form content, and comprehensive social engagement features.

## Features

### 🎥 Video Platform
- **Regular Videos**: Upload and watch full-length videos with detailed metadata
- **Shorts**: TikTok-style short-form vertical videos with swipe navigation
- **Video Player**: Custom video player with play/pause, seek, quality selection, and fullscreen
- **Downloads**: Offline viewing with quality options (360p, 480p, 720p, 1080p)
- **Playlists**: Create and manage custom playlists

### 💬 Social Features
- **YouTube-Style Comments**: Nested replies with expand/collapse functionality
- **Engagement**: Like, dislike, share, and comment on videos
- **User Profiles**: View channel statistics and content
- **Subscriptions**: Subscribe to creators and track your subscriptions

### 🛡️ Content Management
- **Moderation Panel**: Creators can review and manage reported comments
- **Content Reporting**: Users can report inappropriate comments
- **Comment Actions**: Edit, delete, pin comments (with permissions)

### 👤 User Features
- **Authentication**: Google Sign-In and email/password authentication
- **Profile Management**: Edit profile, change password, manage account
- **Channel Statistics**: Videos, shorts, views, likes, comments, shares tracking
- **Settings**: Privacy policy, feedback system, account settings

### 📱 App Features
- **Modern UI**: Clean, intuitive interface with smooth animations
- **Dark Theme**: Eye-friendly dark mode
- **Offline Support**: Download videos for offline viewing
- **Search**: Find videos, shorts, and creators
- **Share**: Share content via social media platforms

## Tech Stack

- **Framework**: Flutter 3.27.3
- **Language**: Dart 3.6.0
- **Backend**: Firebase
  - Authentication (Google Sign-In, Email/Password)
  - Cloud Firestore (Database)
  - Firebase Storage (Video/Image storage)
- **State Management**: Provider
- **Video Player**: video_player package
- **HTTP Client**: dio
- **Local Storage**: sqflite, shared_preferences

## Project Structure

```
lib/
├── core/                       # Core utilities and services
│   ├── constants/              # App-wide constants
│   ├── di/                     # Dependency injection
│   ├── navigation/             # Navigation/routing
│   ├── services/               # App services
│   ├── theme/                  # Theme configuration
│   └── utils/                  # Helper utilities
├── data/                       # Data layer
│   ├── models/                 # Data models
│   ├── repositories/           # Data repositories
│   └── services/               # Firebase services
├── presentation/               # UI layer
│   ├── providers/              # State management
│   ├── screens/                # App screens
│   └── widgets/                # Reusable widgets
└── main.dart                   # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.27.3 or higher)
- Dart SDK (3.6.0 or higher)
- Firebase project configured
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nil_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download and place configuration files:
     - Android: `google-services.json` → `android/app/`
     - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Run FlutterFire CLI to generate `firebase_options.dart`:
     ```bash
     flutterfire configure
     ```

4. **Android Signing** (for release builds)
   - Create `android/key.properties` with your keystore details:
     ```
     storePassword=<your-password>
     keyPassword=<your-password>
     keyAlias=<your-alias>
     storeFile=<path-to-keystore>
     ```
   - Place your keystore file in `android/app/`

5. **Run the app**
   ```bash
   # Development
   flutter run

   # Release build
   flutter build apk --release
   flutter build appbundle --release
   ```

## Firebase Collections

- **users**: User profiles and settings
- **videos**: Full-length video metadata
- **shorts**: Short-form video metadata
- **comments**: Comments and nested replies
- **reports**: Content moderation reports
- **playlists**: User-created playlists

## Firestore Security Rules

Deploy the security rules:
```bash
firebase deploy --only firestore:rules
```

Deploy indexes:
```bash
firebase deploy --only firestore:indexes
```

## Building for Production

### Android (AAB for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Android (APK)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```

## Version Information

- **Current Version**: 1.1.0 (Build 4)
- **Min SDK**: Android 21 (Lollipop)
- **Target SDK**: Android 34

## Dependencies

Key packages:
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- `provider` - State management
- `video_player` - Video playback
- `image_picker` - Image/video selection
- `dio` - HTTP client
- `sqflite` - Local database
- `share_plus` - Share functionality
- `url_launcher` - Open external URLs
- `cached_network_image` - Image caching

See `pubspec.yaml` for complete list.

## Contributing

1. Follow the existing code structure
2. Use Provider for state management
3. Keep widgets small and reusable
4. Add comments for complex logic
5. Test on both Android and iOS

## Support

For issues or questions:
- Email: nilapp01@gmail.com
- Use the in-app Feedback feature

## License

All rights reserved. Proprietary software.

---

Built with ❤️ using Flutter
