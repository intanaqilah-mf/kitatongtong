import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../pages/profilePage.dart';
import '../pages/HomePage.dart';
import '../pages/adminHomepage.dart';
import '../pages/staffHomepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatelessWidget {
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print("Google Sign-In canceled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

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

  Future<void> checkUserRoleAndNavigate(BuildContext context, User user) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (docSnapshot.exists) {
      final role = docSnapshot.data()?['role'] ?? 'asnaf';
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => adminHomePage()),
        );
      } else if (role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StaffHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    }
  }

  Future<void> createUserInFirestore(User user) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnapshot = await userRef.get();
      if (!docSnapshot.exists) {
        await userRef.set({
          'email': user.email,
          'name': user.displayName ?? "No Name",
          'role': 'asnaf',
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        });
        print("User document created for UID: ${user.uid}");
      } else {
        print("User document already exists for UID: ${user.uid}");
      }
    } catch (e) {
      print("Error creating user in Firestore: $e");
    }
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
              height: MediaQuery.of(context).size.height * 0.65, // Occupy 3/4 of the screen
              width: MediaQuery.of(context).size.width, // Full screen width
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), // Rounded corners
                  topRight: Radius.circular(30),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.16, 0.38, 0.58, 0.88],
                  colors: [
                    Color(0xFFF9F295), // Light Yellow
                    Color(0xFFE0AA3E), // Gold
                    Color(0xFFF9F295), // Light Yellow
                    Color(0xFFB88A44), // Brownish Gold
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Sign up or log in",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Select your preferred method to continue",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/Search (1).png', // Google icon asset
                            height: 20,
                          ),
                          label: Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 18, // Increase font size here
                              fontWeight: FontWeight.w300, // Optional: Make the text bold
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final userCredential = await signInWithGoogle();
                              if (userCredential != null) {
                                final user = userCredential.user!;
                                await createUserInFirestore(user);
                                await updateLastLogin(user);
                                await checkUserRoleAndNavigate(context, user);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(user: userCredential.user),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Google sign-in canceled.")),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Google sign-in failed: $e")),
                              );
                              print("Sign-in error: $e");
                            }
                          },

                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/mail 1.png', // Mail icon
                            height: 20,
                          ),
                          label: Text(
                            "Continue with Email",
                            style: TextStyle(
                              fontSize: 18, // Increase font size here
                              fontWeight: FontWeight.w300, // Optional: Make the text bold
                            ),
                          ),
                          onPressed: () {
                            // Navigate to email sign-in page or logic
                          },
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/student2.png', // Bottom student image
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final user = FirebaseAuth.instance.currentUser;
    if (googleUser == null) {
      return null;
    }
    if (user == null) {
      print("No user is authenticated");
    } else {
      print("User authenticated: ${user.uid}");
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    print("Error during Google Sign-In: $e");
    return null;
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
  ));
}
