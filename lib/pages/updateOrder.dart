import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/reviewUpdateOrder.dart';

class UpdateOrder extends StatefulWidget {
  final String documentId;

  UpdateOrder({required this.documentId});

  @override
  _UpdateOrderState createState() => _UpdateOrderState();
}

class _UpdateOrderState extends State<UpdateOrder> {
  int _selectedIndex = 0;
  String selectedStatus = "No"; // or "Yes" if you prefer
  TextEditingController reasonController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<DocumentSnapshot> fetchApplicationData(String documentId) async {
    return await FirebaseFirestore.instance.collection('redeemedKasih').doc(documentId).get();
  }

  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  void submitStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('redeemedKasih')
          .doc(widget.documentId)
          .update({'processedOrder': 'yes'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order marked as picked up.")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewUpdateOrder(documentId: widget.documentId),
        ),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status.")),
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    "Process Order",
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
                      var userName = applicationData['userName'] ?? 'N/A';

                      return Text(
                        userName,
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
                var userId = applicationData['userId'];
                var pickupCode = applicationData['pickupCode'] ?? 'No Code';

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
                              pickupCode,
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
                                      TextSpan(text: "User Name: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: applicationData['userName'] ?? '-', style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Pickup Code: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: pickupCode, style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(text: "Value Redeemed: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      TextSpan(text: "RM${applicationData['valueRedeemed'] ?? 0}", style: TextStyle(fontSize: 16)),
                                    ],
                                  )),
                                  Text.rich(TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Processed Order: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      TextSpan(
                                        text: applicationData.data().toString().contains('processedOrder')
                                            ? applicationData['processedOrder']
                                            : 'no',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  )),
                                  Text(
                                    "Item(s) Redeemed:",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  ...List.generate((applicationData['itemsRedeemed'] as List).length, (i) {
                                    final item = (applicationData['itemsRedeemed'] as List)[i];
                                    return Text(
                                      "${i + 1}. ${item['name']} (${item['number']} ${item['unit']})",
                                      style: TextStyle(fontSize: 15, color: Colors.black),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status and Reason sections
                      SizedBox(height: 20),
                      Text("Have you done processing the order?", style: TextStyle(color: Colors.white, fontSize: 16)),
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
                            items: ["Yes", "No"].map((String value) {
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
                      SizedBox(height: 25),
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
