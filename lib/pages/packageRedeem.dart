import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successRedeem.dart';
import 'dart:math';

class PackageRedeemPage extends StatefulWidget {
  final String bannerUrl;
  final String packageLabel;
  final int rmValue;
  final int validityDays;
  final List<dynamic> items;
  final Map<String, dynamic>? voucherReceived;

  const PackageRedeemPage({
    required this.bannerUrl,
    required this.packageLabel,
    required this.rmValue,
    required this.validityDays,
    required this.items,
    this.voucherReceived,
  });

  @override
  _PackageRedeemPageState createState() => _PackageRedeemPageState();
}

class _PackageRedeemPageState extends State<PackageRedeemPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add logic for navigation if needed
  }
  String generatePickupCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> redeemVoucher() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = Timestamp.now();
    final pickupCode = generatePickupCode(8);

    // Retrieve the user's document
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'Unknown';
    final totalValuePoints = userData?['totalValuePoints'] ?? 0;
    final updatedPoints = totalValuePoints - widget.rmValue;

    // Prepare the redeemed item list if needed.
    final itemList = [];

    // Create the redeemedKasih record.
    await FirebaseFirestore.instance.collection('redeemedKasih').add({
      'userId': user.uid,
      'userName': userName,
      'valueRedeemed': widget.rmValue,
      'pickupCode': pickupCode,
      'itemRedeemed': itemList,
      'pickedUp': 'no',
      'processedOrder': 'no',
      'redeemedAt': now,
    });

    // Update the total value points.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'totalValuePoints': updatedPoints});

    // Remove the voucher from the user's voucherReceived array.
    if (widget.voucherReceived != null && widget.voucherReceived!.containsKey('voucherId')) {
      final targetVoucherId = widget.voucherReceived!['voucherId'];
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot userSnap = await userRef.get();
      if (userSnap.exists) {
        final data = userSnap.data() as Map<String, dynamic>;
        // Assume voucherReceived is stored as a List.
        List<dynamic> vouchers = data['voucherReceived'] is List
            ? List<dynamic>.from(data['voucherReceived'])
            : [];
        vouchers.removeWhere((voucher) {
          return (voucher is Map && voucher['voucherId'] == targetVoucherId);
        });
        await userRef.update({'voucherReceived': vouchers});
      }
    }

    // Navigate to the Successredeem screen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Successredeem()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF303030),
        body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Banner Image at top
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.bannerUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 140,
                ),
              ),
              SizedBox(height: 20),

              // Golden Info Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.16, 0.38, 0.58, 0.88],
                    colors: [
                      Color(0xFFF9F295),
                      Color(0xFFE0AA3E),
                      Color(0xFFF9F295),
                      Color(0xFFB88A44),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Package ${widget.packageLabel}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA67C00),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      "Validity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67C00),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${widget.validityDays} Days",
                      style: TextStyle(fontSize: 14, color: Color(0xFFA67C00)),
                    ),
                    SizedBox(height: 12),

                    Text(
                      "Value",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67C00),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "RM${widget.rmValue}",
                      style: TextStyle(fontSize: 14, color: Color(0xFFA67C00)),
                    ),
                    SizedBox(height: 12),

                    Text(
                      "What's inside",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67C00),
                      ),
                    ),
                    SizedBox(height: 4),
                    ...List.generate(widget.items.length, (i) {
                      final item = widget.items[i];
                      return Text(
                        "${i + 1}. ${item['name']} ${item['unit']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF303030),
                        ),
                      );
                    }),
                    SizedBox(height: 16),

                    Text(
                      "Terms and Conditions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA67C00),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "1. Only registered users of the Kita Tongtong app are eligible to redeem this package.\n"
                          "2. The package is limited to individuals or families verified as eligible for assistance under the 'fakir' or 'miskin' categories.\n"
                          "3. The package includes:\n" +
                          widget.items.asMap().entries.map((entry) {
                            return "   ${entry.key + 1}. ${entry.value['name']} ${entry.value['unit']}";
                          }).join('\n') +
                          "\n4. Items in the package are non-exchangeable and cannot be substituted with other products.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF303030),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Redeem button in PackageRedeem.dart
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: redeemVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Redeem",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

