import 'package:flutter/material.dart';
import 'package:projects/pages/event.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class EventReview extends StatefulWidget {
  @override
  _EventReviewScreenState createState() =>
      _EventReviewScreenState();
}

class _EventReviewScreenState extends State<EventReview> {
  int _selectedIndex = 0;

  // Function to handle BottomNavBar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/check.png', // Replace with your hourglass asset
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "You have created an event!",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCF40), // Yellow color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "It will be reflected at event page.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400], // Light gray color
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFCF40), // Button background color
                foregroundColor: Colors.black, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                minimumSize: Size(300, 45), // Full-width button
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => EventPage()),
                      (route) => false, // Clears the navigation stack
                );
              },
              child: Text(
                "OK",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
