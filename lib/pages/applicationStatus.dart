// lib/pages/applicationStatus.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/HomePage.dart';

class ApplicationStatusPage extends StatefulWidget {
  final String documentId;
  const ApplicationStatusPage({Key? key, required this.documentId})
      : super(key: key);

  @override
  _ApplicationStatusPageState createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(
              child: Text(
                "No application found.",
                style: TextStyle(color: Colors.red),
              ),
            );

          final data = snapshot.data!.data()! as Map<String, dynamic>;
          final fullName = data['fullname'] ?? "Unknown";
          final appCode = data['applicationCode'] ?? "N/A";
          final statusApplication = data['statusApplication'] ?? "Submitted";
          final statusReward = data['statusReward'] as String?;

          // colors for each stage
          final color1 = _getStatusColor(stage: 1, statusApp: statusApplication, statusReward: statusReward);
          final color2 = _getStatusColor(stage: 2, statusApp: statusApplication, statusReward: statusReward);
          final color3 = _getStatusColor(stage: 3, statusApp: statusApplication, statusReward: statusReward);

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 25, horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Text(
                      "Application Status",
                      style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "Application Code",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "#$appCode",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "Full Name",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                fullName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Color(0xFF303030),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),

              // Stage 1: Submitted (connector always green)
              statusTile(
                title: "Application Submitted",
                subtitle: "We received your application.",
                iconPath: "assets/applicationStatus1.png",
                circleColor: color1,
                showLine: true,
                lineColor: color1, // CONNECTOR to next ALWAYS green
              ),

              // Stage 2: Completed
              statusTile(
                title: "Completed",
                subtitle: statusApplication == "Disapprove"
                    ? "Your application was rejected."
                    : "Your application has been accepted.",
                iconPath: "assets/applicationStatus3.png",
                circleColor: color2,
                showLine: true,
                lineColor: color3, // CONNECTOR follows reward status
              ),

              // Stage 3: Rewards Issued
              statusTile(
                title: "Rewards Issued",
                subtitle: statusReward == "Issued"
                    ? "Your reward has been issued."
                    : "Pending reward issuance.",
                iconPath: "assets/reward.png",
                circleColor: color3,
                showLine: false,
              ),

              SizedBox(height: 100),

              // OK button full-width
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFDB515),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(fontSize: 16, color: Colors.white),
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

  Color _getStatusColor({
    required int stage,
    required String statusApp,
    required String? statusReward,
  }) {
    if (stage == 1) {
      return Colors.green;
    }
    if (stage == 2) {
      if (statusApp == "Disapprove") return Colors.red;
      if (statusApp == "Approve" || statusApp == "Approved") return Colors.green;
      return Colors.grey;
    }
    // stage == 3
    if (statusApp == "Disapprove") {
      return Colors.red;
    }
    if (statusReward == "Issued") {
      return Colors.green;
    }
    return Colors.grey;
  }

  Widget statusTile({
    required String title,
    required String subtitle,
    required String iconPath,
    required Color circleColor,
    required bool showLine,
    Color? lineColor,
  }) {
    final connectorColor = lineColor ?? circleColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 65,
                height: 30,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(
                  width: 5,
                  height: 90,
                  color: connectorColor,
                ),
            ],
          ),
          SizedBox(width: 15),
          Image.asset(iconPath, width: 45, height: 45),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
