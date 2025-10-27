# Deep Link Testing Guide

## ✅ **Deep Link Setup Complete!**

### **What's Been Configured:**

1. **App Deep Links**: `nilstream://video/{videoId}`
2. **Android**: Intent filter in AndroidManifest.xml
3. **iOS**: URL scheme in Info.plist
4. **Flutter**: Route handling in main.dart

### **How to Test:**

#### **Method 1: ADB (Android)**
```bash
# Test deep link on Android device/emulator
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "nilstream://video/YOUR_VIDEO_ID" \
  com.example.nil_app
```

#### **Method 2: iOS Simulator**
```bash
# Test deep link on iOS simulator
xcrun simctl openurl booted "nilstream://video/YOUR_VIDEO_ID"
```

#### **Method 3: Share from App**
1. Open any video in the app
2. Tap Share button
3. Copy the link: `nilstream://video/{videoId}`
4. Send to another device
5. Tap the link - should open NIL app

### **Expected Behavior:**
- ✅ Link opens NIL app
- ✅ App navigates directly to video
- ✅ Video loads and plays
- ✅ Shows "Video Not Found" if invalid ID

### **Troubleshooting:**
- **Link doesn't open app**: Check URL scheme configuration
- **App opens but no video**: Check video ID exists in Firestore
- **App crashes**: Check console for errors

### **Next Steps:**
1. Build and install app on device
2. Test sharing a video
3. Test clicking shared link
4. Verify deep link works correctly

## 🚀 **Ready to Test!**
