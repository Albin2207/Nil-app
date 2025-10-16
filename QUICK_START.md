# ⚡ Quick Start Guide - Get Running in 5 Minutes!

## 1️⃣ Install Packages (30 seconds)

```bash
flutter pub get
```

## 2️⃣ Add a Test Video to Firebase (2 minutes)

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: **nilstream**
3. Click **Firestore Database** from the left menu
4. Click on **videos** collection (create if doesn't exist)
5. Click **"Add document"**
6. Use **Auto-ID** for Document ID
7. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| title | string | "Test Video - Big Buck Bunny" |
| description | string | "This is a test video for the app" |
| videoUrl | string | https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4 |
| thumbnailUrl | string | https://picsum.photos/480/270 |
| channelName | string | "Test Channel" |
| channelAvatar | string | https://i.pravatar.cc/150?img=5 |
| duration | **number** | 596 |
| views | **number** | 0 |
| likes | **number** | 0 |
| dislikes | **number** | 0 |
| subscribers | **number** | 1000 |
| timestamp | timestamp | Click the clock icon ⏰ |

8. Click **Save**

## 3️⃣ Run the App (1 minute)

```bash
flutter run
```

## 4️⃣ Test Features (1 minute)

✅ **Home Screen**: See your video listed  
✅ **Click Video**: Video should play automatically  
✅ **Like Button**: Click to like (turns red)  
✅ **Comment**: Type and send a comment  
✅ **Share**: Click share to test share functionality  
✅ **Subscribe**: Click subscribe button  

## 🎉 That's It!

Your YouTube-style app is now running!

---

## 🔧 Troubleshooting

### Video Not Playing?
- Check your internet connection
- Try the test URL from above (it's a free public video)
- Open the video URL in a browser to verify it works

### Nothing Showing on Home Screen?
- Verify you added the video to Firebase
- Check that the collection name is exactly "videos" (lowercase)
- Make sure duration, views, likes, dislikes are **Number** type, not String

### Like/Comment Not Working?
- Make sure Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Check Firebase Console for permission errors

---

## 📱 Next Steps

1. **Add Your Own Video**:
   - Upload to Cloudinary (see CLOUDINARY_GUIDE.md)
   - Add to Firebase with your video URL

2. **Add More Videos**:
   - Repeat the process to add 3-5 videos
   - Test the "Related Videos" section

3. **Customize**:
   - Change app name in home_screen.dart
   - Update colors to match your brand
   - Add your own channel information

---

## 🚀 For Production

Before launching:
- [ ] Add Firebase Authentication
- [ ] Update Firestore security rules
- [ ] Replace test URLs with real videos
- [ ] Add error handling
- [ ] Test on real devices
- [ ] Set up analytics

---

**Need more help?** Check out:
- 📖 [SETUP_GUIDE.md](SETUP_GUIDE.md) - Full documentation
- 🎥 [CLOUDINARY_GUIDE.md](CLOUDINARY_GUIDE.md) - Video hosting
- 📊 [FIREBASE_DATA_STRUCTURE.md](FIREBASE_DATA_STRUCTURE.md) - Database schema

