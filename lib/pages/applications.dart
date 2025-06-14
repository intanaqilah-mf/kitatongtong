import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/applicationStatus.dart';
import 'package:projects/localization/app_localizations.dart';

class ApplicationsScreen extends StatefulWidget {
  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
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

  Stream<QuerySnapshot> _getApplicationsStream(int tabIndex) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: user.uid);

    switch (tabIndex) {
      case 1: // Submitted
        query = query.where('statusApplication', whereIn: ['Pending', 'Reject']);
        break;
      case 2: // Completed
        query = query
            .where('statusApplication', whereIn: ['Approve'])
            .where('statusReward', isEqualTo: 'Pending');
        break;
      case 3: // Rewards Issued
        query = query.where('statusReward', isEqualTo: 'Issued');
        break;
    }

    switch (_selectedSort) {
      case "Name":
        query = query.orderBy('fullname');
        break;
      case "Status":
        query = query.orderBy('statusApplication');
        break;
      default: // "Date"
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
      final code = (data['applicationCode'] as String? ?? '').toLowerCase();
      return code.contains(_searchQuery);
    }).toList();
  }

  Color _statusColor(String statusApplication, String? statusReward, int stage) {
    if (stage == 1) {
      return Colors.green;
    }
    if (statusApplication == 'Reject') {
      return Colors.red;
    }
    if (stage == 2) {
      if (statusApplication == 'Disapprove') return Colors.red;
      if (statusApplication == 'Approve' || statusApplication == 'Approved') return Colors.green;
      return Colors.grey;
    }
    // stage == 3
    if (statusApplication == 'Disapprove') {
      return Colors.red;
    }
    if (statusReward == 'Issued') {
      return Colors.green;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303030),
        elevation: 0,
        title: Text(
          localizations.translate('applications_title'),
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
            Tab(text: localizations.translate('applications_tab_all')),
            Tab(text: localizations.translate('applications_tab_submitted')),
            Tab(text: localizations.translate('applications_tab_completed')),
            Tab(text: localizations.translate('applications_tab_rewards_issued')),
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
                        hintText: localizations.translate('applications_search_hint'),
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
                  stream: _getApplicationsStream(tabIndex),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(localizations.translateWithArgs('applications_error_fetch', {'error': snapshot.error.toString()}), style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(localizations.translate('applications_no_apps_found'), style: const TextStyle(color: Colors.white70)));
                    }

                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);

                    if (displayDocs.isEmpty) {
                      return Center(
                          child: Text(
                            localizations.translate('applications_no_apps_in_category') + (_searchQuery.isNotEmpty ? localizations.translate('applications_matching_search') : '.'),
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        return _buildApplicationCard(displayDocs[index]);
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

  Widget _buildApplicationCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final localizations = AppLocalizations.of(context);

    final dateStr = data['date'] ?? '';
    final date = dateStr.isNotEmpty
        ? DateFormat("dd MMM yyyy").format(DateTime.parse(dateStr))
        : localizations.translate('applications_no_date');
    final code = data['applicationCode'] ?? localizations.translate('applications_no_code');
    final statusApplication = data['statusApplication'] ?? localizations.translate('applications_status_pending');
    final statusReward = data['statusReward'] as String?;

    final c1 = _statusColor(statusApplication, statusReward, 1);
    final c2 = _statusColor(statusApplication, statusReward, 2);
    final c3 = _statusColor(statusApplication, statusReward, 3);

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
              builder: (_) => ApplicationStatusPage(documentId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: c1, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$date   $code",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Text(
                    statusApplication,
                    style: TextStyle(
                      color: c2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimelineStep(localizations.translate('applications_timeline_submitted'), c1),
                  _buildTimelineLine(c2),
                  _buildTimelineStep(localizations.translate('applications_timeline_completed'), c2),
                  _buildTimelineLine(c3),
                  _buildTimelineStep(localizations.translate('applications_timeline_rewards'), c3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String label, Color color) {
    return Column(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color != Colors.grey ? Colors.white : Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(Color color) {
    return Expanded(
      child: Container(
        height: 2,
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}