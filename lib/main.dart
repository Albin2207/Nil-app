import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nil_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/firebase_messaging_background.dart';
import 'core/services/fcm_token_service.dart';
import 'core/services/notification_topics_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/movies_provider.dart';
import 'presentation/providers/shorts_provider_new.dart';
import 'presentation/providers/video_provider.dart';
import 'presentation/providers/comment_provider.dart';
import 'presentation/providers/tmdb_provider.dart';
import 'presentation/providers/upload_provider.dart';
import 'presentation/providers/download_provider.dart';
import 'presentation/providers/playlist_provider.dart';
import 'presentation/providers/subscription_provider.dart';
import 'core/services/connectivity_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/video_playing_screen.dart';
import 'data/models/downloaded_video.dart';
import 'data/models/playlist_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set up FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // FCM initialization removed for faster startup
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Handle deep links when app is launched from a link
  _handleInitialDeepLink();
  

  Hive.registerAdapter(DownloadedVideoAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  
  // Note: Run 'flutter packages pub run build_runner build' to generate adapters

  runApp(
    MultiProvider(
      providers: [
        // Connectivity Service
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        
        // Auth Provider 
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Content Providers
        ChangeNotifierProvider(create: (_) => ShortsProviderNew()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => TmdbProvider()),
        
        // Upload & Download Providers
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // Always start with splash screen which handles routing
      home: const SplashScreen(),
      // Handle deep links
      onGenerateRoute: (settings) {
        // Handle nilstream:// links (direct app links)
        if (settings.name?.startsWith('nilstream://video/') == true) {
          final videoId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => _DeepLinkVideoScreen(videoId: videoId),
          );
        }
        // Handle Netlify redirect links (https://nilapp-links.netlify.app/video?id=xxx)
        if (settings.name?.contains('nilapp-links.netlify.app') == true || 
            settings.name?.startsWith('https://nilapp-links.netlify.app') == true) {
          final uri = Uri.parse(settings.name!);
          final videoId = uri.queryParameters['id'];
          if (videoId != null && videoId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => _DeepLinkVideoScreen(videoId: videoId),
            );
          }
        }
        return null;
      },
      // This ensures the app responds to auth state changes globally
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Just return the child, splash screen handles navigation
            return child ?? const SplashScreen();
          },
        );
      },
    );
  }
}

// Deep link video screen that loads video by ID
class _DeepLinkVideoScreen extends StatelessWidget {
  final String videoId;

  const _DeepLinkVideoScreen({required this.videoId});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home screen instead of going back to splash
        Navigator.of(context).pushReplacementNamed('/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('videos')
              .doc(videoId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                  ),
                  title: const Text('Video Not Found'),
                ),
                body: const Center(
                  child: Text(
                    'Video not found or has been removed.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            return VideoPlayerScreen(video: snapshot.data!);
          },
        ),
      ),
    );
  }
}

// Handle initial deep link when app is launched from a link
void _handleInitialDeepLink() {
  // This will be handled by the platform-specific code
  // For now, we rely on the onGenerateRoute in MaterialApp
}
