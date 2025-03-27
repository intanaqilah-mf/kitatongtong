import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/HomePage.dart';

class Redemptionstatus extends StatefulWidget {
  @override
  _RedemptionstatusState createState() => _RedemptionstatusState();
}

class _RedemptionstatusState extends State<Redemptionstatus> {
  String? _pickupCode;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPickupCode(); // Fetch the applicationCode when the page loads
  }

  Future<void> _fetchPickupCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('redeemedKasih')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _pickupCode = snapshot.docs.first.data()['pickupCode'] ?? "UNKNOWN";
      });
    } else {
      setState(() {
        _pickupCode = "UNKNOWN";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pickupCode == null
          ? Center(child: CircularProgressIndicator()) // Show loading until we fetch applicationCode
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redeemedKasih')
            .where('pickupCode', isEqualTo: _pickupCode) // Now _applicationCode is valid
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No application found.", style: TextStyle(color: Colors.red)));
          }

          var data = snapshot.data!.docs.first;
          Map<String, dynamic> pickupData = data.data() as Map<String, dynamic>;

          String fullName = pickupData['userName'] ?? "Unknown";
          String appCode = pickupData['pickupCode'] ?? "N/A";
          String statusApplication = pickupData['statusApplication'] ?? "Submitted";
          bool hasReward = pickupData.containsKey('reward') && pickupData['reward'] != null;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 25, horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 50), // Moves title lower
                    Text(
                      "Pickup Status",
                      style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // Row for Application Code & Full Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Pickup Code",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                appCode,
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
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                    SizedBox(height: 15), // Space before divider
                    Container(
                      width: double.infinity,
                      height: 2, // Divider thickness
                      decoration: BoxDecoration(
                        color: Color(0xFF303030), // Divider color
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54, // Inner shadow effect
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(0, 2), // Adjust shadow for depth
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50), // Adds spacing after header
                  ],
                ),
              ),

              statusTile(
                  "Order Placed",
                  "We have received your order",
                  "assets/pickup1.png",
                  getStatusColor(1, statusApplication, hasReward),
                  true),
              statusTile(
                  "Order Processed",
                  "We are processing your order",
                  "assets/pickup2.png",
                  getStatusColor(2, statusApplication, hasReward),
                  true),
              statusTile(
                  "Ready to Pickup",
                  "Your order is ready to pickup",
                  "assets/pickup3.png",
                  getStatusColor(3, statusApplication, hasReward),
                  false),
              SizedBox(height: 100),
              ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDB515),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                child: Center(child: Text("OK", style: TextStyle(fontSize: 16, color: Colors.white))),
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

  Color getStatusColor(int stage, String statusApplication, bool hasReward) {
    if (stage == 1) return Colors.green; // Always green for submitted
    if (stage == 2) {
      if (statusApplication == "Pending") return Colors.grey;
      if (statusApplication == "Rejected") return Colors.red;
      if (statusApplication == "Approve") return Colors.green;
    }
    if (stage == 3) {
      return hasReward ? Colors.green : Colors.grey;
    }
    return Colors.grey;
  }

  Widget statusTile(String title, String subtitle, String iconPath, Color timelineColor, bool showLine) {
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
                  color: timelineColor, // Colored based on status
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(
                  width: 5, // Thicker timeline line
                  height: 90, // Adjust height to match icon center
                  color: timelineColor,
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDB515),
                    fontSize: 16,
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
