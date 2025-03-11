import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationStatusPage extends StatefulWidget {
  @override
  _ApplicationStatusPageState createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  String? _applicationCode; // Store applicationCode

  @override
  void initState() {
    super.initState();
    _fetchApplicationCode(); // Fetch the applicationCode when the page loads
  }

  Future<void> _fetchApplicationCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _applicationCode = snapshot.docs.first.data()['applicationCode'] ?? "UNKNOWN";
      });
    } else {
      setState(() {
        _applicationCode = "UNKNOWN";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _applicationCode == null
          ? Center(child: CircularProgressIndicator()) // Show loading until we fetch applicationCode
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('applicationCode', isEqualTo: _applicationCode) // Now _applicationCode is valid
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No application found.", style: TextStyle(color: Colors.red)));
          }

          var data = snapshot.data!.docs.first;
          Map<String, dynamic> applicationData = data.data() as Map<String, dynamic>;

          String fullName = applicationData['fullname'] ?? "Unknown";
          String appCode = applicationData['applicationCode'] ?? "N/A";
          String statusApplication = applicationData['statusApplication'] ?? "Submitted";
          bool hasReward = applicationData.containsKey('reward') && applicationData['reward'] != null;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 25, horizontal: 16), // Increased vertical padding
                child: Column(
                  children: [
                    SizedBox(height: 10), // Moves the title lower
                    Text(
                      "Application Status",
                      style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20), // Adds more space before Full Name & Application Code
                    Text(
                      "Full Name: $fullName",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Application Code: $appCode",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              statusTile(
                  "Application Submitted",
                  "We received your application.",
                  "assets/applicationStatus1.png",
                  getStatusColor(1, statusApplication, hasReward),
                  true),
              statusTile(
                  "Under Review",
                  "Admin is reviewing your application.",
                  "assets/applicationStatus2.png",
                  getStatusColor(2, statusApplication, hasReward),
                  true),
              statusTile(
                  "Completed",
                  "Your application has been accepted.",
                  "assets/applicationStatus3.png",
                  getStatusColor(3, statusApplication, hasReward),
                  false),
            ],
          );
        },
      ),
    );
  }

  Color getStatusColor(int stage, String statusApplication, bool hasReward) {
    if (stage == 1) return Colors.green; // Always green for submitted
    if (stage == 2) {
      if (statusApplication == "Pending") return Colors.grey;
      if (statusApplication == "Rejected") return Colors.red;
      if (statusApplication == "Approved") return Colors.green;
    }
    if (stage == 3) {
      return hasReward ? Colors.green : Colors.grey; // Grey if reward doesn't exist
    }
    return Colors.grey;
  }

  Widget statusTile(String title, String subtitle, String iconPath, Color timelineColor, bool showLine) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Moves text slightly higher
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Aligns timeline and icon properly
        children: [
          Column(
            children: [
              Container(
                width: 60,
                height: 25,
                decoration: BoxDecoration(
                  color: timelineColor, // Colored based on status
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(
                  width: 3, // Thicker timeline line
                  height: 70, // Adjust height to match icon center
                  color: timelineColor,
                ),
            ],
          ),
          SizedBox(width: 15), // Adjust spacing between timeline and icon
          Image.asset(iconPath, width: 45, height: 45), // Slightly bigger icons for balance
          SizedBox(width: 15), // Adjust spacing between icon and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDB515),
                    fontSize: 16, // Adjusted for better alignment
                  ),
                ),
                SizedBox(height: 10), // Moves the text slightly higher
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
