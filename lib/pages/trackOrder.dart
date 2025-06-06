// lib/pages/trackOrder.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
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

  // Cache for item image URLs to avoid repeated Firestore reads.
  // Key: Item Name, Value: Image URL
  final Map<String, String> _itemImageCache = {};

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

  // NEW FUNCTION: Fetches an item's image URL from package_kasih by matching the item name.
  Future<String?> _fetchItemImageUrl(Map<String, dynamic> item) async {
    final String itemName = item['name'];
    if (_itemImageCache.containsKey(itemName)) {
      return _itemImageCache[itemName]; // Return from cache
    }

    try {
      // Find the package that contains this exact item in its 'items' array.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('package_kasih')
          .where('items', arrayContains: item) // Match the exact item map
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final bannerUrl = doc.data()['bannerUrl'] as String?;
        if (bannerUrl != null) {
          _itemImageCache[itemName] = bannerUrl; // Save to cache
          return bannerUrl;
        }
      }
    } catch (e) {
      print("Error fetching image URL for $itemName: $e");
    }
    return null; // Return null if not found or on error
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
        filteredByTab = docs.where((doc) => (doc['processedOrder'] ?? 'no') == 'yes' && (doc['pickedUp'] ?? 'no') == 'no').toList();
        break;
      case 3:
        filteredByTab = docs.where((doc) => (doc['processedOrder'] ?? 'no') == 'yes' && (doc['pickedUp'] ?? 'no') == 'yes').toList();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDB515),
          labelColor: const Color(0xFFFDB515),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "To Process"),
            Tab(text: "Processed"),
            Tab(text: "Rating"),
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
                        return _buildOrderCard(orderDoc, tabIndex);
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

  // --- WIDGETS REBUILT TO SHOW MULTIPLE ITEMS ---

  // Main Order Card Widget
  Widget _buildOrderCard(DocumentSnapshot orderDoc, int currentTabIndex) {
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
    if (processedOrder == 'yes' && pickedUp == 'yes') {
      statusText = 'Completed';
      statusColor = Colors.green;
    } else if (processedOrder == 'yes') {
      statusText = 'Processed, Awaiting Pickup';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order-level details
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

              // List of items
              ...itemsRedeemed.map((item) {
                // Ensure item is a Map before passing
                if (item is Map<String, dynamic>) {
                  return _buildItemDetailRow(item);
                }
                return const SizedBox.shrink(); // Return empty widget if format is wrong
              }).toList(),

              if (currentTabIndex == 3 && statusText == 'Completed')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to rate order: $code')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDB515),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12, color: Color(0xFF303030)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Rate Order", style: TextStyle(color: Color(0xFF303030), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // New Widget for displaying a single item row
  Widget _buildItemDetailRow(Map<String, dynamic> item) {
    final String name = item['name'] ?? 'Unknown Item';
    final double price = (item['price'] as num? ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Image with FutureBuilder
          SizedBox(
            width: 60,
            height: 60,
            child: FutureBuilder<String?>(
              future: _fetchItemImageUrl(item),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))))));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.image_not_supported, color: Colors.grey[500], size: 30),
                  );
                }
                final imageUrl = snapshot.data!;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.broken_image, color: Colors.grey[500], size: 30)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Item Name and Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "RM ${price.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}