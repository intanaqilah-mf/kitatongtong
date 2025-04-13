import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staffDetails.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class ManageStaffsScreen extends StatefulWidget {
  @override
  _ManageStaffsScreenState createState() => _ManageStaffsScreenState();
}

class _ManageStaffsScreenState extends State<ManageStaffsScreen> {
  int _selectedIndex = 0;
  List<String> selectedRoles = []; // empty means show all roles
  String sortBy = 'created_at'; // or 'name'
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Stream<QuerySnapshot> getUsersStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('users');

    // Apply role filter only if one or more roles are selected.
    // Note: Ensure that the string here exactly matches the format stored in Firebase.
    if (selectedRoles.isNotEmpty) {
      query = query.where('role', whereIn: selectedRoles);
    }

    // Order by either creation date or name.
    query = query.orderBy(sortBy, descending: sortBy == 'created_at');

    return query.snapshots();
  }

  Widget buildUserCard(Map<String, dynamic> userData, String docId) {
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
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: (userData['photoUrl'] ?? '').toString().isNotEmpty
                ? Image.network(
              userData['photoUrl'],
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            )
                : Container(width: 30, height: 30, color: Colors.grey.shade800),
          ),
          title: Text(userData['name'] ?? 'Unknown',
              style: TextStyle(color: Colors.white)),
          subtitle: Text(userData['email'] ?? 'No Email',
              style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
        title: Text("Manage Staffs", style: TextStyle(color: Color(0xFFFDB515))),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Text("Track users you’ve registered or managed.",
                    style: TextStyle(color: Color(0xFFAA820C), fontSize: 13)),
                SizedBox(height: 15),
                Row(
                  children: [
                    // 🔍 Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() => searchQuery = value.toLowerCase());
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 25, color: Color(0xFFFDB515)),
                          hintText: "Search User",
                          hintStyle: TextStyle(fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    SizedBox(width: 8),

                    // 🧩 Filter by Role (Multi-select)
                    Expanded(
                      flex: 2,
                      child: PopupMenuButton<String>(
                        onSelected: (role) {
                          setState(() {
                            if (selectedRoles.contains(role)) {
                              selectedRoles.remove(role);
                            } else {
                              selectedRoles.add(role);
                            }
                          });
                        },
                        itemBuilder: (context) => ['admin', 'staff', 'asnaf']
                            .map((role) => CheckedPopupMenuItem(
                          value: role,
                          checked: selectedRoles.contains(role),
                          child: Text(role[0].toUpperCase() + role.substring(1)),
                        ))
                            .toList(),
                        child: Container(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, color: Colors.black),
                              SizedBox(width: 6),
                              Text("Filter", style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // 📅 Sort by dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: sortBy,
                            icon: Icon(Icons.expand_more, color: Colors.black),
                            style: TextStyle(color: Colors.black),
                            items: [
                              DropdownMenuItem(
                                value: 'created_at',
                                child: Text('Date'),
                              ),
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Name'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => sortBy = value!);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(thickness: 1, color: Colors.white, indent: 10, endIndent: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: TextStyle(color: Colors.white)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text("No users found.",
                        style: TextStyle(color: Colors.white)),
                  );

                // Client-side filtering for search query on name.
                var users = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return data['name'] != null &&
                      data['name'].toString().toLowerCase().contains(searchQuery);
                }).toList();

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