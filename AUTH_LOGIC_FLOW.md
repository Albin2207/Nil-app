# 🔐 Authentication & Onboarding Logic Flow

## 📋 Key Logic Requirements

---

## **1. ONBOARDING LOGIC** 🎯

### **How it Works:**

**Using SharedPreferences to track first-time users:**

```dart
// Check if user has seen onboarding
Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
}

// Mark onboarding as completed
Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
}
```

### **Flow:**

```
App Launch → Splash Screen
       ↓
Check hasCompletedOnboarding()
       ↓
┌──────┴──────┐
│             │
false        true
│             │
↓             ↓
Show         Skip Onboarding
Onboarding   (go to next check)
│
↓
User completes onboarding
↓
Save: onboarding_completed = true
↓
Never show again!
```

### **Result:**
- ✅ Onboarding shows **only once** per device
- ✅ Even if user logs out, onboarding won't show again
- ✅ Only shows again if user clears app data

---

## **2. LOGIN PERSISTENCE LOGIC** 🔐

### **How Firebase Auth Handles It:**

Firebase Auth **automatically persists login state**:
- When user logs in, Firebase stores auth token locally
- Token is encrypted and secure
- Token persists until:
  - User logs out
  - Token expires (handled by Firebase)
  - App data is cleared

### **No Extra Code Needed!**

```dart
// Firebase Auth automatically maintains session
// Just check current user:
User? currentUser = FirebaseAuth.instance.currentUser;

if (currentUser != null) {
  // User is logged in!
} else {
  // User is not logged in
}
```

### **Flow:**

```
User Logs In
    ↓
Firebase Auth creates session
    ↓
Session stored locally (encrypted)
    ↓
User closes app
    ↓
User reopens app
    ↓
Firebase Auth checks session
    ↓
Session valid? ──Yes──→ User is logged in! (go to home)
    │
    No (expired/not found)
    ↓
Show Login Screen
```

---

## **3. APP LAUNCH LOGIC** 🚀

### **Complete Decision Tree:**

```
App Launch
    ↓
Splash Screen (1-2 seconds)
    ↓
Check 1: Has completed onboarding?
    │
    ├──No──→ Show Onboarding → Complete → Mark as done
    │                              ↓
    └──Yes─────────────────────────┘
                                   ↓
Check 2: Is user logged in?
(FirebaseAuth.instance.currentUser != null)
    │
    ├──Yes──→ Navigate to Home Screen ✅
    │
    └──No───→ Navigate to Login Screen
```

### **In Code:**

```dart
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    await Future.delayed(Duration(seconds: 2)); // Splash delay
    
    // Check 1: Onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;
    
    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
      return;
    }
    
    // Check 2: Login state
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is logged in - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else {
      // User not logged in - go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## **4. LOGOUT LOGIC** 🚪

### **What Happens When User Logs Out:**

```dart
Future<void> logout() async {
  await FirebaseAuth.instance.signOut();
  // Firebase automatically clears session
  
  // Navigate to login screen
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
    (route) => false, // Remove all previous routes
  );
}
```

### **Flow:**

```
User taps Logout
    ↓
FirebaseAuth.signOut()
    ↓
Session cleared from device
    ↓
Navigate to Login Screen
    ↓
