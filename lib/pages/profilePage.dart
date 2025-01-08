import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottomNavBar.dart';
import '../pages/loginPage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  final User? user;

  ProfilePage({this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // Retrieve the current user
    currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
  }
  Future<void> clearAuthCache() async {
    // Sign out from FirebaseAuth
    await FirebaseAuth.instance.signOut();

    // Clear Google Sign-In cache
    GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect(); // Disconnect account from the app
    }
    await googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : AssetImage('assets/profileNotLogin.png') as ImageProvider,
                ),
                SizedBox(height: 20),
                // Name Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentUser?.displayName ?? "Set your name",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      'assets/pencil.png',
                      height: 20,
                      width: 20,
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // Profile Information
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Color(0xFF404040),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      buildProfileRow('assets/profileicon1.png', 'Change profile photo'),
                      buildProfileRow('assets/profileicon2.png', currentUser?.displayName ?? 'Set username'),
                      buildProfileRow('assets/profileicon3.png', currentUser?.phoneNumber ?? 'Set mobile number'),
                      buildProfileRow('assets/profileicon4.png', 'Set NRIC'),
                      buildProfileRow('assets/profileicon5.png', 'Set home address'),
                      buildProfileRow('assets/profileicon6.png', 'Set city'),
                      buildProfileRow('assets/profileicon7.png', 'Set postcode'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentUser != null ? Colors.red : Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              ),
              onPressed: () async {
                if (currentUser != null) {
                  // Logout from FirebaseAuth and GoogleSignIn
                  await GoogleSignIn().signOut(); // Sign out from Google account
                  await FirebaseAuth.instance.signOut(); // Sign out from Firebase

                  // Redirect to LoginPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                } else {
                  // Navigate to LoginPage if not logged in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                }
              },
              child: Text(
                currentUser != null ? "Logout" : "Login",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onItemTapped: (int index) {
          if (index != 4) {
            Navigator.pushNamed(context, '/home'); // Navigate to other pages
          }
        },
      ),
    );
  }

  Widget buildProfileRow(String iconPath, String text) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        height: 24,
        width: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
