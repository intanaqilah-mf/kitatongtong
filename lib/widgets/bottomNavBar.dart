import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex; // Selected index passed from the parent
  final Function(int) onItemTapped; // Function to handle taps passed from the parent

  const BottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Color(0xFF3F3F3F),
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.grey,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
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
            'assets/bottomNaviAsnaf2.png',
            height: 30,
            width: 30,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/bottomNaviAsnaf3.png',
            height: 30,
            width: 30,
          ),
          label: 'Shopping',
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
