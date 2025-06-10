import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RedemptionStatus extends StatefulWidget {
  final String documentId;
  const RedemptionStatus({Key? key, required this.documentId}) : super(key: key);

  @override
  _RedemptionStatusPageState createState() => _RedemptionStatusPageState();
}

class _RedemptionStatusPageState extends State<RedemptionStatus> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        title: Text("Pickup Status", style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF303030),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redeemedKasih')
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFFDB515)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Order not found.", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final pickupCode = data['pickupCode'] ?? 'N/A';
          final userName = data['userName'] ?? 'User';
          final isProcessed = (data['processedOrder'] ?? 'no') == 'yes';
          final isPickedUp = (data['pickedUp'] ?? 'no') == 'yes';

          bool showQrCode = isProcessed && !isPickedUp;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderInfo("Pickup Code", "#$pickupCode"),
                      _buildHeaderInfo("Full Name", userName, isRightAligned: true),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // QR Code Display
                if (showQrCode)
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: pickupCode,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Show this QR to the staff for pickup",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),

                // Timeline
                _buildStatusTimeline(isPlaced: true, isProcessed: isProcessed, isReady: isPickedUp),

                SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFDB515),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: Text("OK", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }

  Widget _buildHeaderInfo(String title, String value, {bool isRightAligned = false}) {
    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // A more robust timeline builder that matches the screenshot
  Widget _buildStatusTimeline({required bool isPlaced, required bool isProcessed, required bool isReady}) {
    return Column(
      children: [
        _buildTimelineNode(
          icon: Icons.shopping_cart_checkout,
          title: "Order Placed",
          subtitle: "We have received your order.",
          isActive: isPlaced,
          isFirst: true,
        ),
        _buildTimelineConnector(isActive: isProcessed),
        _buildTimelineNode(
          icon: Icons.inventory_2_outlined,
          title: "Order Processed",
          subtitle: "We are processing your order.",
          isActive: isProcessed,
        ),
        _buildTimelineConnector(isActive: isReady),
        _buildTimelineNode(
          icon: Icons.storefront_outlined,
          title: "Ready to Pickup",
          subtitle: "Your order is ready to pickup.",
          isActive: isReady,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineNode({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Dot and Line Column
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.grey[700],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive ? Colors.green : Colors.grey[700],
                  ),
                ),
            ],
          ),
          SizedBox(width: 20),
          // Icon and Text Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30.0), // Space between timeline items
              child: Row(
                children: [
                  Icon(icon, color: isActive ? Color(0xFFFDB515) : Colors.grey[600], size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isActive ? Colors.grey[300] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This is a simplified connector for the visual timeline. The main logic is in the node.
  Widget _buildTimelineConnector({required bool isActive}) {
    // This widget is no longer needed as the line is part of the node now.
    // Kept for clarity in case you want to separate it again.
    return SizedBox.shrink();
  }
}
