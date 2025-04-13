import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/pages/ProfilePage.dart'; // Import your Profile page
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/stockItem.dart';
import 'package:projects/pages/redemptionStatus.dart';
import 'package:projects/pages/orderProcessed.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex; // Selected index passed from the parent
  final Function(int) onItemTapped; // Function to handle taps passed from the parent

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String role = ''; // Initialize role as an empty string

  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Fetch user role when the widget is initialized
  }

  // Fetch the user's role from Firestore
  Future<void> _fetchUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid; // Get user ID from Firebase Auth
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (userDoc.exists) {
          setState(() {
            role = userDoc['role'] ?? 'other'; // Default to 'other' if role is not found
            print('Role fetched: $role');  // Debug output
          });
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
    print('Role in build method: $role'); // Debug output
    return BottomNavigationBar(
      backgroundColor: Color(0xFF3F3F3F),
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.grey,
      currentIndex: widget.selectedIndex,
      onTap: (int index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(), // Navigate to HomePage
            ),
          );
        } else if (index == 1) {
          if (role == 'asnaf') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Redemptionstatus(),
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
        }
        else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StockItem(), // Navigate to ProfilePage
            ),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(), // Navigate to ProfilePage
            ),
          );
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
