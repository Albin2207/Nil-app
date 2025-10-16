# 🔧 TMDB API Troubleshooting

## ❌ Error: "Connection reset by peer"

This error means the TMDB API connection failed. Here are the solutions:

### ✅ Solution 1: Wait for API Key Activation (Most Common)

**TMDB API keys take 5-10 minutes to activate after creation!**

1. Just created your API key? → **Wait 10 minutes**
2. Hot reload the app or click "Retry"
3. It should work after activation

### ✅ Solution 2: Check Your Internet Connection

1. Make sure your device has internet
2. Try opening a website in browser
3. Check if you're on WiFi or mobile data
4. Try switching networks

### ✅ Solution 3: Verify API Key

Test your API key in a browser:
```
https://api.themoviedb.org/3/movie/popular?api_key=21d548f63198d5d5c735a3130e13e454
```

**Should return JSON with movies**. If you get an error:
- API key is wrong
- API key not activated yet
- Need to request a new one

### ✅ Solution 4: Restart App

```bash
# Hot restart (in terminal where app is running)
R

# Or completely restart
flutter run
```

### ✅ Solution 5: Check Firewall/VPN

- Disable VPN if you're using one
- Check if firewall is blocking TMDB
- Some networks block API calls

---

## 🎯 Quick Test

**Test API in Browser First:**

Go to this URL in your phone/computer browser:
```
https://api.themoviedb.org/3/movie/popular?api_key=21d548f63198d5d5c735a3130e13e454
```

**If you see JSON data** → API key works!  
**If you see error** → API key issue

---

## ⏰ Common Causes

| Issue | Solution | Time |
|-------|----------|------|
| **API key just created** | Wait 10 minutes | 10 min |
| **No internet** | Connect to WiFi | 1 min |
| **Wrong API key** | Get new one from TMDB | 2 min |
| **Firewall/VPN** | Disable temporarily | 1 min |
| **App cache** | Hot restart (R) | 10 sec |

---

## 🔍 Debug Steps

### Step 1: Test API Key in Browser
Copy this URL to browser:
```
https://api.themoviedb.org/3/movie/popular?api_key=YOUR_KEY_HERE
```

Replace `YOUR_KEY_HERE` with your actual key.

**Expected**: You should see JSON like:
```json
{
  "results": [
    {
      "id": 123,
      "title": "Some Movie",
      ...
    }
  ]
}
```

### Step 2: Check API Key Format
Your key should be **32 characters** of letters and numbers.

**Your key**: `21d548f63198d5d5c735a3130e13e454` ✅ (32 chars)

### Step 3: Wait and Retry
If key is brand new:
1. Wait 5-10 minutes
2. Open app
3. Go to Movies tab
4. Click "Retry" button

---

## 🎉 When It Works

You'll see:
- Featured movie banner at top
- Multiple movie sections
- Real movie posters
- Ratings and info
- Click any movie → Details screen
- Click "Play Trailer" → YouTube player

---

## 💡 Alternative: Test with Sample Data First

While waiting for API activation, you can test with mock data. Let me know if you want that!

---

## 📞 Still Not Working?

1. **Get a new API key** from TMDB
2. **Wait 15 minutes** after getting it
3. **Test in browser first**
4. **Then test in app**

**Most likely**: Just need to wait for API key activation! ⏰

