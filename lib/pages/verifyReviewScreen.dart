import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/pages/verifyApplications.dart'; // Ensure this import is correct
import 'package:projects/widgets/bottomNavBar.dart';

class VerifyReviewScreen extends StatefulWidget {
  @override
  _VerifyReviewScreen createState() => _VerifyReviewScreen();
}

class _VerifyReviewScreen extends State<VerifyReviewScreen> {
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
                      'assets/hourglass.png', // Replace with your hourglass asset
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "You have successfully reviewed an application!",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCF40), // Yellow color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Do you want to review another applicant?",
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
          // Move the buttons higher up by reducing the bottom padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // OK Button
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFCF40), // Button background color
                      foregroundColor: Colors.black, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      minimumSize: Size(140, 45), // Button size
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VerifyApplicationsScreen()),
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
                // No Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB88A44), // Button background color for No
                    foregroundColor: Colors.black, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    minimumSize: Size(140, 45), // Button size
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                          (route) => false, // Clears the navigation stack
                    );
                  },
                  child: Text(
                    "No",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10), // Optional: Add a small space at the bottom
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
