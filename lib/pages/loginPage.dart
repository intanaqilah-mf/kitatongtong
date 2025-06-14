import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../pages/profilePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class LoginPage extends StatelessWidget {
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print("Google Sign-In canceled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        print("User signed in: ${userCredential.user!.uid}");
        return userCredential;
      } else {
        print("No user returned after Google Sign-In.");
        return null;
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> createOrUpdateUserInFirestore(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap    = await userRef.get();

    // 1) Grab provider info
    final profile    = user.providerData
        .firstWhere((p) => p.providerId == 'google.com', orElse: () => user.providerData[0]);
    final email       = profile.email;
    final googlePhoto = profile.photoURL;

    // 2) Download & re-upload into Storage/profile_pictures/uid.jpg
    String storagePhotoUrl = googlePhoto!;
    if (googlePhoto.isNotEmpty) {
      final resp = await http.get(Uri.parse(googlePhoto));
      final ref  = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      await ref.putData(resp.bodyBytes, SettableMetadata(contentType: 'image/jpeg'));
      storagePhotoUrl = await ref.getDownloadURL();
    }
    await user.updatePhotoURL(storagePhotoUrl);

    // 3) Merge into Firestore
    final data = {
      'uid':        user.uid,
      'email':      email,
      'photoUrl':   storagePhotoUrl,
      'name':       user.displayName ?? 'No Name',
      'role':       'asnaf',
      'last_login': FieldValue.serverTimestamp(),
      if (!snap.exists) 'created_at': FieldValue.serverTimestamp(),
    };
    await userRef.set(data, SetOptions(merge: true));
  }

  Future<void> updateLastLogin(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.update({
      'last_login': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030), // Dark background
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Image.asset(
                'assets/student1.png', // Top student image
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.16, 0.38, 0.58, 0.88],
                  colors: [
                    Color(0xFFF9F295),
                    Color(0xFFE0AA3E),
                    Color(0xFFF9F295),
                    Color(0xFFB88A44),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('login_title'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)
                                .translate('login_subtitle'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 50),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Image.asset(
                              'assets/Search (1).png',
                              height: 20,
                            ),
                            label: Text(
                              AppLocalizations.of(context)
                                  .translate('login_google'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final userCredential = await signInWithGoogle();
                                if (userCredential != null &&
                                    userCredential.user != null) {
                                  final user = userCredential.user!;
                                  await createOrUpdateUserInFirestore(user);
                                  await updateLastLogin(user);
                                  print("Email: ${user.email}");

                                  if (context.mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfilePage(user: userCredential.user),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)
                                                  .translate('login_failed'))),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(AppLocalizations.of(
                                            context)
                                            .translateWithArgs('login_error',
                                            {'error': e.toString()}))),
                                  );
                                }
                                print("Sign-in process error: $e");
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              minimumSize: Size(
                                  MediaQuery.of(context).size.width * 0.9, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Image.asset(
                              'assets/mail 1.png',
                              height: 20,
                            ),
                            label: Text(
                              AppLocalizations.of(context)
                                  .translate('login_email'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            onPressed: () {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(AppLocalizations.of(context)
                                          .translate('login_not_implemented'))),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Image.asset(
                        'assets/student2.png',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
  ));
}
