import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/loginPage.dart';
import '../pages/profilePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF303030), // Background color for the app
      ),
      home: AuthWrapper(), // Use an authentication wrapper
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user != null) {
      return ProfilePage(user: user); // Redirect to ProfilePage with the user object
    } else {
      return LoginPage(); // Redirect to LoginPage if not logged in
    }
  }
}
