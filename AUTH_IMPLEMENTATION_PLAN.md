# 🔐 Authentication & Onboarding Implementation Plan

## 📋 Complete Feature List

---

## **PHASE 1: Setup & Dependencies** ⚙️

### **1.1 Packages to Add**
```yaml
dependencies:
  # Authentication
  firebase_auth: ^6.1.1
  google_sign_in: ^6.2.2
  
  # Onboarding
  smooth_page_indicator: ^1.2.0+3  # For page dots
  
  # Storage (for "remember me" & first-time check)
  shared_preferences: ^2.3.5  # Already added
```

### **1.2 Firebase Console Setup**
- ✅ Enable Email/Password authentication
- ✅ Enable Google Sign-In (Android & iOS setup)
- ✅ Add SHA-1 & SHA-256 fingerprints for Android
- ✅ Download updated `google-services.json`

---

## **PHASE 2: Onboarding Screens** 🎯

### **2.1 Screens to Create**
1. **Splash Screen** (`splash_screen.dart`)
   - App logo animation
   - Check if first time user
   - Check if user is logged in
   - Navigate accordingly

2. **Onboarding Screens** (`onboarding_screen.dart`)
   - 3-4 pages explaining app features
   - Page indicators (dots)
   - Skip button
   - Get Started button on last page
   - Save "onboarding completed" flag

### **2.2 Onboarding Pages Content**
**Page 1: Welcome**
- Title: "Welcome to NilStream"
- Description: "Your ultimate entertainment hub"
- Image/Icon: App logo or video icon

**Page 2: Videos**
- Title: "Watch Unlimited Videos"
- Description: "Discover and watch millions of videos from creators worldwide"
- Image/Icon: Video player illustration

**Page 3: Shorts**
- Title: "Enjoy Short Videos"
- Description: "Swipe through endless short-form content"
- Image/Icon: Shorts illustration

**Page 4: Movies**
- Title: "Stream Movies & TV Shows"
- Description: "Browse and watch your favorite movies and shows"
- Image/Icon: Movie illustration

---

## **PHASE 3: Authentication Screens** 🔐

### **3.1 Login Screen** (`login_screen.dart`)
**UI Elements:**
- App logo/name
- Email TextField
- Password TextField (with show/hide toggle)
- "Forgot Password?" link
- Login Button
- "OR" divider
- Google Sign-In button
- "Don't have an account? Sign Up" link

**Functionality:**
- Email validation
- Password validation
- Login with email/password
- Login with Google
- Error handling (wrong password, user not found, etc.)
- Loading state during login
- Navigate to home on success
- Remember me option (optional)

### **3.2 Signup Screen** (`signup_screen.dart`)
**UI Elements:**
- App logo/name
- Full Name TextField
- Email TextField
- Password TextField (with show/hide toggle)
- Confirm Password TextField
- Terms & Conditions checkbox
- Sign Up Button
- "OR" divider
- Google Sign-In button
- "Already have an account? Login" link

**Functionality:**
- Name validation
- Email validation
- Password strength validation
- Confirm password match
- Create account with email/password
- Sign up with Google
- Create user profile in Firestore
- Error handling (email already in use, weak password, etc.)
- Loading state during signup
- Navigate to home on success

### **3.3 Forgot Password Screen** (`forgot_password_screen.dart`)
**UI Elements:**
- Back button
- Email TextField
- "Send Reset Link" button
- Success message

**Functionality:**
- Send password reset email
- Show success/error messages

---

## **PHASE 4: Data Models** 📦

### **4.1 User Model** (`lib/data/models/user_model.dart`)
```dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int uploadedVideosCount;
  final int uploadedShortsCount;
  final List<String> likedVideos;
  final List<String> likedShorts;
}
```

### **4.2 Firestore User Document Structure**
```
users/
  {userId}/
    ├── uid: "firebase_uid"
    ├── name: "John Doe"
    ├── email: "john@example.com"
    ├── photoUrl: "https://..."
    ├── phoneNumber: "+1234567890"
    ├── createdAt: Timestamp
    ├── lastLogin: Timestamp
    ├── uploadedVideosCount: 0
    ├── uploadedShortsCount: 0
    ├── likedVideos: []
    ├── likedShorts: []
```

