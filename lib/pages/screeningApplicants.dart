import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class screeningApplicants extends StatefulWidget {
  @override
  _screeningApplicantsState createState() =>
      _screeningApplicantsState();
}

class _screeningApplicantsState extends State<screeningApplicants> {
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
          // Header Section (Full Width) with inner shadow
          Container(
            width: double.infinity, // Full width
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
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
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the details page and pass the application data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationDetailsScreen(applicationData: app),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> applicationData;

  ApplicationDetailsScreen({required this.applicationData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(applicationData['fullname']),
        backgroundColor: Color(0xFF303030),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Full Name: ${applicationData['fullname']}", style: TextStyle(color: Colors.white)),
            Text("Date: ${applicationData['date']}", style: TextStyle(color: Colors.white)),
            Text("Submitted by: ${applicationData['submitted_by']}", style: TextStyle(color: Colors.white)),
            Text("Status: ${applicationData['status']}", style: TextStyle(color: Colors.white)),
            // Add other fields as needed
          ],
        ),
      ),
    );
  }
}
