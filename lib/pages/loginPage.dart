import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../pages/profilePage.dart';
// import '../pages/HomePage.dart'; // HomePage import was present but not used in the build method or sign-in logic.
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatelessWidget {
  // signInWithGoogle method remains the same as you provided
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

  // checkUserRoleAndNavigate method remains the same
  Future<void> checkUserRoleAndNavigate(BuildContext context, User user) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();
      if (!docSnapshot.exists) {
        print("Creating Firestore document for user: ${user.uid}");
        await userRef.set({
          'email': user.email,
          'name': user.displayName ?? "No Name",
          'role': 'asnaf', // Default role
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        });
        print("User document created for UID: ${user.uid}");
      } else {
        print("User document already exists for UID: ${user.uid}");
        // If document exists, you might still want to update last_login here
        // or ensure it's handled by updateLastLogin called separately.
      }
    } catch (e) {
      print("Error creating or checking user in Firestore: $e");
    }
  }

  // createUserInFirestore method remains the same
  Future<void> createUserInFirestore(User user) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();
      if (!docSnapshot.exists) {
        print("Creating Firestore document for user: ${user.uid}");
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

  // updateLastLogin method remains the same
  Future<void> updateLastLogin(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // It's good practice to ensure the document exists before updating,
    // or use SetOptions(merge: true) if creating/updating.
    // However, since createUserInFirestore is called before this, it should usually exist.
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
                // ✨ MAIN CHANGE: Wrap the Column with SingleChildScrollView ✨
                child: SingleChildScrollView(
                  child: Column(
                    // When inside SingleChildScrollView, MainAxisAlignment.spaceBetween
                    // might not behave as expected if the content is shorter than the view.
                    // Consider using MainAxisAlignment.start and adding Spacer() or SizedBox
                    // if specific spacing is needed at the bottom.
                    // For simply preventing overflow, this is fine.
                    mainAxisAlignment: MainAxisAlignment.start, // Adjusted for scrolling
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
                            textAlign: TextAlign.center, // Added for better text wrapping
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
                              'assets/Search (1).png',
                              height: 20,
                            ),
                            label: Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final userCredential = await signInWithGoogle();
                                if (userCredential != null && userCredential.user != null) { // Added null check for userCredential.user
                                  final user = userCredential.user!;
                                  await createUserInFirestore(user); // Ensures user doc is created/checked
                                  await updateLastLogin(user); // Updates last login
                                  // checkUserRoleAndNavigate is redundant if createUserInFirestore handles creation
                                  // and you're navigating to ProfilePage regardless of new/existing for this button.
                                  // If checkUserRoleAndNavigate had specific navigation logic based on role
                                  // that differs from ProfilePage, then it would be needed.
                                  // For now, assuming ProfilePage is the destination.
                                  // await checkUserRoleAndNavigate(context, user);
                                  if (context.mounted) { // Check if widget is still in the tree
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(user: userCredential.user),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Google sign-in canceled or failed.")),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Google sign-in error: $e")),
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
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Image.asset(
                              'assets/mail 1.png',
                              height: 20,
                            ),
                            label: Text(
                              "Continue with Email",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            onPressed: () {
                              // Navigate to email sign-in page or logic
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Email sign-in not implemented yet.")),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 30), // Added SizedBox for spacing before the bottom image
                      Image.asset(
                        'assets/student2.png',
                        height: 300, // This height is quite large and a primary cause of overflow.
                        // Consider reducing it or making it more flexible if possible.
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

// The standalone signInWithGoogle function you had at the end of the file
// is already part of the LoginPage class, so it's redundant here.
// If it was meant to be a global function, ensure it's defined outside any class.
// For this solution, I'm assuming the one within the class is the one being used.

// The main function should typically be in your main.dart file.
// If this is your main file for testing this page, it's okay.
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
  ));
}