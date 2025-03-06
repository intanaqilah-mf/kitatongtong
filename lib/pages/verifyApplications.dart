import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class VerifyApplicationsScreen extends StatefulWidget {
  @override
  _VerifyApplicationsScreenState createState() =>
      _VerifyApplicationsScreenState();
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
                SizedBox(height: 15.0), // Add more space
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
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 6.0),
            child: Row(
              children: [
                // Search Field (Increase width)
                SizedBox(
                  width: 160, // Increased width for Search field
                  height: 40, // Match height of dropdowns
                  child: TextField(
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
                          size: 25, // Adjust size to match dropdown icon size
                          color: Colors.white, // This will be overridden by ShaderMask
                        ),
                      ),
                      hintText: "Search Asnaf",
                      hintStyle: TextStyle(fontSize: 14), // Match dropdown text size
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 14), // Match dropdown text size
                    onChanged: (value) {
                      setState(() {}); // Triggers UI refresh on text change
                    },
                  ),
                ),

                SizedBox(width: 8), // Small gap between search and filter

                // Filter Dropdown (Reduce width)
                SizedBox(
                  width: 100, // Reduced width for Filter field
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2), // Reduced padding
                    ),
                    dropdownColor: Colors.black,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.filter_list, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    selectedItemBuilder: (BuildContext context) {
                      return ["All", "Pending", "Approved", "Rejected"]
                          .map<Widget>((String value) {
                        return Padding(
                          padding: EdgeInsets.only(left: 10),  // Add left padding to move text to the right
                          child: Center(
                            child: Text(value, style: TextStyle(color: Colors.black)),
                          ),
                        );
                      }).toList();
                    },
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
                          child: Text(value, style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(width: 8), // Small gap between filter and sort

                // Sort Dropdown (Reduce width)
                SizedBox(
                  width: 90, // Reduced width for Sort field
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Reduced padding
                    ),
                    dropdownColor: Colors.black,
                    icon: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.sort, color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    selectedItemBuilder: (BuildContext context) {
                      return ["Date", "Name", "Status"].map<Widget>((String value) {
                        return Center(
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList();
                    },
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
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Fetch & Display Applications (Cards)
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
