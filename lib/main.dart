import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/loginPage.dart';
import '../pages/profilePage.dart';
import '../pages/homePage.dart';
import '../pages/successPay.dart';
import '../pages/failPay.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links3/uni_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // Listen to deep links using uni_links3
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'myapp' && uri.host == 'payment-result') {
        final status = uri.queryParameters['status'];
        if (status == 'success') {
          Navigator.pushNamed(context, '/successPay');
        } else if (status == 'fail') {
          Navigator.pushNamed(context, '/failPay');
        }
      }
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF303030),
      ),
      home: HomePage(), // Your existing HomePage design remains unchanged
      routes: {
        '/successPay': (context) => SuccessPay(),
        '/failPay': (context) => FailPay(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return ProfilePage(user: user); // Redirect to ProfilePage with the user object
    } else {
      return LoginPage(); // Redirect to LoginPage if not logged in
    }
  }
}
