import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import 'package:app_links/app_links.dart'; // For mobile deep linking
import 'package:flutter/foundation.dart' show kIsWeb; // For platform checking

import '../pages/loginPage.dart';
import '../pages/profilePage.dart';
import '../pages/successPay.dart';
import '../pages/failPay.dart';
import '../pages/notifications.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initFCM();
    if (!kIsWeb) { // Initialize deep links only for mobile
      _initDeepLinks();
    }
  }

  void _initFCM() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, announcement: false, badge: true, carPlay: false,
      criticalAlert: false, provisional: false, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted FCM permission');
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        _saveTokenToDb(token);
      }
      _messaging.onTokenRefresh.listen(_saveTokenToDb);
    } else {
      print('User declined or has not accepted FCM permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!: ${message.messageId}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        final SnackBar snackBar = SnackBar(
          content: Text(message.notification!.body ?? 'New Message!'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _handleNotificationTap(message.data),
          ),
        );
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked from background/terminated!: ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('Initial message received!: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap with data: $data');
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  Future<void> _saveTokenToDb(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('fcmTokens').doc(token)
          .set({'createdAt': FieldValue.serverTimestamp()});
      print('FCM token saved to DB for user ${user.uid}');
    } catch (e) {
      print('Error saving FCM token to DB: $e');
    }
  }

  Future<void> _initDeepLinks() async { // This will only be called if !kIsWeb
    _appLinks = AppLinks();
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('Initial mobile deep link received: $initialUri');
        _handleMobileDeepLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial mobile deep link: $e');
    }
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      print('Streamed mobile deep link received: $uri');
      _handleMobileDeepLink(uri);
    }, onError: (err) {
      print('Error in mobile deep link stream: $err');
    });
  }

  void _handleMobileDeepLink(Uri uri) { // Renamed for clarity
    print('Handling mobile deep link: $uri');
    if (uri.scheme == 'myapp' && uri.host == 'payment-result') {
      final status = uri.queryParameters['status'];
      // For mobile, we don't usually pass large data via deep links.
      // The PaymentWebView already has `donationData` if needed.
      Map<String, dynamic> argumentsForNavigation = {};
      if (status == 'success') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/successPay', (route) => false, arguments: argumentsForNavigation);
      } else if (status == 'fail') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/failPay', (route) => false, arguments: argumentsForNavigation);
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _linkSubscription?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF303030),
      ),
      initialRoute: kIsWeb && Uri.base.path.isNotEmpty ? Uri.base.path + (Uri.base.hasQuery ? '?${Uri.base.query}' : '') : '/',
      onGenerateRoute: (settings) { // settings already IS a RouteSettings object
        Uri? routeUri;
        if (settings.name != null) {
          if (kIsWeb) {
            routeUri = Uri.parse(settings.name!);
          }
        }

        print("[Web specific onGenerateRoute] settings.name: ${settings.name}, parsed routeUri: $routeUri");

        if (kIsWeb && routeUri != null && routeUri.path == '/payment-redirect') {
          final billId     = routeUri.queryParameters['billplz[id]'];
          final paid       = routeUri.queryParameters['billplz[paid]'];
          final paidAt     = routeUri.queryParameters['billplz[paid_at]'];
          final xSignature = routeUri.queryParameters['billplz[x_signature]'];
          print('[Web] Payment redirect detected: billId=$billId, paid=$paid, paidAt=$paidAt');
          Map<String, dynamic> paymentResultArgs = {
            'billplz_id'       : billId,
            'billplz_paid'     : paid,
            'billplz_paid_at'  : paidAt,
            'billplz_signature': xSignature,
            'source'           : 'web_redirect'
          };

          if (paid == 'true') { // Billplz success
            return MaterialPageRoute(
              builder: (_) => const SuccessPay(), // No 'arguments:' here
              settings: RouteSettings(arguments: paymentResultArgs), // Pass args via settings
            );
          } else { // Includes '3' (failure) and potentially others like '2' (pending)
            return MaterialPageRoute(
              builder: (_) => const FailPay(), // No 'arguments:' here
              settings: RouteSettings(arguments: paymentResultArgs), // Pass args via settings
            );
          }
        }

        // Fallback to named routes if not a web payment redirect
        switch (settings.name) {
          case '/successPay':
            return MaterialPageRoute(
              builder: (_) => const SuccessPay(), // No 'arguments:' here
              settings: settings, // Pass the original settings object which contains arguments
            );
          case '/failPay':
            return MaterialPageRoute(
              builder: (_) => const FailPay(), // No 'arguments:' here
              settings: settings, // Pass the original settings object
            );
          case '/notifications':
            return MaterialPageRoute(builder: (_) => NotificationsScreen());
          case '/':
          default:
            return MaterialPageRoute(builder: (_) => AuthWrapper());
        }
      },
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              backgroundColor: Color(0xFF303030),
              body: Center(child: CircularProgressIndicator(color: Color(0xFFFDB515))));
        }
        if (snapshot.hasError) {
          return const Scaffold(
              backgroundColor: Color(0xFF303030),
              body: Center(child: Text('Error initializing authentication.', style: TextStyle(color: Colors.red))));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ProfilePage(user: snapshot.data!);
        }
        return LoginPage();
      },
    );
  }
}

// Ensure SuccessPay, FailPay, and NotificationsScreen widgets are correctly defined
// and can handle the 'arguments' parameter if you intend to pass data.
// Example structure for SuccessPay/FailPay:
//
// class SuccessPay extends StatelessWidget {
//   final Map<String, dynamic>? arguments; // Can be Map<String, String?> for web
//   const SuccessPay({Key? key, this.arguments}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // Use arguments to display info
//     return Scaffold(
//       appBar: AppBar(title: Text("Payment Success")),
//       body: Center(child: Text("Payment successful! Details: ${arguments.toString()}")),
//     );
//   }
// }