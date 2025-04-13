import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staffDetails.dart';
import 'package:intl/intl.dart'; // In case you want to display a formatted date or similar
import 'package:projects/widgets/bottomNavBar.dart';

class ManageStaffsScreen extends StatefulWidget {
  @override
  _ManageStaffsScreenState createState() => _ManageStaffsScreenState();
}

class _ManageStaffsScreenState extends State<ManageStaffsScreen> {
  int _selectedIndex = 0;
  // Query users collection where role is not "admin"
  late Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .orderBy('role') // required when using isNotEqualTo
      .where('role', isNotEqualTo: 'admin')
      .snapshots();
  Map<String, bool> _expandedStates = {};
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildUserCard(Map<String, dynamic> userData, String docId) {
    // For expanding/collapsing, similar to verifyApplications card
    bool isExpanded = _expandedStates[docId] ?? false;
    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffDetailScreen(documentId: docId),
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
                        _expandedStates[docId] = !isExpanded;
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
                    child: (userData['photoUrl'] ?? "").toString().isNotEmpty
                        ? Image.network(
                      userData['photoUrl'],
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
                userData['name'] ?? 'Unknown',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                userData['email'] ?? 'No Email',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Optionally add expanded details here if needed
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          // Top Header and Search Fields (UI similar to verifyApplications.dart)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: 50.0),
                Text(
                  "Manage Staffs",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15.0),
                Text(
                  "List of users (non-admin) available for management.",
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
                      prefixIcon: Icon(Icons.search_rounded, size: 25, color: Colors.white),
                      hintText: "Search Staff",
                      hintStyle: TextStyle(fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                // Additional dropdowns can be added if needed for sorting or filtering
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
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                      child: Text("No users found", style: TextStyle(color: Colors.white, fontSize: 16)));

                // Filter users based on search query if needed
                var users = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return data['name'] != null &&
                      data['name'].toString().toLowerCase().contains(searchQuery);
                }).toList();
                print("Documents: ${snapshot.data!.docs.length}");
                for (var doc in snapshot.data!.docs) {
                  print(doc.data());
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userDoc = users[index];
                    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
                    return buildUserCard(userData, userDoc.id);
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
