// Quick script to fix negative shorts count in Firebase
// Run this with: dart fix_shorts_count.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔧 Fixing shorts count...');
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Get your user ID (replace with your actual user ID)
  // You can find this in Firebase Console → Authentication → Users
  final userId = 'YOUR_USER_ID_HERE';
  
  // Fix the count
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
    'uploadedShortsCount': 0,  // Reset to 0
    'uploadedVideosCount': FieldValue.increment(0),  // Ensure it exists
  });
  
  print('✅ Shorts count reset to 0!');
  print('Now you can upload new shorts and the count will be correct.');
}

