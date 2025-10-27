import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message handler: ${message.messageId}');
  debugPrint('📱 Message data: ${message.data}');
  debugPrint('📱 Message notification: ${message.notification?.title}');
  
  // Handle background message processing here
  // This runs when the app is in the background or terminated
}
