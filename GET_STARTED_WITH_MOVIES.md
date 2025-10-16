# ⚡ Quick Start - Netflix-Style Movies (2 Minutes!)

## 🎬 What You Have Now

✅ **Netflix-Style Movies UI**
✅ **Real movie data from TMDB API**
✅ **Movie details with trailers**
✅ **YouTube player for trailers**
✅ **Cast information**
✅ **Multiple categories**

---

## 🔑 Step 1: Get TMDB API Key (2 minutes - FREE!)

### Quick Steps:
1. **Go to**: https://www.themoviedb.org/signup
2. **Sign up** (free!)
3. **Verify email**
4. **Go to**: https://www.themoviedb.org/settings/api
5. **Click "Create" or "Request an API Key"**
6. **Select "Developer"**
7. **Fill in**:
   - App Name: `NilStream`
   - App URL: `http://localhost`
   - Description: `Video streaming app`
8. **Submit**
9. **Copy your API Key (v3 auth)**

---

## 📝 Step 2: Add API Key (30 seconds)

1. **Open file**: `lib/core/constants/tmdb_config.dart`
2. **Line 3**: Replace `YOUR_TMDB_API_KEY_HERE` with your key
3. **Save**

**Example:**
```dart
static const String apiKey = 'abc123def456ghi789'; // Your actual key
```

---

## 🚀 Step 3: Run & Test

```bash
flutter run
```

### Test Features:
1. ✅ Open app
2. ✅ Navigate to **Movies** tab (bottom nav - 3rd icon)
3. ✅ See **Featured Movie** banner at top
4. ✅ Scroll through sections
5. ✅ Click any movie card
6. ✅ Click "Play Trailer"
7. ✅ Watch trailer!

---

## 🎯 What Each Section Shows

| Section | What It Shows |
|---------|---------------|
| **Featured Banner** | #1 Trending movie with backdrop |
| **Trending Now** | Popular this week |
| **Popular Movies** | Most popular overall |
| **Now Playing** | Currently in theaters |
| **Top Rated** | Highest rated all-time |
| **Coming Soon** | Upcoming releases |
| **Popular TV Shows** | Top TV series |

---

## 🎨 Netflix-Style Features

### Home Banner:
- Full-width backdrop image
- Movie title, rating, year
- Overview text
- "Watch Trailer" button
- "More Info" button

### Movie Cards:
- High-quality posters
- Star ratings
- Smooth loading
- Cached images
- Professional layout

### Details Screen:
- Cinematic backdrop
- Full movie information
- Embedded YouTube trailer
- Cast carousel
- Similar movies (ready to add)

---

## 🔧 Customization

### Change Number of Movies Shown:
Edit providers - they load 20 by default (TMDB standard)

### Add More Sections:
In `movies_screen.dart`, add more `_buildSection()` calls

### Modify Card Sizes:
Change `height` and `width` in `_buildMovieCard()`

---

## ⚠️ Important Notes

### API Key Security:
- Don't commit API key to Git
- For production, use environment variables
- Keep key private

### Rate Limits:
- Free tier: 40 requests / 10 seconds
- App caches data in Provider
- Don't spam the API

### Internet Required:
- TMDB API needs internet
- Show error message if offline
- Cache images for faster loading

---

## 🎉 You're All Set!

**All you need**: TMDB API key (free, 2 minutes to get)

**Then**: Enjoy Netflix-style movies with real data!

---

## 📞 Need Help?

### Getting API Key:
- TMDB Support: https://www.themoviedb.org/talk/category/5047958519c29526b50017d6

### API Issues:
- Read: `TMDB_SETUP_GUIDE.md` for detailed help
- Check: https://developers.themoviedb.org/3

### App Issues:
- Make sure API key is correct
- Check internet connection
- Look at Flutter console for errors

---

**Ready? Get your API key and run the app! 🎬🚀**

