import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/main_app_screen.dart'; // HomeScreen
import 'screens/ride_request_screen.dart'; // Book a Ride Screen
import 'screens/bottom_navbar.dart'; // BottomNavBar widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseApp app;

    if (Firebase.apps.isEmpty) {
      app = await Firebase.initializeApp(
        name: 'CustomApp', // Initialize a new Firebase app with a custom name
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      app = Firebase.app('CustomApp');
    }

    runApp(MyApp());
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false; // Track login state

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: _isLoggedIn ? '/' : '/login', // Decide initial route
      routes: {
        '/': (context) => LandingScreen(), // Landing Page (Unauthenticated)
        '/login': (context) => LoginScreen(), // Login Page
        '/signup': (context) => SignUpScreen(), // Sign Up Page
      },
      onGenerateRoute: (settings) {
        // Handle routes dynamically
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MainAppScreen(userType: args['userType']),
          );
        }
        return null;
      },
    );
  }

  // Handle successful login and navigate to home screen
  void _handleLoginSuccess(String userType) {
    setState(() {
      _isLoggedIn = true;
    });
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'userType': userType},
    );
  }
}
