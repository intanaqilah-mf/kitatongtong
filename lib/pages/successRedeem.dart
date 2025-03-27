import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/redemptionStatus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Successredeem extends StatefulWidget {
  @override
  _SuccessredeemState createState() =>
      _SuccessredeemState();
}

class _SuccessredeemState extends State<Successredeem> {
  int _selectedIndex = 0;

  // Function to handle BottomNavBar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                      'assets/check.png', // Replace with your hourglass asset
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Your redemption is successful!",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCF40), // Yellow color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Congratulations! Your Package A has been successfully redeemed. Your pickup code is",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400], // Light gray color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('redeemedKasih')
                          .orderBy('redeemedAt', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            "Unable to fetch pickup code.",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          );
                        }

                        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        final pickupCode = data['pickupCode'] ?? 'N/A';

                        return Column(
                          children: [
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
                              "You can pick up your package at:\nMADAD Office\nOperating Hours: 9:00 AM - 5:00 PM\nPlease ensure you bring your redemption code and valid ID during pickup.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
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
                backgroundColor: Color(0xFFEFBF04), // Button background color
                foregroundColor: Colors.black, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                minimumSize: Size(300, 45), // Full-width button
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Redemptionstatus()),
                      (route) => false, // Clears the navigation stack
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
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
