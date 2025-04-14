import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/VoucherIssuance.dart';

class IssueReward extends StatefulWidget {
  @override
  _IssueRewardScreenState createState() => _IssueRewardScreenState();
}

class _IssueRewardScreenState extends State<IssueReward> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _applicationsStream;
  Map<int, bool> _expandedStates = {};
  String selectedFilter = "All";
  String selectedSort = "Date";
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _applicationsStream =
        FirebaseFirestore.instance.collection('applications').snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Column(
              children: [
                Text(
                  "Issue Reward",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15.0),
                Text(
                  "View and issue rewards to applicants.",
                  style: TextStyle(
                    color: Color(0xFFAA820C),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
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
                      hintText: "Search Asnaf",
                      hintStyle: TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(width: 6),
                SizedBox(
                  width: 105,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 2, horizontal: 10),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.filter_list, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    },
                    items: ["All", "Pending", "Approved", "Rejected"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child: Text(value,
                              style: TextStyle(color: Colors.black)),
                        ),
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
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 2, horizontal: 12),
                    ),
                    dropdownColor: Colors.white,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.sort, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSort = newValue!;
                      });
                    },
                    items: ["Date", "Name", "Status"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child: Text(value,
                              style: TextStyle(color: Colors.black)),
                        ),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _applicationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No applications found",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  );
                }

                var applications = snapshot.data!.docs.map((doc) {
                  var appData = doc.data() as Map<String, dynamic>;
                  return {
                    'fullname': appData['fullname'] ?? 'Unknown',
                    'date': appData['date'] ?? '',
                    // Use the exact key "submittedBy" as stored in Firestore
                    'submittedBy': appData['submittedBy'] ?? 'Unknown',
                    'statusApplication': appData['statusApplication'] ?? 'Pending',
                    'applicationCode': appData['applicationCode'] ?? '',
                    'id': doc.id,
                    'userId': appData['userId'] ?? '',
                  };
                }).toList();

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    var app = applications[index];
                    String formattedDate = app['date'] != ''
                        ? DateFormat("dd MMM yyyy").format(DateTime.parse(app['date']))
                        : 'No date provided';
                    String userId = app['userId'] ?? '';
                    String uniqueCode = app['applicationCode'] ?? 'N/A';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
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

  // Build the application card with submittedBy above statusApplication
  Widget buildApplicationCard(Map<String, dynamic> app, String formattedDate, String uniqueCode, String photoUrl) {
    bool isExpanded = _expandedStates[app['id']] ?? false;
    String statusApplication = app['statusApplication'] ?? 'Pending';
    String submittedBy = app['submittedBy'] ?? 'Unknown';

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoucherIssuance(
                documentId: app['id'],
              ),
            ),
          );
        },
        child: Column(
          children: [
            ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedStates[app['id']] = !isExpanded;
                      });
                    },
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                      photoUrl,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 30,
                      height: 30,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              title: Text(
                app['fullname'],
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 6,
                  ),
                  SizedBox(width: 6),
                  Text(
                    uniqueCode,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Display submittedBy on top
                  Text(
                    submittedBy,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  // Then display statusApplication below it
                  Text(
                    statusApplication,
                    style: TextStyle(
                      color: statusApplication == "Pending"
                          ? Colors.orange
                          : statusApplication == "Approve"
                          ? Colors.green
                          : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
