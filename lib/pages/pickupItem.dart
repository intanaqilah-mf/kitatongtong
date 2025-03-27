import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/pickupSuccess.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';

final TextEditingController _attendanceCodeController = TextEditingController();
final TextEditingController _eventNameController = TextEditingController();
final TextEditingController _pointsController = TextEditingController();
final TextEditingController _participantNameController = TextEditingController();
final TextEditingController _participantNumberController = TextEditingController();

class pickUpItem extends StatefulWidget {
  @override
  _pickUpItemState createState() => _pickUpItemState();
}

class _pickUpItemState extends State<pickUpItem> {
  Map<String, String> formData = {};
  int _selectedIndex = 0;
  String? currentUserEmail;
  String? docIdToUpdate;

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
  void _fetchPickupDetails(String code) async {
    final trimmedCode = code.trim();

    if (trimmedCode.isEmpty) {
      _clearAllFields();
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('redeemedKasih')
        .where('pickupCode', isEqualTo: trimmedCode)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final userId = data['userId'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      setState(() {
        _eventNameController.text = data['valueRedeemed'].toString();
        _participantNameController.text = data['userName'] ?? '';
        _participantNumberController.text = userDoc.data()?['phone'] ?? '';
        docIdToUpdate = snapshot.docs.first.id;
      });
    } else {
      _clearAllFields(); // clear if code is wrong
    }
  }

  void _clearAllFields() {
    setState(() {
      _eventNameController.clear();
      _participantNameController.clear();
      _participantNumberController.clear();
      docIdToUpdate = null;
    });
  }

  @override
  void dispose() {
    _attendanceCodeController.clear();
    _eventNameController.clear();
    _participantNameController.clear();
    _participantNumberController.clear();
    super.dispose();
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
                "Verify pickup code here",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDB515),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Fill in pickup code to verify it",
                style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              buildTextField("Enter Pickup Code", "attendanceCode", _attendanceCodeController, isReadOnly: false, onChanged: (value) => _fetchPickupDetails(value)),
              buildTextField("Reward Redeemed", "eventName", _eventNameController, isReadOnly: true),
              buildTextField("Asnaf's Name", "name", _participantNameController, isReadOnly: true),

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
              SizedBox(height: 20),

              ElevatedButton(
                  onPressed: () async {
                    if (docIdToUpdate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Invalid pickup code.")),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection("redeemedKasih")
                          .doc(docIdToUpdate)
                          .update({"pickedUp": "yes"});

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => pickupSuccess(
                            name: _participantNameController.text,
                            phone: _participantNumberController.text,
                            reward: _eventNameController.text,
                            pickupCode: _attendanceCodeController.text,
                          ),
                        ),
                            (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Item marked as picked up.")),
                      );
                    } catch (e) {
                      print("Error updating document: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to update. Please try again.")),
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