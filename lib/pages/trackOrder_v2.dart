// lib/pages/trackOrder.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/redemptionStatus.dart';

class TrackOrderScreen extends StatefulWidget {
  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  int _selectedIndex = 1;
  late Stream<QuerySnapshot> _ordersStream;
  String selectedFilter = "All";
  String selectedSort = "Date";
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('redeemedKasih')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _ordersStream = const Stream.empty();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Column(children: [
              Text(
                "Track Order",
                style: TextStyle(
                  color: Color(0xFFFDB515),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                "Track orders you’ve redeemed.",
                style: TextStyle(
                  color: Color(0xFFAA820C),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          ),

          // SEARCH / FILTER / SORT (match VerifyApplications UI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
            child: Row(
              children: [
                SizedBox(
                  width: 145,
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      prefixIcon: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.16, 0.38, 0.58, 0.88],
                            colors: [
                              Color(0xFFF9F295),
                              Color(0xFFE0AA3E),
                              Color(0xFFF9F295),
                              Color(0xFFB88A44),
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(Icons.search_rounded, size: 25, color: Colors.white),
                      ),
                      hintText: "Search Code",
                      hintStyle: TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(width: 6),

                SizedBox(
                  width: 120,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.filter_list, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    },
                    items: ["All", "Pending", "Processed", "Pick Up"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child:
                          Text(value, style: TextStyle(color: Colors.black)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 8),

                // Sort dropdown
                SizedBox(
                  width: 90,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.sort, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (v) => setState(() => selectedSort = v!),
                    items: ["Date", "Code", "Status"]
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Center(child: Text(s, style: TextStyle(color: Colors.black))),
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          Divider(thickness: 1, color: Colors.white, indent: 10, endIndent: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty)
                  return Center(
                    child: Text("No orders found", style: TextStyle(color: Colors.white, fontSize: 16)),
                  );

                return ListView.builder(
                  itemCount: docs.length,
                  padding: EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()! as Map<String, dynamic>;

                    final date = data['redeemedAt'] != null
                        ? DateFormat("dd MMM yyyy").format((data['redeemedAt'] as Timestamp).toDate())
                        : 'No date';
                    final code = data['pickupCode'] ?? '—';
                    final processed = data['processedOrder'] ?? 'no';
                    final pickedUp  = data['pickedUp']      ?? 'no';

                    // → New: determine status text & color
                    String status;
                    Color statusColor;
                    if (processed == 'yes' && pickedUp == 'yes') {
                      status = 'Pick Up';
                      statusColor = Colors.green;
                    } else if (processed == 'yes') {
                      status = 'Processed';
                      statusColor = Colors.green;
                    } else {
                      status = 'Pending';
                      statusColor = Colors.orange;
                    }

                    // apply search & filter
                    if (selectedFilter != "All" && status != selectedFilter) return SizedBox.shrink();
                    if (searchQuery.isNotEmpty && !code.toLowerCase().contains(searchQuery)) return SizedBox.shrink();

                    return Card(
                      color: Colors.grey[850],
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RedemptionStatus(documentId: doc.id)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // top row: date, code, status
                              Row(
                                children: [
                                  Icon(Icons.circle, color: Colors.green, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "$date   #$code",
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                  Text(status, style: TextStyle(color: statusColor, fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 8),
                              // timeline row
                              Row(
                                children: [
                                  _buildStep("Placed",
                                      color: Colors.green,
                                      filled: true),
                                  _buildLine(color: processed == 'yes' ? Colors.green : Colors.grey),
                                  _buildStep("Processed",
                                      color: processed == 'yes' ? Colors.green : Colors.grey,
                                      filled: processed == 'yes'),
                                  _buildLine(color: pickedUp == 'yes' ? Colors.green : Colors.grey),
                                  _buildStep("Pickup",
                                      color: pickedUp == 'yes' ? Colors.green : Colors.grey,
                                      filled: pickedUp == 'yes'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );

              },
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

  Widget _buildStep(String label, {required Color color, required bool filled}) {
    return Column(
      children: [
        Icon(Icons.circle, size: 12, color: filled ? color : Colors.grey[700]),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: filled ? Colors.white : Colors.grey[600], fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildLine({required Color color}) {
    return Expanded(
      child: Container(height: 2, color: color, margin: EdgeInsets.symmetric(horizontal: 4)),
    );
  }
}
