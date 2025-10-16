# 🎬 TMDB API Setup Guide

## 🎯 What's New - Netflix-Style Movies Section!

Your app now has:
- ✅ **TMDB API Integration** - Real movies and TV shows from The Movie Database
- ✅ **Netflix-Style UI** - Beautiful card layouts with posters and ratings
- ✅ **Movie Details Screen** - Full movie information
- ✅ **YouTube Trailers** - Watch trailers directly in the app
- ✅ **Multiple Categories**: Trending, Popular, Now Playing, Upcoming, Top Rated
- ✅ **Cast Information** - See actors and their roles
- ✅ **Cached Images** - Fast loading with image caching

---

## 🔑 Step 1: Get Your TMDB API Key (5 minutes - FREE!)

### 1. Create TMDB Account
1. Go to: https://www.themoviedb.org/
2. Click "Join TMDB" in the top right
3. Sign up with your email (it's FREE!)
4. Verify your email

### 2. Request API Key
1. Log in to TMDB
2. Click on your profile (top right)
3. Go to **Settings**
4. Click **API** in the left sidebar
5. Click **Create** or **Request an API Key**
6. Select **Developer**
7. Accept the terms
8. Fill in the form:
   - **Application Name**: NilStream App
   - **Application URL**: http://localhost (for now)
   - **Application Summary**: A video streaming mobile app
9. Submit the form
10. Copy your **API Key (v3 auth)**

### 3. Add API Key to Your App
1. Open `lib/core/constants/tmdb_config.dart`
2. Find line 3: `static const String apiKey = 'YOUR_TMDB_API_KEY_HERE';`
3. Replace `YOUR_TMDB_API_KEY_HERE` with your actual API key
4. Save the file

**Example:**
```dart
static const String apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

---

## 🚀 Step 2: Run the App

```bash
flutter pub get
flutter run
```

---

## 🎨 Features

### Movies Screen:
- **Featured Banner**: Large backdrop with movie info
- **Trending Now**: Big cards with ratings
- **Popular Movies**: Horizontal scrollable list
- **Now Playing**: Movies currently in theaters
- **Top Rated**: Highest rated movies
- **Coming Soon**: Upcoming releases
- **Popular TV Shows**: Top TV series

### Movie Details Screen:
- **Full backdrop image**
- **Movie title, year, rating, runtime**
- **Genres as chips**
- **Play Trailer button** (YouTube player)
- **Overview/Synopsis**
- **Cast with photos**
- **Smooth scroll animations**

### YouTube Trailer Player:
- **Full YouTube player** embedded
- **Play/pause, seek controls**
- **Quality selection**
- **Fullscreen support**
- **Captions available**

---

## 📚 How It Works

### Data Flow:
```
1. App starts
   → TmdbProvider loads movies from TMDB API
   
2. Movies Screen displays:
   → Featured banner (trending movie)
   → Multiple sections from different API endpoints
   
3. User clicks movie card
   → Navigate to Movie Details Screen
   → Load full movie details (with trailer info)
   
4. User clicks "Play Trailer"
   → YouTube player opens
   → Trailer plays automatically
```

### API Endpoints Used:
- `/trending/movie/week` - Trending movies
- `/movie/popular` - Popular movies
- `/movie/top_rated` - Top rated
- `/movie/now_playing` - In theaters
- `/movie/upcoming` - Coming soon
- `/tv/popular` - Popular TV shows
- `/movie/{id}?append_to_response=videos,credits` - Full details

---

## 🎯 File Structure

```
lib/
├── core/constants/
│   └── tmdb_config.dart              # API keys & endpoints
├── data/
│   ├── models/
│   │   └── movie_tmdb_model.dart     # Movie, MovieDetails, Cast, Video
│   └── repositories/
│       └── tmdb_repository.dart      # API calls
├── presentation/
│   ├── providers/
│   │   └── tmdb_provider.dart        # State management
│   └── screens/
│       ├── movies_screen.dart        # Netflix-style UI
│       └── movie_details_screen.dart # Details with trailer
```

---

## 🎨 UI Customization

### Change Colors:
Edit `lib/core/constants/app_constants.dart`:
```dart
static const Color primaryColor = Colors.red; // Change to your brand color
```

### Modify Sections:
Edit `lib/presentation/screens/movies_screen.dart`:
- Add/remove sections in the `ListView`
- Change section titles
- Modify card sizes

### Customize Details Screen:
Edit `lib/presentation/screens/movie_details_screen.dart`:
- Change layout
- Add more information
- Modify YouTube player appearance

---

## 🐛 Troubleshooting

### No Movies Showing?
1. **Check API Key**: Make sure you added it correctly in `tmdb_config.dart`
2. **Check Internet**: TMDB API requires internet connection
3. **Check Console**: Look for error messages
4. **Verify API Key**: Test it in browser: 
   ```
   https://api.themoviedb.org/3/movie/popular?api_key=YOUR_API_KEY
   ```

### Trailer Not Playing?
1. **Check Internet**: YouTube requires connection
2. **Verify Trailer Exists**: Not all movies have trailers
3. **Check YouTube Key**: Some trailers may be region-locked

### Images Not Loading?
1. **Internet Connection**: Required for images
2. **TMDB Images**: Sometimes TMDB doesn't have images for all movies
3. **Cached Images**: Clear app data and retry

---

## 💡 Pro Tips

### 1. **Rate Limiting**
TMDB free tier has rate limits:
- 40 requests per 10 seconds
- Don't spam the API
- The app caches results in Provider

### 2. **Image Optimization**
The app uses `cached_network_image`:
- Images are cached automatically
- Faster subsequent loads
- Saves bandwidth

### 3. **Search Feature**
To add search:
```dart
final results = await context.read<TmdbProvider>().searchMovies('Inception');
```

### 4. **More Endpoints**
TMDB has many more endpoints:
- Similar movies
- Movie recommendations
- Discover by genre
- Person details
- And much more!

Check: https://developers.themoviedb.org/3

---

## 📊 Example Movie Data

```json
{
  "id": 550,
  "title": "Fight Club",
  "overview": "A ticking-time-bomb insomniac...",
  "poster_path": "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
  "backdrop_path": "/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg",
  "vote_average": 8.4,
  "release_date": "1999-10-15",
  "runtime": 139,
  "genres": [
    {"id": 18, "name": "Drama"}
  ],
  "videos": {
    "results": [
      {
        "key": "SUXWAEX2jlg",
        "site": "YouTube",
        "type": "Trailer"
      }
    ]
  }
}
```

---

## 🎉 What You Get

### Real Movie Data:
- ✅ 20,000+ movies
- ✅ TV shows
- ✅ High-quality posters
- ✅ Backdrop images
- ✅ Cast & crew info
- ✅ Ratings & reviews
- ✅ Official trailers

### Netflix-Style UI:
- ✅ Featured banner
- ✅ Horizontal scrolling sections
- ✅ Beautiful card layouts
- ✅ Smooth animations
- ✅ Professional design

### YouTube Integration:
- ✅ Official trailers
- ✅ Full player controls
- ✅ HD quality
- ✅ Captions support

---

## 🔐 Security Note

**Important**: Your TMDB API key is currently in the code. For production:
1. Move API key to environment variables
2. Use a backend proxy
3. Don't commit API keys to Git
4. Add `.env` to `.gitignore`

---

## 📱 Testing

1. **Run the app**
2. **Navigate to Movies tab** (bottom nav)
3. **See featured banner** at top
4. **Scroll through sections**
5. **Click any movie card**
6. **See movie details**
7. **Click "Play Trailer"**
8. **Watch trailer!**

---

## 🚀 Next Steps

### Immediate:
- [ ] Get TMDB API key
- [ ] Add to `tmdb_config.dart`
- [ ] Test the movies screen

### Future Features:
- [ ] Add search functionality
- [ ] Implement favorites/watchlist
- [ ] Add movie recommendations
- [ ] Filter by genre
- [ ] Sort options
- [ ] User ratings

---

## 📞 Support

### TMDB Resources:
- **API Docs**: https://developers.themoviedb.org/3
- **Forum**: https://www.themoviedb.org/talk
- **API Status**: https://status.themoviedb.org/

### Common Issues:
- **401 Unauthorized**: Invalid API key
- **404 Not Found**: Wrong endpoint or movie ID
- **429 Too Many Requests**: Rate limit exceeded

---

**Enjoy your Netflix-style movie app! 🎬✨**

