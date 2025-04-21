// lib/pages/successRedeem.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/redemptionStatus.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class SuccessRedeem extends StatefulWidget {
  @override
  _SuccessRedeemState createState() => _SuccessRedeemState();
}

class _SuccessRedeemState extends State<SuccessRedeem> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the entire body in a FutureBuilder so we can grab the doc ID
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('redeemedKasih')
            .orderBy('redeemedAt', descending: true)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Unable to fetch pickup code.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Grab the latest redemption document
          final doc = snapshot.data!.docs.first;
          final data = doc.data()! as Map<String, dynamic>;
          final pickupCode = data['pickupCode'] ?? 'N/A';
          final docId = doc.id;

          return Column(
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
                          "Your redemption is successful!",
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFCF40),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Congratulations! Your Package A has been successfully redeemed. Your pickup code is",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          pickupCode,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "You can pick up your package at:\n"
                              "MADAD Office\n"
                              "Operating Hours: 9:00 AM - 5:00 PM\n"
                              "Please ensure you bring your redemption code and valid ID during pickup.",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Track Order button now passes the documentId
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEFBF04),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RedemptionStatus(documentId: docId),
                      ),
                          (route) => false,
                    );
                  },
                  child: Text(
                    "Track Order",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
