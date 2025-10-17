import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
        
        // Reload user to get updated profile
        await user.reload();
        
        // Get the refreshed user
        final refreshedUser = _auth.currentUser;
        
        // Create user document in Firestore
        await _createUserDocument(refreshedUser ?? user, name);
        
        return refreshedUser ?? user;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign up';
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update last login
        await _updateLastLogin(user.uid);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign in';
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user != null) {
        // Check if user document exists, create if not
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _createUserDocument(user, user.displayName ?? 'User');
        } else {
          await _updateLastLogin(user.uid);
        }
      }

      return user;
    } catch (e) {
      throw 'Failed to sign in with Google: ${e.toString()}';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out';
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data';
    }
  }

  // Get user data stream
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        
        // Also update Firebase Auth profile
        final user = _auth.currentUser;
        if (user != null) {
          if (name != null) await user.updateDisplayName(name);
          if (photoUrl != null) await user.updatePhotoURL(photoUrl);
          
          // Reload to apply changes
          await user.reload();
        }
      }
    } catch (e) {
      throw 'Failed to update profile';
    }
  }

  // Private: Create user document in Firestore
  Future<void> _createUserDocument(User user, String name) async {
    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
  }

  // Private: Update last login
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': Timestamp.now(),
    });
  }

  // Private: Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}

