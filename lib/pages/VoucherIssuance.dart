import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/reviewIssueReward.dart';

class VoucherIssuance extends StatefulWidget {
  final String documentId;

  VoucherIssuance({required this.documentId});

  @override
  _VoucherIssuanceState createState() => _VoucherIssuanceState();
}

class _VoucherIssuanceState extends State<VoucherIssuance> {
  int _selectedIndex = 0;

  // Dropdown selections
  String selectedRewardType = "Voucher Package Kasih";
  String selectedEligibility = "Asnaf Application";
  String selectedRewardAmount = "RM10"; // Default for RM rewards
  TextEditingController pointsController = TextEditingController(); // For manual points input

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void submitRewardDetails() async {
    try {
      // Determine the correct reward value based on reward type
      String finalRewardValue = selectedRewardType == "Points"
          ? pointsController.text // User input for points
          : selectedRewardAmount; // Dropdown value for RM

      await FirebaseFirestore.instance.collection('applications').doc(widget.documentId).update({
        'rewardType': selectedRewardType,
        'eligibilityDetails': selectedEligibility,
        'reward': finalRewardValue,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reward details updated successfully!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewIssueReward()),
      );

    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update reward details.")),
      );
    }
  }

  Future<DocumentSnapshot> fetchApplicationData(String documentId) async {
    return await FirebaseFirestore.instance.collection('applications').doc(documentId).get();
  }

  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
                    "Voucher Issuance",
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
                var userId = applicationData['userId'];
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
                            Text(
                              applicationCode,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text.rich(TextSpan(
                              children: [
                                TextSpan(text: "Full Name: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                TextSpan(text: fullname, style: TextStyle(fontSize: 16)),
                              ],
                            )),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      Text("Reward Type", style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedRewardType,
                          decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
                          items: ["Voucher Package Kasih", "Points"].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedRewardType = newValue!;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 15),
                      Text("Eligibility Details", style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedEligibility,
                          decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
                          items: ["Asnaf Application", "Participation in event"].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedEligibility = newValue!;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 15),

                      // Reward Amount or Points Input
                      Text(
  selectedRewardType == "Points" ? "Reward (Points)" : "Reward Amount (RM)",
  style: TextStyle(color: Colors.white, fontSize: 16),
),
SizedBox(height: 5),
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: selectedRewardType == "Points"
      ? TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(10),
            hintText: "Enter points",
          ),
        )
      : DropdownButtonFormField<String>(
          value: selectedRewardAmount,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(10),
          ),
          items: ["RM10", "RM20", "RM50"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedRewardAmount = newValue!;
            });
          },
        ),
),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFDB515),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: submitRewardDetails, // Calls function to store data
                          child: Text(
                            "Submit",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
