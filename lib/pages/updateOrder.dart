import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/reviewUpdateOrder.dart'; // Assuming this page exists for navigation after submission

class UpdateOrder extends StatefulWidget {
  final String documentId;

  UpdateOrder({required this.documentId});

  @override
  _UpdateOrderState createState() => _UpdateOrderState();
}

class _UpdateOrderState extends State<UpdateOrder> {
  int _selectedIndex = 0;
  String _processedStatus = "no"; // Default status

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<DocumentSnapshot> _fetchOrderData() {
    return FirebaseFirestore.instance.collection('redeemedKasih').doc(widget.documentId).get();
  }

  Future<DocumentSnapshot> _fetchUserData(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  Future<List<Map<String, dynamic>>> _fetchHamperItems(String hamperName) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('package_hamper')
        .where('name', isEqualTo: hamperName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('package_kasih')
          .where('name', isEqualTo: hamperName)
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      final hamperData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      if (hamperData['items'] != null && hamperData['items'] is List) {
        return List<Map<String, dynamic>>.from(hamperData['items']);
      }
    }
    return [];
  }

  void _submitStatus() async {
    final loc = AppLocalizations.of(context);
    if (_processedStatus == "no") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('update_order_select_yes_prompt'))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('redeemedKasih')
          .doc(widget.documentId)
          .update({'processedOrder': 'yes'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('update_order_success_message'))),
      );

      // Navigate back or to a review screen
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translateWithArgs('update_order_failure_message', {'error': e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: Text(
          loc.translate('process_order_title'),
          style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF303030),
        iconTheme: IconThemeData(color: Color(0xFFFDB515)),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchOrderData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(loc.translate('update_order_no_data'), style: TextStyle(color: Colors.white70)));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final userId = orderData['userId'];

          return FutureBuilder<DocumentSnapshot>(
            future: _fetchUserData(userId),
            builder: (context, userSnapshot) {
              String photoUrl = "";
              if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                photoUrl = userData['photoUrl'] ?? "";
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUserInfoCard(context, orderData, photoUrl),
                    const SizedBox(height: 16),
                    _buildItemsCard(context, orderData),
                    const SizedBox(height: 24),
                    _buildActionSection(context),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, Map<String, dynamic> data, String photoUrl) {
    final loc = AppLocalizations.of(context);
    final userName = data['userName'] ?? loc.translate('orderProcessed_unknown_user');
    final pickupCode = data['pickupCode'] ?? 'N/A';
    final applicationCode = data['applicationCode']; // This can be null
    final valueRedeemed = data['valueRedeemed'] ?? 0;
    final redeemedAt = data['redeemedAt'] as Timestamp?;
    final formattedDate = redeemedAt != null
        ? DateFormat("dd MMM yyyy, kk:mm a").format(redeemedAt.toDate())
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F295), Color(0xFFE0AA3E), Color(0xFFB88A44)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.white70) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black26, height: 24, thickness: 1),
          _buildInfoRow(loc.translate('update_order_pickup_code_label'), pickupCode),
          if (applicationCode != null) _buildInfoRow(loc.translate('update_order_application_code'), applicationCode),
          _buildInfoRow(loc.translate('update_order_value_redeemed'), 'RM${valueRedeemed.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, Map<String, dynamic> data) {
    final loc = AppLocalizations.of(context);
    final List<dynamic> itemsRedeemed = data['itemsRedeemed'] ?? [];

    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('update_order_items_redeemed'),
              style: TextStyle(color: Color(0xFFFDB515), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white24, height: 16),
            if (itemsRedeemed.isEmpty)
              Text(loc.translate('update_order_no_items'), style: TextStyle(color: Colors.white70)),
            ...itemsRedeemed.map((item) {
              if (item is Map<String, dynamic>) {
                final isHamper = item['category'] == 'Hamper' || item['category'] == loc.translate('track_order_hamper_category');
                if (isHamper) {
                  return _buildHamperView(context, item['name'], item['imageUrl']);
                }
                return _buildItemDetailRow(context, item);
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHamperView(BuildContext context, String name, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemDetailRow(context, {'name': name, 'imageUrl': imageUrl}),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchHamperItems(name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(left: 62.0, top: 8.0, bottom: 8.0),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515)))),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final hamperContents = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12, height: 1, thickness: 0.5, indent: 45),
                  ...hamperContents.asMap().entries.map((entry) {
                    return _buildItemDetailRow(context, entry.value, isSubItem: true, index: entry.key);
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemDetailRow(BuildContext context, Map<String, dynamic> item, {bool isSubItem = false, int? index}) {
    final loc = AppLocalizations.of(context);
    final String name = item['name'] ?? loc.translate('track_order_unknown_item');

    if (isSubItem) {
      return Padding(
        padding: const EdgeInsets.only(left: 45.0, top: 6, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index! + 1}.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final String? imageUrl = item['imageUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], child: Icon(Icons.shopping_basket, color: Colors.grey[500])),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('update_order_prompt'), style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _processedStatus,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFDB515)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: [
                DropdownMenuItem<String>(value: "no", child: Text(loc.translate('update_order_dropdown_no'))),
                DropdownMenuItem<String>(value: "yes", child: Text(loc.translate('update_order_dropdown_yes'))),
              ],
              onChanged: (newValue) {
                setState(() {
                  _processedStatus = newValue!;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDB515),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              loc.translate('submit_button_text'),
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
