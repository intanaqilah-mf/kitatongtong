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
  String selectedRewardAmount = "RM50"; // Default for RM rewards
  TextEditingController pointsController = TextEditingController(); // For manual points input

  // New state variables for recurring feature
  bool isRecurring = false;
  String selectedRecurrence = "2 Weeks"; // Default recurrence period

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

  void submitRewardDetails() async {
    try {
      // Determine the correct reward value based on reward type.
      String finalRewardValue = selectedRewardType == "Points"
          ? pointsController.text
          : selectedRewardAmount;

      // Calculate next eligible date if recurring
      DateTime? nextEligibleDate;
      if (isRecurring) {
        if (selectedRecurrence == "2 Weeks") {
          nextEligibleDate = DateTime.now().add(Duration(days: 14));
        } else if (selectedRecurrence == "1 Month") {
          nextEligibleDate = DateTime.now().add(Duration(days: 30));
        } else if (selectedRecurrence == "3 Month") {
          nextEligibleDate = DateTime.now().add(Duration(days: 90));
        } else if (selectedRecurrence == "6 Month") {
          nextEligibleDate = DateTime.now().add(Duration(days: 180));
        } else if (selectedRecurrence == "9 Month") {
          nextEligibleDate = DateTime.now().add(Duration(days: 270));
        } else if (selectedRecurrence == "1 year") {
          nextEligibleDate = DateTime.now().add(Duration(days: 365));
        }
      }

      // Update the application document with reward details.
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.documentId)
          .update({
        'rewardType': selectedRewardType,
        'eligibilityDetails': selectedEligibility,
        'reward': finalRewardValue,
        'statusReward': 'Issued',
        'isRecurring': isRecurring,
        'recurrencePeriod': isRecurring ? selectedRecurrence : null,
        'nextEligibleDate': isRecurring ? Timestamp.fromDate(nextEligibleDate!) : null,
        'lastRedeemed': null, // Initially not redeemed
      });

      print("Application document ${widget.documentId} updated successfully.");

      // Fetch application data to retrieve the user ID.
      DocumentSnapshot applicationSnapshot =
      await FirebaseFirestore.instance.collection('applications').doc(widget.documentId).get();
      if (!applicationSnapshot.exists) {
        print("Application document not found for ID: ${widget.documentId}");
        throw Exception("Application document not found.");
      }
      var appData = applicationSnapshot.data() as Map<String, dynamic>;
      String userId = appData['userId'];

      // Generate a unique id for the admin voucher.
      final String adminVoucherId = "admin_${DateTime.now().millisecondsSinceEpoch}";

      // Update the user's voucherReceived field with the admin voucher.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'voucherReceived': FieldValue.arrayUnion([{
          'voucherGranted': finalRewardValue,
          'eligibility': selectedEligibility,
          'rewardType': selectedRewardType,
          'voucherId': adminVoucherId,
          'redeemedAt': Timestamp.now()
        }])
      });

      print("User $userId voucherReceived field updated.");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reward details updated successfully!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewIssueReward()),
      );
    } catch (e) {
      print("Error updating reward details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update reward details.")),
      );
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
            // Header Section
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
            // Main Data Section
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
                      // Application info container
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

                      // Reward Type Dropdown
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
                      // Eligibility Dropdown
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
                      // Recurring Asnaf Radio Buttons
                      Text("Recurring Asnaf", style: TextStyle(color: Colors.white, fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text("Yes", style: TextStyle(color: Colors.white)),
                              value: true,
                              groupValue: isRecurring,
                              onChanged: (bool? value) {
                                setState(() {
                                  isRecurring = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text("No", style: TextStyle(color: Colors.white)),
                              value: false,
                              groupValue: isRecurring,
                              onChanged: (bool? value) {
                                setState(() {
                                  isRecurring = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      // Recurrence Period Dropdown (Conditional)
                      if (isRecurring) ...[
                        SizedBox(height: 15),
                        Text("Recurring every", style: TextStyle(color: Colors.white, fontSize: 16)),
                        SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedRecurrence,
                            decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
                            items: ["2 Weeks", "1 Month", "3 Month","6 Month","9 Month","1 year",].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRecurrence = newValue!;
                              });
                            },
                          ),
                        ),
                      ],


                      SizedBox(height: 15),
                      // Reward Amount (or Points) Input
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
                          items: ["RM50", "RM100", "RM150", "RM200", "RM250"].map((String value) {
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
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFDB515),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: submitRewardDetails,
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