# Fix Negative Count Issue

## ⚠️ Current Issue:
Your shorts count is showing `-2` because the initial count was 0 (or not set), and when you deleted 2 shorts, it decremented to -2.

## ✅ Solution Applied:
I've updated the delete function to check if the count is greater than 0 before decrementing. This prevents negative numbers in the future.

## 🔧 To Fix Your Current -2 Count:

### Option 1: Using Firebase Console (Recommended)
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: `nilstream`
3. Go to Firestore Database
4. Navigate to: `users` collection → Your user document
5. Find the field: `uploadedShortsCount`
6. Change the value from `-2` to `0`
7. Click Save

### Option 2: Delete and Re-create the Field
1. In Firebase Console → Your user document
2. Delete the `uploadedShortsCount` field entirely
3. Save
4. Upload a new short → count will start fresh at 1

### Option 3: Run This Quick Fix (in Firebase Console, Firestore Rules, run a query)
You can also update it programmatically, but the console method is fastest.

---

## 🎯 What's Fixed for Future:

**Before:**
```dart
// Always decremented, even if count was 0
uploadedShortsCount: -1  // Could go negative!
```

**After:**
```dart
// Only decrements if count > 0
if (currentCount > 0) {
  uploadedShortsCount: -1  // Safe!
}
```

---

## ✨ Now Protected Against:
- ✅ Negative counts
- ✅ Decrementing when count is 0
- ✅ Decrementing when field doesn't exist

---

**After you fix the -2 in Firebase Console, the count will work correctly going forward!**

