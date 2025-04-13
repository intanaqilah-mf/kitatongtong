import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class StaffDetailScreen extends StatefulWidget {
  final String documentId;
  StaffDetailScreen({required this.documentId});

  @override
  _StaffDetailScreenState createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  int _selectedIndex = 0;
  String selectedRole = ""; // will be assigned from Firestore (lowercase)
  bool _roleLoaded = false; // ensures we only initialize dropdown value once

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// A helper function to build a text row (label + value) in black text.
  Widget textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Updates the user's 'role' field in Firestore when the Submit button is pressed.
  void updateRole() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.documentId)
          .update({
        'role': selectedRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User role updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating role: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.documentId)
            .get(),
        builder: (context, snapshot) {
          // 1) Show loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // 2) Show "no data" message if user doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "No data found for this user.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 3) Extract user data
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var fullname = userData['fullname'] ?? 'N/A';
          var email = userData['email'] ?? 'N/A';
          var phoneNumber = userData['phoneNumber'] ?? 'N/A';
          var addressLine1 = userData['addressLine1'] ?? '';
          var addressLine2 = userData['addressLine2'] ?? '';
          var city = userData['city'] ?? '';
          var postcode = userData['postcode'] ?? '';
          var photoUrl = userData['photoUrl'] ?? '';

          // 4) Initialize 'selectedRole' from Firestore only once
          if (!_roleLoaded) {
            selectedRole = (userData['role'] ?? "staff").toString().toLowerCase();
            _roleLoaded = true;
          }

          // 5) Build UI
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 50.0),
                  Text(
                    "Manage Users",
                    style: TextStyle(
                      color: Color(0xFFFDB515),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15.0),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.16, 0.38, 0.58, 0.88],
                        colors: [
                          Color(0xFFF9F295),
                          Color(0xFFE0AA3E),
                          Color(0xFFF9F295),
                          Color(0xFFB88A44),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        SizedBox(height: 10),

                        // Full Name in the center
                        Center(
                          child: Text(
                            fullname,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF303030),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // User Info Rows in black
                        textRow("Full Name", fullname),
                        textRow("Email", email),
                        textRow("Phone Number", phoneNumber),
                        textRow("Address", "$addressLine1, $addressLine2, $city, $postcode"),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  Text("Role", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        items: ["admin", "staff", "asnaf"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            // Capitalize first letter for display
                            child: Text(
                              value[0].toUpperCase() + value.substring(1),
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedRole = newValue!;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFDB515),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
