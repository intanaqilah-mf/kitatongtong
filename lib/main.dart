import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF303030), // Background color for the app
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of widgets for each tab
  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    Center(child: Text('Search Page')),
    Center(child: Text('Notifications Page')),
    Center(child: Text('Profile Page')),
    Center(child: Text('Settings Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF3F3F3F),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
      ),
    );
  }
}
