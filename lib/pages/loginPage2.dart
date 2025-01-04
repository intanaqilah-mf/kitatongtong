import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      return null; // The user canceled the sign-in
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030), // Match the background color with the app theme
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/student1.png', // Top student image
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.16, 0.38, 0.58, 0.88],
                colors: [
                  Color(0xFFF9F295), // Light Yellow
                  Color(0xFFE0AA3E), // Gold
                  Color(0xFFF9F295), // Light Yellow
                  Color(0xFFB88A44), // Brownish Gold
                ],
              ).createShader(bounds);
            },
            child: Container(
              padding: EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/Search (1).png', // Your Google icon asset
                      height: 20,
                    ),
                    label: Text("Continue with Google"),
                    onPressed: () async {
                      final user = await signInWithGoogle();
                      if (user != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Logged in as ${user.user?.displayName}")),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/mail 1.png', // Gold mail icon
                      height: 20,
                    ),
                    label: Text("Continue with Email"),
                    onPressed: () {
                      // Navigate to email sign-in page or logic
                    },
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/student2.png', // Bottom student image
            height: 200,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
