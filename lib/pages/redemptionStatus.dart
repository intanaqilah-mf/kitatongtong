// lib/pages/redemptionStatus.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/HomePage.dart';

class RedemptionStatus extends StatefulWidget {
  final String documentId;
  const RedemptionStatus({Key? key, required this.documentId}) : super(key: key);

  @override
  _RedemptionStatusPageState createState() => _RedemptionStatusPageState();
}

class _RedemptionStatusPageState extends State<RedemptionStatus> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Color _dotColor(int stage, String processed, String pickedUp) {
    if (stage == 1) return Colors.green;
    if (stage == 2) return processed == 'yes' ? Colors.green : Colors.grey;
    // stage 3
    return pickedUp == 'yes' ? Colors.green : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redeemedKasih')
            .doc(widget.documentId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists)
            return Center(child: Text("No order found.", style: TextStyle(color: Colors.red)));

          final data = snap.data!.data()! as Map<String, dynamic>;
          final code = data['pickupCode'] ?? 'N/A';
          final name = data['userName'] ?? 'Unknown';
          final processed = data['processedOrder'] ?? 'no';
          final pickedUp = data['pickedUp'] ?? 'no';

          final c1 = _dotColor(1, processed, pickedUp);
          final c2 = _dotColor(2, processed, pickedUp);
          final c3 = _dotColor(3, processed, pickedUp);

          return Column(children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 25, horizontal: 16),
              child: Column(children: [
                SizedBox(height: 50),
                Text(
                  "Pickup Status",
                  style: TextStyle(color: Color(0xFFFDB515), fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text("Pickup Code", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("#$code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text("Full Name", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(name, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ]),
                SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Color(0xFF303030),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4, spreadRadius: 1, offset: Offset(0, 2))],
                  ),
                ),
                SizedBox(height: 50),
              ]),
            ),

            // Stage 1: Order Placed
            statusTile(
              "Order Placed",
              "We have received your order.",
              "assets/pickup1.png",
              c1,
              true,
              c2,
            ),

            // Stage 2: Order Processed
            statusTile(
              "Order Processed",
              "We are processing your order.",
              "assets/pickup2.png",
              c2,
              true,
              c3,
            ),

            // Stage 3: Ready to Pickup
            statusTile(
              "Ready to Pickup",
              "Your order is ready to pickup.",
              "assets/pickup3.png",
              c3,
              false,
              Colors.transparent,
            ),

            SizedBox(height: 100),

            // OK button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDB515),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("OK", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ]);
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }

  Widget statusTile(String title, String subtitle, String iconPath, Color dotColor, bool showLine, Color lineColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 65, height: 30, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          if (showLine) Container(width: 5, height: 90, color: lineColor),
        ]),
        SizedBox(width: 15),
        Image.asset(iconPath, width: 45, height: 45),
        SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: Color(0xFFFDB515), fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(subtitle, style: TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}
