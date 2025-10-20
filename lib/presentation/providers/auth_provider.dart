import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  // Initialize - listen to auth state changes
  void _init() {
    _authRepository.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _listenToUserData(user.uid);
      } else {
        _currentUser = null;
        _userDataSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  // Listen to real-time user data changes from Firestore
  void _listenToUserData(String uid) {
    _userDataSubscription?.cancel();
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _currentUser = UserModel.fromFirestore(snapshot);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        // Small delay to ensure Firebase Auth profile is fully updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force refresh the current user to get updated displayName
        await FirebaseAuth.instance.currentUser?.reload();
        _firebaseUser = FirebaseAuth.instance.currentUser;
        
        // Real-time listener will automatically load user data
        // No need to manually load - _listenToUserData is called by _init()
      }

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithGoogle();
      
      if (user != null) {
        // Manually update the firebase user to get the latest data
        _firebaseUser = _authRepository.currentUser;
        // Real-time listener will automatically load user data
      }
      
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _firebaseUser = null;
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (_firebaseUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authRepository.updateUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        photoUrl: photoUrl,
      );

      // Refresh firebase user - real-time listener will update user data
      _firebaseUser = _authRepository.currentUser;
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Onboarding methods
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}

