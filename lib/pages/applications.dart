import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/applicationStatus.dart';

class ApplicationsScreen extends StatefulWidget {
  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _applicationsStream;
  String selectedFilter = "All";
  String selectedSort = "Date";
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _applicationsStream = FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _applicationsStream = const Stream.empty();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Color _statusColor(String statusApplication, String? statusReward, int stage) {
    if (stage == 1) {
      return Colors.green;
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
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Column(
              children: [
                Text(
                  "Your Application Status",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  "Track applications you’ve submitted.",
                  style: TextStyle(
                    color: Color(0xFFAA820C),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // SEARCH / FILTER / SORT (match verifyApplications)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
            child: Row(
              children: [
                SizedBox(
                  width: 145,
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.16, 0.38, 0.58, 0.88],
                            colors: [
                              Color(0xFFF9F295),
                              Color(0xFFE0AA3E),
                              Color(0xFFF9F295),
                              Color(0xFFB88A44),
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(
                          Icons.search_rounded,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                      hintText: "Search Code",
                      hintStyle: TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(width: 6),
                SizedBox(
                  width: 115,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.filter_list, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (String? newValue) {
                      setState(() => selectedFilter = newValue!);
                    },
                    items: ["All", "Pending", "Approve", "Disapprove"]
                        .map<DropdownMenuItem<String>>((String v) {
                      return DropdownMenuItem<String>(
                        value: v,
                        child: Center(
                            child: Text(
                              v,
                              style: TextStyle(color: Colors.black),
                            )),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.sort, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (String? newValue) {
                      setState(() => selectedSort = newValue!);
                    },
                    items: ["Date", "Name", "Status"]
                        .map<DropdownMenuItem<String>>((String v) {
                      return DropdownMenuItem<String>(
                        value: v,
                        child: Center(
                            child: Text(
                              v,
                              style: TextStyle(color: Colors.black),
                            )),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            thickness: 1,
            color: Colors.white,
            indent: 10,
            endIndent: 10,
          ),

          // LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _applicationsStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text("No applications found",
                        style:
                        TextStyle(color: Colors.white, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final dateStr = data['date'] ?? '';
                    final date = dateStr.isNotEmpty
                        ? DateFormat("dd MMM yyyy")
                        .format(DateTime.parse(dateStr))
                        : 'No date';
                    final code = data['applicationCode'] ?? '—';
                    final statusApplication = data['statusApplication'] ?? 'Pending';
                    final statusReward = data['statusReward'] as String?;

                    // filters
                    if (selectedFilter != 'All' && statusApplication != selectedFilter) {
                      return SizedBox.shrink();
                    }
                    if (searchQuery.isNotEmpty &&
                        !code.toLowerCase().contains(searchQuery)) {
                      return SizedBox.shrink();
                    }

                    // timeline colors
                    final c1 = _statusColor(statusApplication, statusReward, 1);
                    final c2 = _statusColor(statusApplication, statusReward, 2);
                    final c3 = _statusColor(statusApplication, statusReward, 3);

                    return Card(
                      color: Colors.grey[850],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      margin:
                      EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplicationStatusPage(
                                  documentId: doc.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // main row
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      color: c1, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "$date   $code",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16),
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
                              SizedBox(height: 8),
                              // mini timeline: Submitted → Completed → Rewards
                              Row(
                                children: [
                                  _buildTimelineStep('Submitted', c1),
                                  _buildTimelineLine(c1),
                                  _buildTimelineStep('Completed', c2),
                                  _buildTimelineLine(c3),
                                  _buildTimelineStep('Rewards', c3),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
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

  Widget _buildTimelineStep(String label, Color color) {
    return Column(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        SizedBox(height: 4),
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
        margin: EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
