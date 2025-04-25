import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';  // Import for kIsWeb
import '/screens/login_screen.dart';
import '/screens/home_screen.dart';
import '/screens/register_screen.dart';
import '/screens/advice_screen.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");

    // Handle platform-specific configurations
    if (kIsWeb) {
      print("Running on Web. Using Remote Config.");
      // Set up Remote Config for web
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'openai_api_key': ''});
      await remoteConfig.fetchAndActivate();
    } else {
      print("Running on Mobile. Loading .env file.");
      // Load .env file for mobile platforms
      await dotenv.load(fileName: ".env");
      String? openAiKey = dotenv.env['OPENAI_API_KEY'];
      print('Dotenv Loaded: OPENAI_API_KEY is ${openAiKey != null ? "set" : "null"}');
    }
    

    // Run the app once Firebase is initialized
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print("Error during initialization: $e");
    print("Stack trace: $stackTrace");
    runApp(const MyAppWithError());
  }
}

// Error screen to show if Firebase initialization fails
class MyAppWithError extends StatelessWidget {
  const MyAppWithError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Error initializing Firebase. Please try again later.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get OpenAI API Key based on the platform (web vs non-web)
    String? openAiKey = kIsWeb ? FirebaseRemoteConfig.instance.getString('openai_api_key') : dotenv.env['OPENAI_API_KEY'];
    print('OPENAI_API_KEY in MaterialApp: $openAiKey');

    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEFF2FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8C0FF),
          primary: const Color(0xFFB8C0FF),
          secondary: const Color(0xFFB8E0FF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB8E0FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            textStyle: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/advice': (context) => const AdviceScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( 
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error message if there's an error with the authentication stream
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error loading user state")),
          );
        }

        // Navigate to HomeScreen if user is authenticated, else to LoginScreen
        return snapshot.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}