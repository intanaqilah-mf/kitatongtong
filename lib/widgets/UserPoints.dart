import 'package:flutter/material.dart';
import '../pages/checkIn.dart';
import '../pages/rewards.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/pickupItem.dart';
import 'package:projects/localization/app_localizations.dart';

class UserPoints extends StatefulWidget {
  @override
  _UserPointsState createState() => _UserPointsState();
}

class _UserPointsState extends State<UserPoints> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'asnaf';
        final localizations = AppLocalizations.of(context);

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
                        role == 'asnaf' ? Rewards() : PickUpItem(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 76,
                        width: 180,
                        margin:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                                  role == 'asnaf'
                                      ? localizations.translate('userpoints_points')
                                      : localizations.translate('userpoints_pickup_item'),
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
                        builder: (context) => checkIn(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 76,
                        width: 180,
                        margin:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                                    role == 'asnaf'
                                        ? localizations.translate('userpoints_checkin_event')
                                        : localizations.translate('userpoints_help_attendance'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (role == 'asnaf')
                                    Text(
                                      localizations.translate('userpoints_checkin_description'),
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
  }
}