import 'package:flutter/material.dart';
import '../widgets/HomeAppBar.dart';
import '../widgets/AsnafDashboard.dart';
import '../widgets/UserPoints.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Keep track of the selected tab

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Widget content based on the selected tab
  static List<Widget> _widgetOptions = <Widget>[
    ListView(
      children: [
        Container(
          padding: EdgeInsets.only(top: 15),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                padding: EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Wrapping TextFormField in Expanded
                    Expanded(
                      child: Container(
                        //margin: EdgeInsets.only(left: 5),
                        height: 50,
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search here...",
                          ),
                        ),
                      ),
                    ),
                    // Search Icon
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
                      child: Icon(
                        Icons.search_rounded,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              AsnafDashboard(),
              UserPoints(),
            ],
          ),
        ),
      ],
    ),
    Center(child: Text('Search Page')), // Add other tabs here
    Center(child: Text('Shopping Page')),
    Center(child: Text('Inbox Page')),
    Center(child: Text('Profile Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // Display selected tab content
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex, // Pass selected index to BottomNavBar
        onItemTapped: _onItemTapped, // Pass the tap handler to BottomNavBar
      ),
    );
  }
}