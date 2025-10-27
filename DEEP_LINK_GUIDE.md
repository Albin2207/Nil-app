# Deep Link Setup - Complete Guide 🎯

## ✅ What's Been Set Up

### 1. Netlify Redirect Site
- **URL**: https://nilapp-links.netlify.app/
- **Location**: `nilapp_links/` folder
- **Function**: Beautiful redirect page that opens your app

### 2. Flutter App Integration
- Video sharing now uses Netlify URLs
- App handles both direct (`nilstream://`) and web (`https://`) deep links

## 🔄 How It Works

### User Flow:
1. **User shares video** → Gets `https://nilapp-links.netlify.app/video?id=abc123`
2. **Recipient taps link** → Opens Netlify page (beautiful loading screen)
3. **Netlify page detects** → Tries to open `nilstream://video/abc123` (your app)
4. **If app installed** → Opens your app directly to the video
5. **If app not installed** → Shows download buttons

## 📱 Testing

### Test on Android (via ADB):
```bash
# Test direct app link
adb shell am start -W -a android.intent.action.VIEW -d "nilstream://video/TEST_VIDEO_ID"

# Test Netlify redirect link
adb shell am start -W -a android.intent.action.VIEW -d "https://nilapp-links.netlify.app/video?id=TEST_VIDEO_ID"
```

### Test on iOS (Xcode Simulator):
1. Open Safari in Simulator
2. Type: `nilstream://video/TEST_VIDEO_ID` or `https://nilapp-links.netlify.app/video?id=TEST_VIDEO_ID`
3. Press Enter

### Test Sharing Flow:
1. Open your app
2. Share any video
3. You'll see: `Check out this video on NIL: [Title] https://nilapp-links.netlify.app/video?id=xxx`
4. Copy the link
5. Paste in browser → Netlify page opens → Tries to open your app

## 🎨 Features

### Netlify Page Features:
- ✅ Beautiful gradient design
- ✅ Loading spinner animation
- ✅ Auto-detects if app opens
- ✅ Fallback to download buttons if app not found
- ✅ 2-second timeout before showing fallback
- ✅ Mobile-responsive

### App Features:
- ✅ Handles both link formats seamlessly
- ✅ Extracts video ID correctly
- ✅ Shows video player on deep link
- ✅ Works in portrait and landscape

## 🔧 Customization Options

### To change Netlify URL:
1. Update `lib/presentation/widgets/video_player/action_buttons_widget.dart` (line 470)
2. Update `lib/presentation/screens/home_screen.dart` (line 797)

### To add custom domain:
1. In Netlify Dashboard → Domain Settings
2. Add custom domain (e.g., `nilapp.com`)
3. Update DNS as instructed
4. Update Flutter code to use new domain

### To customize Netlify page design:
Edit `nilapp_links/index.html` - CSS is in the `<style>` tag

## 🚀 What's Next?

1. **Test thoroughly** on both Android and iOS
2. **Update download links** in `index.html` (lines 106-107) with actual Play Store/App Store URLs
3. **Optional**: Connect custom domain for cleaner URLs
4. **Optional**: Add analytics to track deep link usage

## 📝 Notes

- The Netlify page works as a "bridge" between web links and your app
- Messaging apps (WhatsApp, Telegram, etc.) will show the link as clickable
- Works perfectly on free Netlify plan
- No backend needed - it's all client-side!

---

**Ready to Test!** 🎉

Test URL: https://nilapp-links.netlify.app/video?id=TEST_VIDEO_ID
