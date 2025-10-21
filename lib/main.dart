import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nil_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'presentation/screens/splash_screen.dart';
import 'data/models/downloaded_video.dart';
import 'data/models/playlist_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Hive
  await Hive.initFlutter();
  

  Hive.registerAdapter(DownloadedVideoAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  
  // Note: Run 'flutter packages pub run build_runner build' to generate adapters

  runApp(
    MultiProvider(
      providers: [
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
    );
  }
}
