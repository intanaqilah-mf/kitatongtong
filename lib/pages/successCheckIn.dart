import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class successCheckIn extends StatefulWidget {
  @override
  _successCheckInState createState() =>
      _successCheckInState();
}

class _successCheckInState extends State<successCheckIn> {
  int _selectedIndex = 0;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? eventData;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchEventDetails();
  }
  void _fetchUserDetails() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  void _fetchEventDetails() async {
    try {
      // Fetch the last check-in (or based on other criteria)
      var checkInDoc = await FirebaseFirestore.instance
          .collection('checkIn_list')
          .orderBy('checkedInAt', descending: true)
          .limit(1)
          .get();

      if (checkInDoc.docs.isNotEmpty) {
        var checkInData = checkInDoc.docs.first.data();
        String attendanceCode = checkInData['attendanceCode']; // Get the attendance code

        // Fetch the event with the matching attendance code
        var eventDoc = await FirebaseFirestore.instance
            .collection('event')
            .where('attendanceCode', isEqualTo: attendanceCode)
            .get();

        if (eventDoc.docs.isNotEmpty) {
          setState(() {
            eventData = eventDoc.docs.first.data(); // Set the event data
          });
        }
      }
    } catch (e) {
      print("Error fetching event details: $e");
    }
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
                      'assets/check.png',
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Check-In Successful",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCF40),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Here is the event check-in detail.",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Participant's Name: ${userData?["name"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Participant's Number: ${userData?["phone"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Event Name: ${eventData?["eventName"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Event Date: ${eventData?["eventDate"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Eligible Points: ${eventData?["points"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
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
                backgroundColor: Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(300, 45),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
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
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );}
}