---

## **PHASE 5: State Management** 🔄

### **5.1 Auth Provider** (`lib/presentation/providers/auth_provider.dart`)

**State Variables:**
- `UserModel? currentUser`
- `bool isLoading`
- `bool isAuthenticated`
- `String? errorMessage`

**Methods:**
```dart
// Email/Password Auth
Future<void> signUpWithEmail(String email, String password, String name)
Future<void> loginWithEmail(String email, String password)
Future<void> resetPassword(String email)

// Google Auth
Future<void> signInWithGoogle()

// User Management
Future<void> logout()
Future<void> updateUserProfile(String name, String? photoUrl)
Future<UserModel?> getUserData(String uid)
Stream<UserModel?> getUserStream(String uid)

// Utility
bool isFirstTimeUser()
Future<void> markOnboardingComplete()
```

---

## **PHASE 6: Firebase Auth Service** 🔥

### **6.1 Auth Repository** (`lib/data/repositories/auth_repository.dart`)

**Responsibilities:**
- Handle all Firebase Auth operations
- Handle Google Sign-In
- Create/update user documents in Firestore
- Error handling and conversion

**Methods:**
```dart
Future<User?> signUpWithEmailPassword(String email, String password)
Future<User?> signInWithEmailPassword(String email, String password)
Future<void> sendPasswordResetEmail(String email)
Future<User?> signInWithGoogle()
Future<void> signOut()
User? getCurrentUser()
Stream<User?> authStateChanges()
```

---

## **PHASE 7: Navigation & Routing** 🗺️

### **7.1 App Flow**
```
App Launch
    ↓
Splash Screen
    ↓
Check First Time? ──Yes──→ Onboarding ──→ Login/Signup
    │                            ↓
    No                      Get Started
    ↓                            ↓
Check Logged In? ──Yes──→ Main Screen (Home)
    │
    No
    ↓
Login/Signup Screen
    ↓
[Login or Sign Up]
    ↓
Main Screen (Home)
```

### **7.2 Routes to Update**
- `main.dart` - Set initial route based on auth state
- Add splash screen as initial route
- Protect main screen (require auth)

---

## **PHASE 8: UI/UX Enhancements** 🎨

### **8.1 Validation & Error Messages**
**Email Validation:**
- ✅ Not empty
- ✅ Valid email format
- ✅ Show error message inline

**Password Validation:**
- ✅ Not empty
- ✅ Minimum 6 characters
- ✅ Contains uppercase, lowercase, number
- ✅ Show strength indicator

**Name Validation:**
- ✅ Not empty
- ✅ Minimum 3 characters
- ✅ Only letters and spaces

### **8.2 Loading States**
- Show CircularProgressIndicator during auth operations
- Disable buttons during loading
- Show overlay with loading message

### **8.3 Error Handling**
**Common Firebase Auth Errors:**
- `user-not-found` → "No account found with this email"
- `wrong-password` → "Incorrect password"
- `email-already-in-use` → "Email is already registered"
- `weak-password` → "Password should be at least 6 characters"
- `invalid-email` → "Invalid email address"
- `network-request-failed` → "Network error. Check your connection"

### **8.4 Success Messages**
- "Account created successfully!"
- "Logged in successfully!"
- "Password reset email sent!"

---

## **PHASE 9: Security & Best Practices** 🔒

