import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/screeningApplicants.dart';

class VerifyApplicationsScreen extends StatefulWidget {
  @override
  _VerifyApplicationsScreenState createState() =>
      _VerifyApplicationsScreenState();
}

class _VerifyApplicationsScreenState extends State<VerifyApplicationsScreen>
    with SingleTickerProviderStateMixin {
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
    Query query = FirebaseFirestore.instance.collection('applications');

    // Filter based on the selected tab
    switch (tabIndex) {
      case 1: // Pending
        query = query.where('statusApplication', isEqualTo: 'Pending');
        break;
      case 2: // Verified
        query = query.where('statusApplication', isEqualTo: 'Approve');
        break;
      case 3: // Rejected
        query = query.where('statusApplication', isEqualTo: 'Reject');
        break;
    // Case 0 (All) does not need a filter
    }

    // Sort based on the selected sort option
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
      final fullname = (data['fullname'] as String? ?? '').toLowerCase();
      return fullname.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303030),
        elevation: 0,
        title: Text(
          loc.translate('verifyApp_title'),
          style: TextStyle(
            color: Color(0xFFFDB515),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFDB515),
          labelColor: const Color(0xFFFDB515),
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: loc.translate('verifyApp_tab_all')),
            Tab(text: loc.translate('verifyApp_tab_pending')),
            Tab(text: loc.translate('verifyApp_tab_verified')),
            Tab(text: loc.translate('verifyApp_tab_rejected')),
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
                        hintText: loc.translate('verifyApp_search_hint'),
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
                    items: [
                      {"value": "Date", "label": loc.translate('verifyApp_sort_date')},
                      {"value": "Name", "label": loc.translate('verifyApp_sort_name')},
                      {"value": "Status", "label": loc.translate('verifyApp_sort_status')}
                    ]
                        .map((s) => DropdownMenuItem(value: s["value"], child: Text(s["label"]!)))
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
                      return Center(child: Text(loc.translateWithArgs('verifyApp_error_generic', {'error': snapshot.error.toString()}), style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(loc.translate('verifyApp_no_apps_found'), style: TextStyle(color: Colors.white70)));
                    }

                    final displayDocs = _filterDocsBySearch(snapshot.data!.docs);

                    if (displayDocs.isEmpty) {
                      return Center(
                          child: Text(
                            loc.translate('verifyApp_no_apps_in_category') + (_searchQuery.isNotEmpty ? loc.translate('verifyApp_search_no_match') : "."),
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: displayDocs.length,
                      itemBuilder: (context, index) {
                        final doc = displayDocs[index];
                        final appData = doc.data() as Map<String, dynamic>;

                        final app = {
                          'fullname': appData['fullname'] ?? loc.translate('verifyApp_unknown_user'),
                          'date': appData['date'] ?? '',
                          'submittedBy': appData['submittedBy'],
                          'statusApplication': appData['statusApplication'] ?? 'Pending',
                          'applicationCode': appData.containsKey('applicationCode')
                              ? appData['applicationCode']
                              : loc.translate('verifyApp_no_code'),
                          'id': doc.id,
                          'userId': appData['userId'],
                        };

                        final formattedDate = app['date'] != ''
                            ? DateFormat("dd MMMFocusBracketing").format(DateTime.parse(app['date'].toString()))
                            : loc.translate('verifyApp_no_date');

                        final uniqueCode = app['applicationCode']?.toString() ?? loc.translate('verifyApp_no_code');
                        final userId = app['userId']?.toString() ?? '';

                        if (userId.isNotEmpty) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                            builder: (context, userSnapshot) {
                              String photoUrl = "";
                              if (userSnapshot.connectionState == ConnectionState.done &&
                                  userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                photoUrl = userData['photoUrl'] ?? "";
                              }
                              return buildApplicationCard(app, formattedDate, uniqueCode, photoUrl);
                            },
                          );
                        } else {
                          return buildApplicationCard(app, formattedDate, uniqueCode, "");
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget buildApplicationCard(Map<String, dynamic> app, String formattedDate, String uniqueCode, String photoUrl) {
    final loc = AppLocalizations.of(context)!;
    String statusKey = app['statusApplication'] ?? 'Pending';
    String statusApplication;

    switch (statusKey) {
      case 'Approve':
        statusApplication = loc.translate('verifyApp_status_approve');
        break;
      case 'Reject':
        statusApplication = loc.translate('verifyApp_status_reject');
        break;
      default:
        statusApplication = loc.translate('verifyApp_status_pending');
    }

    var submittedByData = app['submittedBy'];
    String submittedByText;

    if (submittedByData is Map) {
      submittedByText = submittedByData['name'] ?? loc.translate('screening_unknown_staff');
    } else if (submittedByData is String) {
      submittedByText = submittedByData;
    } else {
      submittedByText = loc.translate('verifyApp_unknown_user');
    }

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScreeningApplicants(
                documentId: app['id'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                  photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: 40, height: 40, color: Colors.grey.shade700, child: const Icon(Icons.person)),
                )
                    : Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade700,
                  child: const Icon(Icons.person, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['fullname'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.circle, color: Colors.grey, size: 5),
                        ),
                        Flexible(
                          child: Text(
                            uniqueCode,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    submittedByText,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusKey == "Pending"
                          ? Colors.orange.withOpacity(0.2)
                          : statusKey == "Approve"
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusApplication,
                      style: TextStyle(
                        color: statusKey == "Pending"
                            ? Colors.orange
                            : statusKey == "Approve"
                            ? Colors.green
                            : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
