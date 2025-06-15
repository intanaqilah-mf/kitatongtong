import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/applicationStatus.dart';
import 'package:projects/pages/redemptionStatus.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TrackRewardsScreen extends StatefulWidget {
  const TrackRewardsScreen({Key? key}) : super(key: key);

  @override
  _TrackRewardsScreenState createState() => _TrackRewardsScreenState();
}

class _TrackRewardsScreenState extends State<TrackRewardsScreen>
    with SingleTickerProviderStateMixin {
  int _bottomNavSelectedIndex = 0;
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
    _tabController.addListener(() {
      if (mounted && _tabController.indexIsChanging) {
        setState(() {});
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

  Stream<QuerySnapshot> _getStreamForTab(int tabIndex) {
    if (tabIndex == 3) { // Redeemed Tab
      Query query = FirebaseFirestore.instance.collection('redeemedKasih');
      if (_selectedSort == "Date") {
        query = query.orderBy('redeemedAt', descending: true);
      } else {
        query = query.orderBy('pickupCode');
      }
      return query.snapshots();
    }

    Query query = FirebaseFirestore.instance.collection('applications');
    query = query.where('statusReward', whereIn: ['Pending', 'Issued', 'Redeemed']);

    switch (tabIndex) {
      case 0:
        break;
      case 1:
        query = query.where('statusReward', isEqualTo: 'Pending');
        break;
      case 2:
        query = query.where('statusReward', isEqualTo: 'Issued');
        break;
    }

    switch (_selectedSort) {
      case "Name":
        query = query.orderBy('fullname');
        break;
      case "Status":
        query = query.orderBy('statusReward');
        break;
      default:
        query = query.orderBy('date', descending: true);
        break;
    }
    return query.snapshots();
  }

  List<DocumentSnapshot> _filterDocsBySearch(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final code = (data['applicationCode'] as String? ?? data['pickupCode'] as String? ?? '').toLowerCase();
      final name = (data['fullname'] as String? ?? data['userName'] as String? ?? '').toLowerCase();
      return code.contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303030),
        elevation: 0,
        title: Text(localizations.translate('track_rewards_title'), style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDB515),
          labelColor: const Color(0xFFFDB515),
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: localizations.translate('rewards_tab_all')),
            Tab(text: localizations.translate('rewards_tab_pending')),
            Tab(text: localizations.translate('rewards_tab_issued')),
            Tab(text: localizations.translate('rewards_tab_redeemed')),
          ],
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
                        hintText: localizations.translate('rewards_search_hint'),
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    dropdownColor: Colors.grey[800],
                    icon: const Icon(Icons.sort, color: Colors.white70),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: ["Date", "Name", "Status"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(localizations.translate('applications_sort_${s.toLowerCase()}'))))
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
                  stream: _getStreamForTab(tabIndex),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
                    if (snapshot.hasError) return Center(child: Text(localizations.translateWithArgs('rewards_error_fetch', {'error': snapshot.error.toString()}), style: const TextStyle(color: Colors.white)));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(localizations.translate('rewards_no_items_found'), style: const TextStyle(color: Colors.white70)));

                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);
                    if (displayDocs.isEmpty) return Center(child: Text(localizations.translate('rewards_no_items_in_category') + (_searchQuery.isNotEmpty ? localizations.translate('rewards_matching_search') : '.'), style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        final doc = displayDocs[index];
                        if (tabIndex == 3) {
                          return _buildRedeemedOrderCard(context, doc);
                        } else {
                          return _buildApplicationCard(context, doc);
                        }
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _bottomNavSelectedIndex, onItemTapped: _onBottomNavItemTapped),
    );
  }

  Widget _buildApplicationCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final localizations = AppLocalizations.of(context);
    final fullname = data['fullname'] ?? localizations.translate('applications_no_name');
    final dateStr = data['date'] ?? '';
    final date = dateStr.isNotEmpty ? DateFormat("dd MMM yy").format(DateTime.parse(dateStr)) : localizations.translate('applications_no_date');
    final code = data['applicationCode'] ?? localizations.translate('applications_no_code');
    final statusReward = data['statusReward'] ?? 'N/A';
    final rewardValue = data['reward'] as String?;

    Color statusColor;
    switch(statusReward) {
      case 'Issued': statusColor = Colors.green; break;
      case 'Pending': statusColor = Colors.orangeAccent; break;
      case 'Redeemed': statusColor = Colors.blueAccent; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationStatusPage(documentId: doc.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(fullname, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (statusReward == 'Issued' && rewardValue != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        rewardValue,
                        style: const TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$date   $code", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(statusReward, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemedOrderCard(BuildContext context, DocumentSnapshot orderDoc) {
    final localizations = AppLocalizations.of(context);
    final data = orderDoc.data()! as Map<String, dynamic>;
    final dateFormat = DateFormat("dd MMM kk:mm a");
    final date = data['redeemedAt'] != null ? dateFormat.format((data['redeemedAt'] as Timestamp).toDate()) : localizations.translate('track_order_no_date');
    final code = data['pickupCode'] ?? localizations.translate('track_order_not_applicable');
    final processedOrder = data['processedOrder'] ?? 'no';
    final pickedUp = data['pickedUp'] ?? 'no';
    final userName = data['userName'] ?? 'N/A';
    final orderedBy = data['orderedBy'] as String?;

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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RedemptionStatus(documentId: orderDoc.id))),
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
                    Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (orderedBy != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text("by: $orderedBy", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 4),
                    Text(localizations.translateWithArgs('track_order_pickup_code_label', {'code': code}), style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20, thickness: 0.5),
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

  Future<List<Map<String, dynamic>>> _fetchHamperItems(String hamperName) async {
    var querySnapshot = await FirebaseFirestore.instance.collection('package_hamper').where('name', isEqualTo: hamperName).limit(1).get();
    if (querySnapshot.docs.isEmpty) querySnapshot = await FirebaseFirestore.instance.collection('package_kasih').where('name', isEqualTo: hamperName).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      final hamperData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      if (hamperData['items'] != null && hamperData['items'] is List) return List<Map<String, dynamic>>.from(hamperData['items']);
    }
    return [];
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
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.only(left: 62.0, top: 8.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
            final hamperContents = snapshot.data!;
            return Column(
              children: hamperContents.asMap().entries.map((entry) {
                return _buildItemDetailRow(context, entry.value, isSubItem: true, index: entry.key);
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
            Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 13))),
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
                  ? Image.network(imageUrl, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorBuilder: (context, error, stack) => Icon(Icons.broken_image, color: Colors.grey[500]))
                  : Container(color: Colors.grey[800], child: Icon(Icons.shopping_basket, color: Colors.grey[500])),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
