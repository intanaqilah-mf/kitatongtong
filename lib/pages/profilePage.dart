import 'package:flutter/material.dart';
import '../widgets/bottomNavBar.dart';
import '../pages/loginPage.dart';

class ProfilePage extends StatelessWidget {
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
                  backgroundImage: AssetImage('assets/profileNotLogin.png'),
                ),
                SizedBox(height: 20),
                // Name Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Set your name",
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
                      buildProfileRow('assets/profileicon2.png', 'Set username'),
                      buildProfileRow('assets/profileicon3.png', 'Set mobile number'),
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
                backgroundColor: Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to the LoginPage
                );
              },
              child: Text(
                "Login",
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
            // Navigate to other pages
            Navigator.pushNamed(context, '/home');
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
