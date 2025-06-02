import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/pages/ProfilePage.dart'; // Assuming this is your ProfilePage import
import 'package:projects/pages/stockItem.dart';
import 'package:projects/pages/notifications.dart';
import 'package:projects/pages/orderProcessed.dart';
import 'package:projects/pages/rewards.dart';
import 'package:projects/pages/trackOrder.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// If you have a LoginPage, import it here for the else case, e.g.:
// import 'package:projects/pages/loginPage.dart';


class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key, // Use super.key for constructors in newer Flutter versions
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          if (mounted) { // Check if the widget is still in the tree
            setState(() {
              role = userDoc['role'] ?? 'other';
              print('Role fetched: $role');
            });
          }
        } else {
          print('User document does not exist');
        }
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Role in build method: $role');
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF3F3F3F),
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.grey,
      currentIndex: widget.selectedIndex,
      onTap: (int index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        } else if (index == 1) {
          if (role == 'asnaf') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TrackOrderScreen(),
              ),
            );
          } else if (role == 'staff' || role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderProcessed(),
              ),
            );
          }
        } else if (index == 2) {
          if (role == 'asnaf') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Rewards(),
              ),
            );
          } else if (role == 'staff' || role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StockItem(),
              ),
            );
          }
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>  NotificationsScreen(), // Assuming NotificationsScreen can be const
            ),
          );
        } else if (index == 4) { // This is likely your line 119 or related block
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(user: currentUser), // Now passing a non-null User
              ),
            );
          } else {
            // Handle the case where the user is null (not logged in)
            // Option 1: Show a message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please log in to view your profile.")),
            );
            // Option 2: Navigate to your login page (if you have one)
            // Example:
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => LoginPage()),
            // );
            print("User is not logged in. Cannot navigate to ProfilePage.");
          }
        }
      },
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/bottomNaviAsnaf1.png',
            height: 30,
            width: 30,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            role == 'asnaf' ? 'assets/bottomNaviAsnaf2.png' : 'assets/checklist.png',
            height: 30,
            width: 30,
          ),
          label: role == 'asnaf' ? 'Track order' : 'Order',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            role == 'staff' || role == 'admin'
                ? 'assets/stock2.png'
                : 'assets/bottomNaviAsnaf3.png',
            height: 30,
            width: 30,
          ),
          label: role == 'staff' || role == 'admin' ? 'Stock' : 'Shopping',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/bottomNaviAsnaf4.png',
            height: 30,
            width: 30,
          ),
          label: 'Inbox',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/bottomNaviAsnaf5.png',
            height: 30,
            width: 30,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}