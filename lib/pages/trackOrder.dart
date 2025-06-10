import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import the QR package
import '../pages/redemptionStatus.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({Key? key}) : super(key: key);

  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen>
    with SingleTickerProviderStateMixin {
  int _bottomNavSelectedIndex = 1;
  late TabController _tabController;
  late Stream<QuerySnapshot> _ordersStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedSort = "Date";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('redeemedKasih')
          .where('userId', isEqualTo: user.uid)
          .orderBy('redeemedAt', descending: true)
          .snapshots();
    } else {
      _ordersStream = Stream.empty();
    }
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavItemTapped(int index) {
    if (mounted) {
      setState(() {
        _bottomNavSelectedIndex = index;
      });
    }
  }

  List<DocumentSnapshot> _filterAndSortOrders(
      List<DocumentSnapshot> docs, int tabIndex) {
    List<DocumentSnapshot> filteredByTab;

    switch (tabIndex) {
      case 0:
        filteredByTab = docs;
        break;
      case 1:
        filteredByTab = docs.where((doc) => (doc['processedOrder'] ?? 'no') == 'no').toList();
        break;
      case 2:
      // "Processed" tab: processed but not yet picked up
        filteredByTab = docs.where((doc) => (doc['processedOrder'] ?? 'no') == 'yes' && (doc['pickedUp'] ?? 'no') == 'no').toList();
        break;
      case 3:
        filteredByTab = docs.where((doc) => (doc['pickedUp'] ?? 'no') == 'yes').toList();
        break;
      default:
        filteredByTab = docs;
    }

    if (_searchQuery.isNotEmpty) {
      filteredByTab = filteredByTab.where((doc) {
        final code = (doc['pickupCode'] as String? ?? '').toLowerCase();
        return code.contains(_searchQuery);
      }).toList();
    }

    // Sorting logic remains the same
    if (_selectedSort == "Code") {
      filteredByTab.sort((a, b) {
        final codeA = a['pickupCode'] as String? ?? '';
        final codeB = b['pickupCode'] as String? ?? '';
        return codeA.compareTo(codeB);
      });
    }
    return filteredByTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303030),
        elevation: 0,
        title: const Text(
          "Track Order",
          style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDB515),
          labelColor: const Color(0xFFFDB515),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "To Process"),
            Tab(text: "To Pickup"), // Changed from "Processed"
            Tab(text: "Completed"), // Changed from "Rating"
          ],
          onTap: (index) {
            if (mounted) setState(() {});
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by Pickup Code",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  height: 45,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.grey[800],
                    icon: const Icon(Icons.sort, color: Colors.white70),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: ["Date", "Code"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null && mounted) setState(() => _selectedSort = v);
                    },

                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _ordersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No orders found.", style: TextStyle(color: Colors.white70)));
                    }

                    final allDocs = snapshot.data!.docs;
                    final displayDocs = _filterAndSortOrders(allDocs, tabIndex);

                    if (displayDocs.isEmpty) {
                      return Center(
                          child: Text(
                            "No orders in this category${_searchQuery.isNotEmpty ? ' matching your search' : ''}.",
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        final orderDoc = displayDocs[index];
                        return _buildOrderCard(orderDoc);
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _bottomNavSelectedIndex,
        onItemTapped: _onBottomNavItemTapped,
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot orderDoc) {
    final data = orderDoc.data()! as Map<String, dynamic>;
    final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");
    final date = data['redeemedAt'] != null
        ? dateFormat.format((data['redeemedAt'] as Timestamp).toDate())
        : 'No date';
    final code = data['pickupCode'] ?? 'N/A';
    final processedOrder = data['processedOrder'] ?? 'no';
    final pickedUp = data['pickedUp'] ?? 'no';

    String statusText;
    Color statusColor;
    // Condition to show QR code
    bool showQrCode = (processedOrder == 'yes' && pickedUp == 'no');

    if (pickedUp == 'yes') {
      statusText = 'Completed';
      statusColor = Colors.green;
    } else if (processedOrder == 'yes') {
      statusText = 'Ready for Pickup';
      statusColor = Colors.orangeAccent;
    } else {
      statusText = 'To Process';
      statusColor = Colors.blueAccent;
    }

    final List<dynamic> itemsRedeemed = data['itemsRedeemed'] ?? [];

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RedemptionStatus(documentId: orderDoc.id)),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pickup Code: $code", style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20, thickness: 0.5),
                    ...itemsRedeemed.map((item) {
                      if (item is Map<String, dynamic>) {
                        return _buildItemDetailRow(item);
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ],
                ),
              ),
              // Show QR code only if the condition is met
              if (showQrCode)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: QrImageView(
                    data: code, // The data for the QR code
                    version: QrVersions.auto,
                    size: 80.0,
                    backgroundColor: Colors.white,
                    gapless: false,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailRow(Map<String, dynamic> item) {
    final String name = item['name'] ?? 'Unknown Item';
    final String? imageUrl = item['imageUrl'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorBuilder: (context, error, stack) => Icon(Icons.broken_image, color: Colors.grey[500]),
              )
                  : Icon(Icons.image_not_supported, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
