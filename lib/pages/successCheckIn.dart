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
  Map<String, dynamic>? checkInData;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void initState() {
    super.initState();
    _fetchCheckInDetails();
  }

  void _fetchCheckInDetails() async {
    try {
      var checkInDoc = await FirebaseFirestore.instance
          .collection('checkIn_list')
          .orderBy('checkedInAt', descending: true)
          .limit(1)
          .get();

      if (checkInDoc.docs.isNotEmpty) {
        setState(() {
          checkInData = checkInDoc.docs.first.data();
        });
      }
    } catch (e) {
      print("Error fetching check-in details: $e");
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
                      "Participant's Name: ${checkInData?["participantName"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Participant's Number: ${checkInData?["participantNumber"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Event Name: ${checkInData?["eventName"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Event Date: ${checkInData?["eventDate"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Text(
                      "Eligible Points: ${checkInData?["points"] ?? "Unknown"}",
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
