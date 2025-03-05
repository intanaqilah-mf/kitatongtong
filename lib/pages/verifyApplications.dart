import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class VerifyApplicationsScreen extends StatefulWidget {
  @override
  _VerifyApplicationsScreenState createState() => _VerifyApplicationsScreenState();
}

class _VerifyApplicationsScreenState extends State<VerifyApplicationsScreen> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _applicationsStream;
  Map<int, bool> _expandedStates = {}; // Track expanded states for each item

  String selectedFilter = "All"; // Default filter
  String selectedSort = "Date"; // Default sorting

  @override
  void initState() {
    super.initState();
    _applicationsStream = FirebaseFirestore.instance.collection('applications').snapshots();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030), // Background color
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Section (Full Width)
          Container(
            width: double.infinity, // Full width
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF303030), // Background color
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Verify Application",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Center text
                ),
                SizedBox(height: 12.0), // Add more space
                Text(
                  "Track applications you’ve submitted or managed.",
                  style: TextStyle(
                    color: Color(0xFFAA820C),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center, // Center text
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: "Search Asnaf",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Triggers UI refresh on text change
                    },
                  ),
                ),
                SizedBox(width: 8),

                // Filter Dropdown
                DropdownButton<String>(
                  value: selectedFilter,
                  dropdownColor: Colors.black,
                  icon: Icon(Icons.filter_list, color: Colors.white),
                  style: TextStyle(color: Colors.white),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                  items: ["All", "Pending", "Approved", "Rejected"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8),

                // Sort Dropdown
                DropdownButton<String>(
                  value: selectedSort,
                  dropdownColor: Colors.black,
                  icon: Icon(Icons.sort, color: Colors.white),
                  style: TextStyle(color: Colors.white),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSort = newValue!;
                    });
                  },
                  items: ["Date", "Name", "Status"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Fetch & Display Applications
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
                    'date': appData['date'] ?? 'No date provided',
                    'submitted_by': appData['submitted_by'] ?? 'Unknown',
                    'status': appData['status'] ?? 'Pending',
                  };
                }).toList();

                // Sorting Logic
                applications.sort((a, b) {
                  if (selectedSort == "Date") {
                    var dateA = a['date'] ?? '';
                    var dateB = b['date'] ?? '';
                    return dateB.compareTo(dateA);
                  } else if (selectedSort == "Name") {
                    return a['fullname'].compareTo(b['fullname']);
                  } else {
                    return a['status'].compareTo(b['status']);
                  }
                });

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    var app = applications[index];
                    bool isExpanded = _expandedStates[index] ?? false;

                    return Card(
                      color: Colors.grey[850],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedStates[index] = !isExpanded;
                                    });
                                  },
                                  child: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              app['fullname'],
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(app['date'], style: TextStyle(color: Colors.grey)),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Submitted by: ${app['submitted_by']}",
                                  style: TextStyle(color: Colors.amber, fontSize: 12),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  app['status'],
                                  style: TextStyle(
                                    color: app['status'] == "Pending"
                                        ? Colors.orange
                                        : app['status'] == "Approved"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
