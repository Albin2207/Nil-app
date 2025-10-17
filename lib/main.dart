import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nil_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/movies_provider.dart';
import 'presentation/providers/shorts_provider.dart';
import 'presentation/providers/shorts_provider_new.dart';
import 'presentation/providers/video_provider.dart';
import 'presentation/providers/comment_provider.dart';
import 'presentation/providers/tmdb_provider.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ensures async initialization works
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShortProvider()),
        ChangeNotifierProvider(create: (_) => ShortsProviderNew()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => TmdbProvider()),
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
      home: const SplashScreen(),
    );
  }
}
