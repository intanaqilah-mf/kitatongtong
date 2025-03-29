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
final TextEditingController _nricController = TextEditingController();

class checkIn extends StatefulWidget {
  @override
  _checkInState createState() => _checkInState();
}

class _checkInState extends State<checkIn> {
  Map<String, String> formData = {};
  int _selectedIndex = 0;
  String? currentUserEmail;
  String? _role;
  String? _staffName;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _fetchEventDetails(String code) async {
    final trimmed = code.trim();

    if (trimmed.isEmpty) {
      _clearForm();
      return;
    }

    final eventDoc = await FirebaseFirestore.instance
        .collection('event')
        .where('attendanceCode', isEqualTo: trimmed)
        .get();

    if (eventDoc.docs.isNotEmpty) {
      final eventData = eventDoc.docs.first.data();

      setState(() {
        _eventNameController.text = eventData['eventName'] ?? '';
        _pointsController.text = eventData['points'].toString();

        if (_role == 'staff') {
          _participantNameController.text = '';
          _participantNumberController.text = '';
        }
      });
    } else {
      _clearForm();
    }
  }
  void _fetchAsnafDetails(String nric) async {
    final trimmed = nric.trim();

    if (trimmed.isEmpty) {
      _participantNameController.clear();
      _participantNumberController.clear();
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('nric', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      final userData = userDoc.docs.first.data();
      setState(() {
        _participantNameController.text = userData['name'] ?? '';
        _participantNumberController.text = userData['phone'] ?? '';
      });
    } else {
      _participantNameController.clear();
      _participantNumberController.clear();
    }
  }

  void _initUserDetails() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        _role = userData['role'] ?? 'asnaf';
        _staffName = userData['name'] ?? '';

        if (_role == 'asnaf') {
          _participantNameController.text = userData['name'] ?? '';
          _participantNumberController.text = userData['phone'] ?? '';
          currentUserEmail = userData['email'];
        }
      });
    }
  }

  void _clearForm() {
    setState(() {
      _eventNameController.clear();
      _pointsController.clear();

      if (_role == 'staff') {
        _participantNameController.clear();
        _participantNumberController.clear();
        _nricController.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initUserDetails();
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
              if (_role == 'staff')
                buildTextField("Enter Asnaf NRIC", "nric", _nricController, isReadOnly: false, onChanged: _fetchAsnafDetails),
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
                      final userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();
                      final role = userDoc.data()?['role'] ?? 'asnaf';
                      final name = userDoc.data()?['name'] ?? '';
                      final pointsToAdd = int.tryParse(_pointsController.text) ?? 0;

                      final submittedBy = role == 'staff'
                          ? {
                        "uid": userId,
                        "name": name,
                        "role": role,
                      }
                          : "system";

                      // ✅ Fetch event date before storing
                      final eventQuery = await FirebaseFirestore.instance
                          .collection('event')
                          .where('attendanceCode', isEqualTo: _attendanceCodeController.text.trim())
                          .limit(1)
                          .get();

                      final eventDate = eventQuery.docs.isNotEmpty
                          ? eventQuery.docs.first.data()['eventDate']
                          : "Unknown";

                      // ✅ Now you can store eventDate properly
                      await FirebaseFirestore.instance.collection("checkIn_list").add({
                        "attendanceCode": _attendanceCodeController.text,
                        "eventName": _eventNameController.text,
                        "points": pointsToAdd,
                        "participantName": _participantNameController.text,
                        "participantNumber": _participantNumberController.text,
                        "checkedInAt": Timestamp.now(),
                        "eventDate": eventDate,
                        "submittedBy": submittedBy,
                      });

                      // ✅ Update participant points
                      final participantDoc = await FirebaseFirestore.instance
                          .collection("users")
                          .where("phone", isEqualTo: _participantNumberController.text)
                          .limit(1)
                          .get();

                      if (participantDoc.docs.isNotEmpty) {
                        final participantId = participantDoc.docs.first.id;
                        final participantPoints = participantDoc.docs.first.data()['points'] ?? 0;

                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(participantId)
                            .update({'points': participantPoints + pointsToAdd});
                      }

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => successCheckIn()),
                            (route) => false,
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