### **9.1 Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Videos - authenticated users can create
    match /videos/{videoId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.uploadedBy;
      
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null && 
          request.auth.uid == resource.data.userId;
      }
    }
    
    // Shorts - authenticated users can create
    match /shorts/{shortId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.uploadedBy;
      
      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null && 
          request.auth.uid == resource.data.userId;
      }
    }
  }
}
```

### **9.2 Password Security**
- Never store passwords locally
- Use Firebase Auth's secure storage
- Implement password strength meter
- Require minimum password strength

### **9.3 Session Management**
- Use Firebase Auth's built-in session management
- Check auth state on app launch
- Auto-logout on token expiration

---

## **PHASE 10: Profile Integration** 👤

### **10.1 Update Profile Screen**
- Show user info (name, email, photo)
- Edit profile button
- Logout button
- My videos section
- My shorts section
- Settings section

### **10.2 Update Video/Short Creation**
- Link uploads to user account
- Add `uploadedBy` field with user ID
- Add uploader's name and avatar

### **10.3 Update Comments**
- Use real user data instead of "Anonymous User"
- Show user's name and avatar
- Allow users to delete only their own comments

---

## **PHASE 11: Google Sign-In Setup** 📱

### **11.1 Android Setup**
1. Get SHA-1 and SHA-256 fingerprints
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. Add to Firebase Console
3. Download updated `google-services.json`
4. Add to `android/app/`

### **11.2 iOS Setup** (if needed)
1. Download `GoogleService-Info.plist`
2. Add to iOS project
3. Update `Info.plist` with URL scheme

---

## 📂 **File Structure**

```
lib/
├── data/
│   ├── models/
│   │   └── user_model.dart                 ✨ NEW
│   └── repositories/
│       └── auth_repository.dart            ✨ NEW
│
├── presentation/
│   ├── providers/
│   │   └── auth_provider.dart              ✨ NEW
│   │
│   ├── screens/
│   │   ├── splash_screen.dart              ✨ NEW
│   │   ├── onboarding_screen.dart          ✨ NEW
│   │   ├── login_screen.dart               ✨ NEW
│   │   ├── signup_screen.dart              ✨ NEW
│   │   ├── forgot_password_screen.dart     ✨ NEW
│   │   └── profile_screen.dart             🔄 UPDATE
│   │
│   └── widgets/
│       └── auth/
│           ├── custom_text_field.dart      ✨ NEW
│           ├── auth_button.dart            ✨ NEW
│           ├── google_sign_in_button.dart  ✨ NEW
│           └── password_strength_meter.dart ✨ NEW
│
└── core/
    └── constants/
        └── auth_constants.dart             ✨ NEW
```

---

## 🎯 **Implementation Order**

### **Step 1: Setup (30 min)**
1. Add packages to `pubspec.yaml`
2. Run `flutter pub get`
3. Enable auth methods in Firebase Console
4. Update Firebase config

### **Step 2: Data Layer (45 min)**
1. Create `UserModel`
2. Create `AuthRepository`
3. Implement Firebase Auth methods

### **Step 3: State Management (30 min)**
1. Create `AuthProvider`
2. Implement auth methods
3. Add to `MultiProvider` in `main.dart`

### **Step 4: Onboarding (1 hour)**
1. Create `SplashScreen`
2. Create `OnboardingScreen` with pages
3. Implement navigation logic

### **Step 5: Auth Screens (2 hours)**
1. Create `LoginScreen`
2. Create `SignupScreen`
3. Create `ForgotPasswordScreen`
4. Create reusable widgets (TextFields, Buttons)

### **Step 6: Integration (1 hour)**
1. Update `main.dart` routing
2. Update Firestore rules
3. Test all flows

### **Step 7: Polish (30 min)**
1. Add loading states
2. Add error handling
3. Add success messages
4. Test edge cases

---

## ⏱️ **Total Estimated Time: 5-6 hours**

---

## ✅ **Success Criteria**

- [ ] User can complete onboarding
- [ ] User can sign up with email/password
- [ ] User can sign up with Google
- [ ] User can login with email/password
- [ ] User can login with Google
- [ ] User can reset password
- [ ] User data is stored in Firestore
- [ ] User stays logged in after app restart
- [ ] User can logout
- [ ] Auth state is managed properly
- [ ] Error messages are user-friendly
- [ ] Loading states are shown
- [ ] UI is polished and intuitive

---

## 🎨 **Design Inspiration**

- **Onboarding**: Instagram, TikTok style
- **Login/Signup**: Modern, minimal, clean
- **Colors**: Match app theme (YouTube red/black)
- **Animations**: Smooth transitions

---

**Ready to implement! Should we start?** 🚀

