import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uni_links3/uni_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../pages/loginPage.dart';
import '../pages/profilePage.dart';
import '../pages/homePage.dart';
import '../pages/successPay.dart';
import '../pages/failPay.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  // Register background handler before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _initFCM();
    _listenDeepLinks();
  }

  void _initFCM() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) _saveTokenToDb(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final body = message.notification!.body;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body ?? ''))
        );
      }
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.pushNamed(context, '/notifications'); // route to your notification page
    });
  }

  Future<void> _saveTokenToDb(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token);
    await ref.set({'createdAt': FieldValue.serverTimestamp()});
  }

  void _listenDeepLinks() {
    if (kIsWeb) return;
    _deepLinkSub = uriLinkStream.listen((Uri? uri) {
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
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF303030),
      ),
      home: AuthWrapper(),
      routes: {
        '/successPay': (context) => SuccessPay(),
        '/failPay': (context) => FailPay(),
        // '/notifications': (context) => NotificationsScreen(), // if you have this route
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return ProfilePage(user: snapshot.data!);
        }
        return LoginPage();
      },
    );
  }
}
