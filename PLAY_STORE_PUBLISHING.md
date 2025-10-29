# Play Store Publishing Checklist for NIL App

## ✅ What I've Updated

### 1. **AndroidManifest.xml** - Added Required Permissions
- ✅ Internet access
- ✅ Network state
- ✅ Storage permissions (legacy + Android 13+)
- ✅ Camera permission
- ✅ Deep link configurations

### 2. **Version Information** (`pubspec.yaml`)
- ✅ Version: 1.1.0+4
- ✅ Package ID: com.nil.streamapp

### 3. **Build Configuration** (`build.gradle.kts`)
- ✅ Application ID set
- ✅ Signing config ready
- ✅ Minify disabled (can enable later)

## 🔧 Next Steps to Publish

### 1. **Create App Bundle** (AAB)
```bash
flutter build appbundle --release
```
This will create: `build/app/outputs/bundle/release/app-release.aab`

### 2. **Verify Signing**
Check if you have `android/key.properties` with:
```
storePassword=your_password
keyPassword=your_password
keyAlias=upload
storeFile=path/to/your/keystore.jks
```

If you don't have a keystore, create one:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 3. **Create Google Play Console Account**
- Go to https://play.google.com/console
- Pay one-time $25 developer fee
- Create new app

### 4. **Fill App Listing**
- App name: NIL
- Short description
- Full description
- Screenshots (required)
- Icon (already have it in assets)
- Feature graphic
- Privacy policy URL (required!)

### 5. **Required Items**
- [ ] Privacy policy URL (MUST HAVE - create one)
- [ ] Content rating questionnaire
- [ ] App access: All content, most features
- [ ] Target audience (age)
- [ ] Ads (specify if you show ads)
- [ ] Screenshots (at least 2)
- [ ] Feature graphic

### 6. **Release Management**
- Upload the AAB file
- Add release notes
- Submit for review

## ⚠️ Important Notes

1. **Privacy Policy**: You MUST provide a privacy policy URL. Create one on a website explaining:
   - What data you collect
   - How you use it
   - Third-party services (Firebase, Cloudinary)

2. **Content Rating**: Fill out the questionnaire honestly
   - User-generated content? → Yes (videos)
   - Social features? → Yes (comments, likes)
   - Violence? → Depends on content

3. **Testing**: 
   - Test the release build before uploading
   - Use internal testing track first

4. **Deep Links**: Already configured for:
   - Custom scheme: `nilstream://video/ID`
   - HTTP links: `https://nilapp-links.netlify.app/video?id=ID`

## 📝 Checklist Before Publishing

- [ ] Create release keystore
- [ ] Build release AAB
- [ ] Test release build thoroughly
- [ ] Create privacy policy
- [ ] Gather screenshots
- [ ] Fill out content rating
- [ ] Complete store listing
- [ ] Upload AAB
- [ ] Submit for review

## 🎯 Quick Start Commands

```bash
# 1. Build release bundle
flutter build appbundle --release

# 2. Test the bundle
# Download from Play Console or use internal testing

# 3. Check bundle info
bundletool.jar dump manifest --bundle=app-release.aab
```

Good luck with publishing! 🚀

