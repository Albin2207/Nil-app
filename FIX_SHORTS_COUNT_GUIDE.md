# 🔧 Fix Your -2 Shorts Count (2 Minutes!)

## ✅ **Quick Fix via Firebase Console:**

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/

### Step 2: Select Your Project
Click on: **nilstream**

### Step 3: Go to Firestore Database
- In the left sidebar, click: **Firestore Database**
- Click: **Data** tab

### Step 4: Find Your User
1. Click on the `users` collection
2. Find your user document (it will have your email)
3. Click on it to open

### Step 5: Fix the Count
1. Find the field: `uploadedShortsCount` 
2. Current value: `-2`
3. Click the **Edit** icon (pencil) next to it
4. Change value to: `0`
5. Click **Save** ✅

### Step 6: Done!
- The count is now fixed!
- Upload a new short → count will show `1`
- Delete it → count will stay at `0` (not go negative)

---

## 🎯 **Alternative: Delete & Let It Auto-Create**

Instead of editing:
1. **Delete** the `uploadedShortsCount` field entirely
2. Next time you upload a short, it will auto-create with value `1`

---

## ✨ **What We Fixed in the Code:**

The app now prevents negative counts by checking before decrementing:

```dart
// Only decrement if count > 0
if (currentCount > 0) {
  uploadedShortsCount: -1
}
```

So this won't happen again! 🎉

---

## 📸 **Visual Guide:**

```
Firebase Console
└── nilstream (project)
    └── Firestore Database
        └── users (collection)
            └── [your-user-id] (document)
                ├── email: "your@email.com"
                ├── name: "Your Name"
                ├── uploadedVideosCount: 0
                └── uploadedShortsCount: -2  ← Fix this to 0
```

**That's it! Takes less than 2 minutes!** 🚀