Remove all previous routes (can't go back)
    ↓
User must login again to access app
```

### **Result:**
- ✅ User is logged out
- ✅ Can't go back to Home with back button
- ✅ Must login again to access app
- ✅ Onboarding **won't show again** (already completed)

---

## **5. SCENARIOS & BEHAVIORS** 📱

### **Scenario 1: First Time User**
```
Open App
  ↓
Onboarding shows (3-4 pages)
  ↓
User completes onboarding
  ↓
onboarding_completed = true (saved)
  ↓
Show Login/Signup Screen
  ↓
User signs up
  ↓
Navigate to Home
```

### **Scenario 2: User Closes App (Without Logout)**
```
User is logged in
  ↓
User closes app (swipe away)
  ↓
[App is killed]
  ↓
User reopens app
  ↓
Splash Screen checks:
  - Onboarding: Already done ✓
  - Login: User still logged in ✓
  ↓
Navigate directly to Home ✅
```

### **Scenario 3: User Logs Out**
```
User is logged in
  ↓
User taps Logout
  ↓
FirebaseAuth.signOut()
  ↓
Navigate to Login Screen
  ↓
User closes app
  ↓
[App is killed]
  ↓
User reopens app
  ↓
Splash Screen checks:
  - Onboarding: Already done ✓
  - Login: NOT logged in ✗
  ↓
Navigate to Login Screen
  ↓
User must login again
```

### **Scenario 4: Returning User**
```
Open App (after days/weeks)
  ↓
Splash Screen checks:
  - Onboarding: Already done ✓
  - Login: Token still valid ✓
  ↓
Navigate directly to Home ✅
```

### **Scenario 5: Token Expired**
```
Open App (after long time, e.g., months)
  ↓
Splash Screen checks:
  - Onboarding: Already done ✓
  - Login: Token expired ✗
  ↓
Firebase Auth: currentUser = null
  ↓
Navigate to Login Screen
  ↓
User must login again
```

---

## **6. STATE MANAGEMENT** 🔄

### **Using Stream for Real-Time Auth State:**

```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  
  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  
  AuthProvider() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // _user will be updated automatically by authStateChanges
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // _user will be set to null automatically by authStateChanges
  }
}
```

### **Benefits:**
- ✅ Auth state updates automatically
- ✅ UI rebuilds when state changes
- ✅ Consistent state across app
- ✅ No manual state management needed

---

## **7. SHARED PREFERENCES USAGE** 💾

### **What We Store Locally:**

```dart
SharedPreferences stores:
  ├── 'onboarding_completed': bool  // First-time check
  ├── 'video_liked_123': bool       // Like state (already using)
  ├── 'short_liked_456': bool       // Like state (already using)
  └── (more as needed)

Firebase Auth stores (automatically):
  ├── User authentication token (encrypted)
  ├── User ID
  └── Session data
```

### **Clear Separation:**
- **SharedPreferences**: App preferences & flags
- **Firebase Auth**: Authentication & session (automatic)
- **Firestore**: User profile data (name, email, etc.)

---

## **8. SECURITY CONSIDERATIONS** 🔒

### **What's Secure:**
- ✅ Firebase Auth token is **encrypted**
- ✅ Token stored **securely** by Firebase SDK
- ✅ Auto-refresh when expired
- ✅ Cleared on logout
- ✅ Can't be accessed by other apps

### **What's NOT Secure:**
- ❌ Don't store passwords in SharedPreferences
- ❌ Don't store auth tokens manually
- ❌ Don't store sensitive user data locally

### **Best Practices:**
- ✅ Let Firebase handle authentication
- ✅ Use Firestore for user data
- ✅ Use SharedPreferences only for app settings
- ✅ Always check auth state on sensitive operations

---

## **9. IMPLEMENTATION SUMMARY** ✅

### **Files Needed:**

1. **`splash_screen.dart`**
   - Check onboarding status
   - Check login status
   - Navigate accordingly

2. **`onboarding_screen.dart`**
   - Show intro pages
   - Mark as completed when done
   - Never show again

3. **`auth_provider.dart`**
   - Listen to auth state changes
   - Provide login/logout methods
   - Update UI automatically

4. **`main.dart`**
   - Set SplashScreen as initial route
   - Provide AuthProvider
   - Handle navigation based on state

### **Logic Flow:**

```dart
main.dart
  ↓
SplashScreen
  ↓
Check hasCompletedOnboarding()
  ├─ No → OnboardingScreen → completeOnboarding() → LoginScreen
  └─ Yes → Check FirebaseAuth.currentUser
              ├─ null → LoginScreen
              └─ User → MainScreen
```

---

## **10. EXAMPLE: MAIN.DART SETUP** 🎯

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NilStream',
      theme: ThemeData.dark(),
      
      // Always start with splash screen
      home: SplashScreen(),
      
      // Don't set initialRoute - let splash screen decide
    );
  }
}
```

---

## **SUMMARY** 📝

### **Key Points:**

1. **Onboarding**
   - ✅ Shows **only once** (SharedPreferences)
   - ✅ Tracks with `onboarding_completed` flag
   - ✅ Never shows again unless app data cleared

2. **Login Persistence**
   - ✅ **Automatic** via Firebase Auth
   - ✅ User stays logged in until they logout
   - ✅ Works across app restarts

3. **Logout**
   - ✅ Clears session
   - ✅ Navigates to login
   - ✅ Removes navigation stack

4. **App Launch**
   - ✅ Check onboarding first
   - ✅ Check login state second
   - ✅ Navigate accordingly

5. **Security**
   - ✅ Firebase handles encryption
   - ✅ Tokens are secure
   - ✅ No manual token storage

---

**This logic ensures a smooth, secure, and intuitive user experience!** 🚀

**Ready to implement with this logic in mind?** 

