import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedSort = "Date"; // Default sort option

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Add a listener to the search controller to update the UI on text change
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

  // --- OPTIMIZATION 1: Create a function to build Firestore queries dynamically ---
  // This function creates a specific query for each tab and sorting option.
  // This ensures we only fetch the necessary documents from Firestore.
  Stream<QuerySnapshot> _getOrdersStream(int tabIndex) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('redeemedKasih')
        .where('userId', isEqualTo: user.uid);

    // Apply filters based on the selected tab
    switch (tabIndex) {
      case 1: // To Process
        query = query.where('processedOrder', isEqualTo: 'no');
        break;
      case 2: // To Pickup
        query = query
            .where('processedOrder', isEqualTo: 'yes')
            .where('pickedUp', isEqualTo: 'no');
        break;
      case 3: // Completed
        query = query.where('pickedUp', isEqualTo: 'yes');
        break;
    // Case 0 (All) doesn't need an additional filter.
    }

    // Apply sorting based on the user's selection
    // Note: You may need to create corresponding indexes in your Firestore console.
    if (_selectedSort == "Date") {
      query = query.orderBy('redeemedAt', descending: true);
    } else {
      query = query.orderBy('pickupCode');
    }

    return query.snapshots();
  }

  // --- OPTIMIZATION 2: Simplify the filtering function ---
  // This function now only needs to handle the search, as the main filtering
  // and sorting are done by the highly efficient Firestore query.
  List<DocumentSnapshot> _filterDocsBySearch(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      return docs; // Return the list as is if search is empty
    }

    // Filter the already limited list of documents by the search query
    return docs.where((doc) {
      final code = (doc['pickupCode'] as String? ?? '').toLowerCase();
      return code.contains(_searchQuery);
    }).toList();
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
            Tab(text: "To Pickup"),
            Tab(text: "Completed"),
          ],
          // We add a listener to the tab controller itself for state changes
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
                    // When sort option changes, call setState to trigger a rebuild
                    // which will use the new sort order in the Firestore query.
                    onChanged: (v) {
                      if (v != null && mounted) setState(() => _selectedSort = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // --- OPTIMIZATION 3: Use a separate StreamBuilder for each tab ---
            // This ensures each tab has its own dedicated, optimized data stream.
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                return StreamBuilder<QuerySnapshot>(
                  // Get the specific stream for the current tab and sort option
                  stream: _getOrdersStream(tabIndex),
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

                    // Perform the client-side search on the much smaller, pre-filtered list
                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);

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

  // --- NO CHANGES NEEDED BELOW THIS LINE ---
  // The UI logic for building each card remains the same.

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
              if (showQrCode)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: QrImageView(
                    data: code,
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