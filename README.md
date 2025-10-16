# # NilStream - YouTube-Style Video Streaming App

A modern video streaming app built with Flutter that provides a YouTube-like experience for your users.

## ✨ Features

- 🎥 **Professional Video Player** - Powered by Chewie with fullscreen support, seek controls, and smooth playback
- 👍👎 **Like/Dislike System** - Real-time updates with user preference persistence
- 💬 **Comments Section** - Post and view comments in real-time
- 📱 **Responsive UI** - Beautiful, modern interface inspired by YouTube
- 🔄 **Related Videos** - Automatic recommendations below each video
- 📤 **Share Functionality** - Share videos with friends
- 🔔 **Subscribe Feature** - Subscribe to channels
- 📊 **View Tracking** - Automatic view count increment
- 🎨 **Material Design** - Clean, modern UI with smooth animations

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Firebase project set up
- Cloudinary account for video hosting

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd nil_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Firebase is already configured in the app

4. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions and feature overview
- **[FIREBASE_DATA_STRUCTURE.md](FIREBASE_DATA_STRUCTURE.md)** - Firestore database schema
- **[CLOUDINARY_GUIDE.md](CLOUDINARY_GUIDE.md)** - How to upload videos to Cloudinary
- **[SAMPLE_VIDEO_DATA.json](SAMPLE_VIDEO_DATA.json)** - Sample data templates

## 🎯 Key Technologies

- **Flutter** - Cross-platform mobile framework
- **Firebase Firestore** - Real-time NoSQL database
- **Cloudinary** - Video hosting and CDN
- **Chewie** - Advanced video player
- **Provider** - State management
- **SharedPreferences** - Local data persistence

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management
├── screens/
│   ├── home_screen.dart      # Main feed
│   ├── video_playing_screen.dart  # Video player & details
│   └── ...
└── widgets/                  # Reusable components
```

## 🔥 Firebase Collections

### videos (Collection)
```
videos/{videoId}
├── title: String
├── description: String
├── videoUrl: String
├── thumbnailUrl: String
├── channelName: String
├── channelAvatar: String
├── duration: Number
├── views: Number
├── likes: Number
├── dislikes: Number
├── subscribers: Number
└── timestamp: Timestamp
```

### comments (Subcollection)
```
videos/{videoId}/comments/{commentId}
├── text: String
├── username: String
├── userAvatar: String
├── timestamp: Timestamp
└── likes: Number
```

## 🎬 Adding Videos

### Method 1: Manual (Firebase Console)
1. Upload video to Cloudinary
2. Go to Firebase Console > Firestore
3. Add document to `videos` collection
4. Fill in all required fields (see FIREBASE_DATA_STRUCTURE.md)

### Method 2: Quick Test
Use the sample URLs from `SAMPLE_VIDEO_DATA.json` for testing

## 🛠️ Customization

### Change App Name
Edit `lib/screens/home_screen.dart` line 33

### Change Colors
Replace `Colors.red` throughout the app with your brand color

### Add Authentication
See SETUP_GUIDE.md for instructions on adding Firebase Auth

## 📸 Screenshots

(Add your app screenshots here)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Support

If you encounter any issues:
1. Check the [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. Verify your Firebase configuration
3. Ensure Cloudinary URLs are accessible
4. Check Flutter console for errors

## 🎉 What's Next?

- [ ] Add user authentication
- [ ] Implement video upload from app
- [ ] Create admin panel
- [ ] Add search functionality
- [ ] Implement playlists
- [ ] Add video quality selection
- [ ] Enable offline downloads
- [ ] Push notifications for new videos

## 👨‍💻 Author

Your Name - [@yourhandle](https://twitter.com/yourhandle)

---

**Built with ❤️ using Flutter**
