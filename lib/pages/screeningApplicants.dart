import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/verifyReviewScreen.dart';

class ScreeningApplicants extends StatefulWidget {
  final String documentId;

  ScreeningApplicants({required this.documentId});

  @override
  _ScreeningApplicantsState createState() => _ScreeningApplicantsState();
}

class _ScreeningApplicantsState extends State<ScreeningApplicants> {
  int _selectedIndex = 0;
  String selectedStatus = "Approve"; // Default status selection
  TextEditingController reasonController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<DocumentSnapshot> fetchApplicationData(String documentId) async {
    return await FirebaseFirestore.instance.collection('applications').doc(documentId).get();
  }

  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  void submitStatus() async {
    String finalStatus = selectedStatus;

    if (selectedStatus.isEmpty) {
      finalStatus = "Pending";
    }

    try {
      // Update the application in Firestore with the new statusReward field.
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.documentId)
          .update({
        'statusApplication': finalStatus,
        'reasonStatus': reasonController.text,
        'statusReward': 'Pending',
      });

      // Show a success message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Application status updated successfully!")),
      );

      // Navigate to VerifyReviewScreen after submitting.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyReviewScreen()),
      );
    } catch (e) {
      print("Error: $e"); // Debug output in case of error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    "Screening applicants",
                    style: TextStyle(
                      color: Color(0xFFFDB515),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15.0),
                  FutureBuilder<DocumentSnapshot>(
                    future: fetchApplicationData(widget.documentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('No data found for this applicant.');
                      }
                      var applicationData = snapshot.data!;
                      var fullname = applicationData['fullname'] ?? 'N/A';

                      return Text(
                        fullname,
                        style: TextStyle(
                          color: Color(0xFFF1D789),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: fetchApplicationData(widget.documentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('No data found for this applicant.'));
                }

                var applicationData = snapshot.data!;
                var fullname = applicationData['fullname'] ?? 'N/A';
                var mobileNumber = applicationData['mobileNumber'] ?? 'No phone number available';
                var email = applicationData['email'] ?? 'No email available';
                var addressLine1 = applicationData['addressLine1'] ?? 'No address available';
                var addressLine2 = applicationData['addressLine2'] ?? 'No address available';
                var city = applicationData['city'] ?? 'No address available';
                var postcode = applicationData['postcode'] ?? 'No address available';
                var justificationApplication = applicationData['justificationApplication'] ?? 'No justification available';
                var monthlyIncome = applicationData['monthlyIncome'] ?? 'No income available';
                var nric = applicationData['nric'] ?? 'No NRIC available';
                var userId = applicationData['userId'];
                var residencyStatus = applicationData['residencyStatus'] ?? 'Unknown';
                var employmentStatus = applicationData['employmentStatus'] ?? 'Unknown';
                var date = applicationData['date'] ?? 'No date available';
                var applicationCode = applicationData['applicationCode'] ?? 'No Code';

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: fetchUserData(userId),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (userSnapshot.hasError) {
                                  return Text('Error: ${userSnapshot.error}');
                                }
                                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                  return CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, color: Colors.white),
                                  );
                                }

                                var userData = userSnapshot.data!;
                                var photoUrl = userData['photoUrl'];

                                return CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(photoUrl ?? ''),
                                  child: photoUrl == null
                                      ? Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                );
                              },
                            ),
                            SizedBox(height: 10),

                            // Application Code (Centered)
                            Text(
                              applicationCode,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Full Name: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: fullname, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Asnaf NRIC: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: nric, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Phone number: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: "60$mobileNumber", style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Address: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: "$addressLine1, $addressLine2, $postcode, $city", style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Residency Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: residencyStatus, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Employment Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: employmentStatus, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Monthly Income: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: monthlyIncome, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Justification of application: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: justificationApplication, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status and Reason sections
                      SizedBox(height: 20),

                      // Status Dropdown Section
                      Text("Status", style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            items: ["Approve", "Disapprove"].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedStatus = newValue!;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Reason TextField
                      Text("Reason", style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 5),
                      TextField(
                        controller: reasonController,
                        maxLines: null, // Allows expanding dynamically
                        minLines: 3, // Default height
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: "Enter reason...",
                        ),
                      ),

                      SizedBox(height: 25),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitStatus,
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

                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
