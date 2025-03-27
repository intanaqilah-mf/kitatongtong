import 'package:flutter/material.dart';
import '../pages/checkIn.dart';  // Import Check-In page
import '../pages/rewards.dart'; // Import Rewards page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/pickupItem.dart';

class UserPoints extends StatefulWidget {
  @override
  _UserPointsState createState() => _UserPointsState();
}

class _UserPointsState extends State<UserPoints> {
@override
Widget build(BuildContext context) {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      final userData = snapshot.data!.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'asnaf'; // Default to asnaf if not found

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            childAspectRatio: 1.5,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            shrinkWrap: true,
            children: [
              // First Box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      role == 'asnaf' ? Rewards() : pickUpItem(), // Replace Placeholder with actual PickupItemPage()
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      width: 180,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role == 'asnaf' ? "Points" : "Pickup Item",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              role == 'asnaf'
                                  ? Text(
                                "${userData['points'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                                  : SizedBox(),
                            ],
                          ),
                          Positioned(
                            top: 14,
                            right: 0,
                            child: Image.asset(
                              "assets/Smiley.png",
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Second Box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      role == 'asnaf' ? checkIn() : Placeholder(), // Replace with HelpAttendancePage()
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      width: 180,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role == 'asnaf' ? "Check-In Event" : "Help Attendance",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (role == 'asnaf')
                                  Text(
                                    "Earn points by confirming\nyour attendance",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              "assets/calendar.png",
                              height: 50,
                              width: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}}

