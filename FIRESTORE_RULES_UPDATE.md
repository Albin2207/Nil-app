# 🔥 Firestore Rules - Quick Fix for Auth Issues

## ⚠️ Issue: Permission Denied Errors

After implementing authentication, the old videos/shorts (created without auth) are now blocked by the new security rules.

---

## ✅ **Quick Fix - Update Rules Manually**

### **Go to Firebase Console:**
1. Open: https://console.firebase.google.com/project/nilstream/firestore/rules
2. Click **"Edit rules"**
3. Replace ALL rules with this:

```javascript
rules_version='2'

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Anyone can read user profiles
      allow read: if true;
      // Only authenticated users can create their own profile
      allow create: if request.auth != null && request.auth.uid == userId;
      // Only the user can update/delete their own profile
      allow update, delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Videos collection
    match /videos/{videoId} {
      // Anyone can read videos
      allow read: if true;
      // Only authenticated users can create videos
      allow create: if request.auth != null;
      // Allow update for anyone (for likes, views, etc.)
      allow update: if true;
      // Only the video owner can delete (if uploadedBy field exists)
      allow delete: if request.auth != null && 
        (!resource.data.keys().hasAny(['uploadedBy']) || request.auth.uid == resource.data.uploadedBy);
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if true;
        allow update: if true;
        allow delete: if true;
      }
    }
    
    // Shorts collection
    match /shorts/{shortId} {
      // Anyone can read shorts
      allow read: if true;
      // Only authenticated users can create shorts
      allow create: if request.auth != null;
      // Allow update for anyone (for likes, views, etc.)
      allow update: if true;
      // Only the short owner can delete (if uploadedBy field exists)
      allow delete: if request.auth != null && 
        (!resource.data.keys().hasAny(['uploadedBy']) || request.auth.uid == resource.data.uploadedBy);
      
      // Shorts comments subcollection
      match /comments/{commentId} {
        allow read: if true;
        allow create: if true;
        allow update: if true;
        allow delete: if true;
      }
    }
  }
}
```

4. Click **"Publish"**
5. Hot restart app (press `R` in terminal)

---

## ✅ **What This Fixes:**

- ✅ Allows likes/dislikes on old videos/shorts
- ✅ Allows views to increment
- ✅ Allows comments on old content
- ✅ Allows comment deletion
- ✅ Still requires auth for new video/short creation
- ✅ Protects user profiles

---

**After updating rules, hot restart the app!**

