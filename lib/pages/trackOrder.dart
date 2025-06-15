import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../pages/redemptionStatus.dart';
import 'package:projects/localization/app_localizations.dart';

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
  String _selectedSort = "Date";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Stream<QuerySnapshot> _getOrdersStream(int tabIndex) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    Query query = FirebaseFirestore.instance
        .collection('redeemedKasih')
        .where('userId', isEqualTo: user.uid);

    switch (tabIndex) {
      case 1:
        query = query.where('processedOrder', isEqualTo: 'no');
        break;
      case 2:
        query = query
            .where('processedOrder', isEqualTo: 'yes')
            .where('pickedUp', isEqualTo: 'no');
        break;
      case 3:
        query = query.where('pickedUp', isEqualTo: 'yes');
        break;
    }

    if (_selectedSort == "Date") {
      query = query.orderBy('redeemedAt', descending: true);
    } else {
      query = query.orderBy('pickupCode');
    }

    return query.snapshots();
  }

  List<DocumentSnapshot> _filterDocsBySearch(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      return docs;
    }
    return docs.where((doc) {
      final code = (doc['pickupCode'] as String? ?? '').toLowerCase();
      return code.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final sortItems = {
      "Date": localizations.translate('track_order_sort_date'),
      "Code": localizations.translate('track_order_sort_code'),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303030),
        elevation: 0,
        title: Text(
          localizations.translate('track_order_title'),
          style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDB515),
          labelColor: const Color(0xFFFDB515),
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: localizations.translate('track_order_tab_all')),
            Tab(text: localizations.translate('track_order_tab_to_process')),
            Tab(text: localizations.translate('track_order_tab_to_pickup')),
            Tab(text: localizations.translate('track_order_tab_completed')),
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
                        hintText: localizations.translate('track_order_search_hint'),
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
                    items: sortItems.keys
                        .map((s) => DropdownMenuItem(value: s, child: Text(sortItems[s]!)))
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
                  stream: _getOrdersStream(tabIndex),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(localizations.translateWithArgs('track_order_fetch_error', {'error': snapshot.error.toString()}), style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(localizations.translate('track_order_no_orders_found'), style: const TextStyle(color: Colors.white70)));
                    }
                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);
                    if (displayDocs.isEmpty) {
                      return Center(
                          child: Text(
                            "${localizations.translate('track_order_no_orders_in_category')}${_searchQuery.isNotEmpty ? localizations.translate('track_order_matching_search') : ''}.",
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        final orderDoc = displayDocs[index];
                        return _OrderCard(orderDoc: orderDoc);
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
}

class _OrderCard extends StatelessWidget {
  final DocumentSnapshot orderDoc;

  const _OrderCard({Key? key, required this.orderDoc}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final data = orderDoc.data()! as Map<String, dynamic>;
    final dateFormat = DateFormat("dd MMM kk:mm a");
    final date = data['redeemedAt'] != null
        ? dateFormat.format((data['redeemedAt'] as Timestamp).toDate())
        : localizations.translate('track_order_no_date');
    final code = data['pickupCode'] ?? localizations.translate('track_order_not_applicable');
    final processedOrder = data['processedOrder'] ?? 'no';
    final pickedUp = data['pickedUp'] ?? 'no';

    String statusText;
    Color statusColor;
    bool showQrCode = (processedOrder == 'yes' && pickedUp == 'no');

    if (pickedUp == 'yes') {
      statusText = localizations.translate('track_order_status_completed');
      statusColor = Colors.green;
    } else if (processedOrder == 'yes') {
      statusText = localizations.translate('track_order_status_ready_for_pickup');
      statusColor = Colors.orangeAccent;
    } else {
      statusText = localizations.translate('track_order_status_to_process');
      statusColor = Colors.blueAccent;
    }

    final List<dynamic> itemsRedeemed = data['itemsRedeemed'] ?? [];
    bool isHamper = false;
    String hamperName = '';
    String hamperImageUrl = '';

    if (itemsRedeemed.isNotEmpty && itemsRedeemed.first is Map) {
      final firstItem = itemsRedeemed.first as Map<String, dynamic>;
      if (firstItem['category'] == 'Hamper' || firstItem['category'] == localizations.translate('track_order_hamper_category')) {
        isHamper = true;
        hamperName = firstItem['name'] ?? localizations.translate('track_order_hamper_category');
        hamperImageUrl = firstItem['imageUrl'] ?? '';
      }
    }

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RedemptionStatus(documentId: orderDoc.id)),
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
                    Text(localizations.translateWithArgs('track_order_pickup_code_label', {'code': code}),
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(date,
                            style:
                            TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                    const Divider(
                        color: Colors.white24, height: 20, thickness: 0.5),

                    if (isHamper)
                      _buildHamperView(context, hamperName, hamperImageUrl)
                    else
                      ...itemsRedeemed.map((item) {
                        if (item is Map<String, dynamic>) {
                          return _buildItemDetailRow(context, item);
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

  Widget _buildHamperView(BuildContext context, String name, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemDetailRow(context, {'name': name, 'imageUrl': imageUrl}),
        const Divider(color: Colors.white12, height: 15, thickness: 0.5, indent: 60, endIndent: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchHamperItems(name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(left: 62.0, top: 8.0),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final hamperContents = snapshot.data!;
            return Column(
              children: hamperContents.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> item = entry.value;
                return _buildItemDetailRow(context, item, isSubItem: true, index: idx);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildItemDetailRow(BuildContext context, Map<String, dynamic> item, {bool isSubItem = false, int? index}) {
    final localizations = AppLocalizations.of(context);
    final String name = item['name'] ?? localizations.translate('track_order_unknown_item');

    if (isSubItem) {
      return Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index! + 1}.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                progress == null
                    ? child
                    : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                errorBuilder: (context, error, stack) =>
                    Icon(Icons.broken_image, color: Colors.grey[500]),
              )
                  : Container(
                color: Colors.grey[800],
                child: Icon(Icons.shopping_basket, color: Colors.grey[500]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
