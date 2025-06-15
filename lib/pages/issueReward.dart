import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/VoucherIssuance.dart';

class IssueReward extends StatefulWidget {
  @override
  _IssueRewardScreenState createState() => _IssueRewardScreenState();
}

class _IssueRewardScreenState extends State<IssueReward> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
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

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Stream<QuerySnapshot> _getApplicationsStream(int tabIndex) {
    Query query = FirebaseFirestore.instance
        .collection('applications')
        .where('statusApplication', isEqualTo: 'Approve');

    switch (tabIndex) {
      case 1: // Pending
        query = query.where('statusReward', isEqualTo: 'Pending');
        break;
      case 2: // Issued
        query = query.where('statusReward', isEqualTo: 'Issued');
        break;
      case 3: // Redeemed
        query = query.where('statusReward', isEqualTo: 'Redeemed');
        break;
    }

    switch (_selectedSort) {
      case "Name":
        query = query.orderBy('fullname');
        break;
      case "Status":
        query = query.orderBy('statusReward');
        break;
      default: // Date
        query = query.orderBy('date', descending: true);
        break;
    }

    return query.snapshots();
  }

  List<DocumentSnapshot> _filterDocsBySearch(List<DocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      return docs;
    }
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullname = (data['fullname'] as String? ?? '').toLowerCase();
      final code = (data['applicationCode'] as String? ?? '').toLowerCase();
      return fullname.contains(_searchQuery) || code.contains(_searchQuery);
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
          "Issue Reward",
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
            Tab(text: "Pending"),
            Tab(text: "Issued"),
            Tab(text: "Redeemed"),
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
                        hintText: "Search by name or code...",
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
                    items: ["Date", "Name", "Status"]
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
                  stream: _getApplicationsStream(tabIndex),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No applications found", style: TextStyle(color: Colors.white70)));
                    }

                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);

                    if (displayDocs.isEmpty) {
                      return Center(
                        child: Text(
                          "No rewards in this category" + (_searchQuery.isNotEmpty ? " match your search." : "."),
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        return buildApplicationCard(displayDocs[index]);
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
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget buildApplicationCard(DocumentSnapshot doc) {
    final appData = doc.data() as Map<String, dynamic>;
    final String fullname = appData['fullname'] ?? 'Unknown';
    final String dateStr = appData['date'] ?? '';
    final String formattedDate = dateStr.isNotEmpty ? DateFormat("dd MMM yy").format(DateTime.parse(dateStr)) : 'No date';
    final String uniqueCode = appData['applicationCode'] ?? 'N/A';
    final String statusReward = appData['statusReward'] ?? 'Pending';
    final String userId = appData['userId'] ?? '';
    final rewardValue = appData['reward'] as String?;

    Color statusColor;
    switch (statusReward) {
      case 'Issued':
        statusColor = Colors.green;
        break;
      case 'Redeemed':
        statusColor = Colors.blueAccent;
        break;
      case 'Pending':
      default:
        statusColor = Colors.orangeAccent;
        break;
    }

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoucherIssuance(documentId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userId.isNotEmpty)
                    FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, userSnapshot) {
                          String photoUrl = "";
                          if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            photoUrl = userData['photoUrl'] ?? "";
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: photoUrl.isNotEmpty
                                ? Image.network(photoUrl, width: 40, height: 40, fit: BoxFit.cover)
                                : Container(width: 40, height: 40, color: Colors.grey.shade700, child: const Icon(Icons.person, color: Colors.white70)),
                          );
                        }),
                  if (userId.isEmpty)
                    Container(width: 40, height: 40, color: Colors.grey.shade700, child: const Icon(Icons.person, color: Colors.white70)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullname, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("$formattedDate   $uniqueCode", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(statusReward, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      if (statusReward == 'Issued' && rewardValue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            rewardValue,
                            style: const TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
