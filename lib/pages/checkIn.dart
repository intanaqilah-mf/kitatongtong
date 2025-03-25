import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successCheckIn.dart';

final TextEditingController _attendanceCodeController = TextEditingController();
final TextEditingController _eventNameController = TextEditingController();
final TextEditingController _pointsController = TextEditingController();
final TextEditingController _participantNameController = TextEditingController();
final TextEditingController _participantNumberController = TextEditingController();

class checkIn extends StatefulWidget {
  @override
  _checkInState createState() => _checkInState();
}

class _checkInState extends State<checkIn> {
  Map<String, String> formData = {};
  int _selectedIndex = 0;
  String? currentUserEmail;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _fetchEventDetails(String attendanceCode) async {
    var eventDoc = await FirebaseFirestore.instance
        .collection('event')
        .where('attendanceCode', isEqualTo: attendanceCode)
        .get();

    if (eventDoc.docs.isNotEmpty) {
      var eventData = eventDoc.docs.first.data();
      setState(() {
        _eventNameController.text = eventData['eventName'] ?? '';
        _pointsController.text = eventData['points'].toString();
      });
    }
  }

  void _fetchUserDetails() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _participantNameController.text = userData['name'] ?? '';
          _participantNumberController.text = userData['phone'] ?? '';
          currentUserEmail = userData['email'];
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 70),
              Text(
                "Check-In Event",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDB515),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "I am participating event",
                style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              buildTextField("Enter Attendance Code", "attendanceCode", _attendanceCodeController, isReadOnly: false, onChanged: (value) => _fetchEventDetails(value)),
              buildTextField("Event", "eventName", _eventNameController, isReadOnly: true),
              buildTextField("Participant's Name", "name", _participantNameController, isReadOnly: true),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Participant’s Number",
                      style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(color: Color(0xFFFDB515), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "+60",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _participantNumberController,
                              readOnly: true,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Participant's phone number",
                                hintStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              buildTextField("Points per attendance", "points", _pointsController, isReadOnly: true),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  try {
                    final userId = FirebaseAuth.instance.currentUser!.uid;
                    final pointsToAdd = int.tryParse(_pointsController.text) ?? 0;
                    await FirebaseFirestore.instance.collection("checkIn_list").add({
                      "attendanceCode": _attendanceCodeController.text,
                      "eventName": _eventNameController.text,
                      "points": pointsToAdd,
                      "participantNumber": _participantNumberController.text,
                      "checkedInAt": Timestamp.now(),
                      "submittedBy": {
                        "name": _participantNameController.text,
                        "email": currentUserEmail ?? '',
                      },
                    });

                    final userDocRef = FirebaseFirestore.instance.collection("users").doc(userId);
                    final userDoc = await userDocRef.get();

                    if (userDoc.exists) {
                      int currentPoints = (userDoc.data()?['points'] ?? 0) as int;
                      await userDocRef.update({
                        'points': currentPoints + pointsToAdd,
                      });
                    } else {
                      // Set it in case points field doesn't exist
                      await userDocRef.set({'points': pointsToAdd}, SetOptions(merge: true));
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => successCheckIn()),
                          (route) => false, // Clears the navigation stack
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Check-in successful!")),
                    );
                  } catch (e) {
                    print("Error storing check-in: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to check in. Please try again.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDB515),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Center(child: Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white))),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget buildTextField(String label, String key, TextEditingController controller, {bool isReadOnly = false, Function(String)? onChanged}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(color: Color(0xFFFDB515), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              onChanged: onChanged,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}