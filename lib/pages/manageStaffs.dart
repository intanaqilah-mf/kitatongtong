import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/localization/app_localizations.dart';
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
    if (selectedRoles.isNotEmpty) {
      query = query.where('role', whereIn: selectedRoles);
    }

    // Order by either creation date or name.
    query = query.orderBy(sortBy, descending: sortBy == 'created_at');

    return query.snapshots();
  }

  // UPDATED WIDGET
  Widget buildUserCard(Map<String, dynamic> userData, String docId) {
    final loc = AppLocalizations.of(context)!;
    final String role = userData['role'] ?? 'unknown';

    // Determine the display text and colors based on the role
    String roleDisplayText;
    Color roleColor;
    Color roleBackgroundColor;

    switch (role.toLowerCase()) {
      case 'admin':
        roleDisplayText = loc.translate('manageStaffs_role_admin');
        roleColor = Colors.purpleAccent;
        roleBackgroundColor = Colors.purpleAccent.withOpacity(0.2);
        break;
      case 'staff':
        roleDisplayText = loc.translate('manageStaffs_role_staff');
        roleColor = Colors.green;
        roleBackgroundColor = Colors.green.withOpacity(0.2);
        break;
      case 'asnaf':
        roleDisplayText = loc.translate('manageStaffs_role_asnaf');
        roleColor = Colors.orange;
        roleBackgroundColor = Colors.orange.withOpacity(0.2);
        break;
      default:
        roleDisplayText = role; // Fallback for any other unexpected roles
        roleColor = Colors.grey;
        roleBackgroundColor = Colors.grey.withOpacity(0.2);
    }

    // Capitalize the first letter for better display
    if (roleDisplayText.isNotEmpty) {
      roleDisplayText = roleDisplayText[0].toUpperCase() + roleDisplayText.substring(1);
    }

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
            borderRadius: BorderRadius.circular(8),
            child: (userData['photoUrl'] ?? '').toString().isNotEmpty
                ? Image.network(
              userData['photoUrl'],
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: Colors.grey.shade700, child: const Icon(Icons.person, color: Colors.white70)),
            )
                : Container(width: 40, height: 40, color: Colors.grey.shade700, child: const Icon(Icons.person, color: Colors.white70)),
          ),
          title: Text(userData['name'] ?? loc.translate('manageStaffs_unknown_user'),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(userData['email'] ?? loc.translate('manageStaffs_no_email'),
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: roleBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              roleDisplayText,
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
        title: Text(loc.translate('manageStaffs_title'), style: TextStyle(color: Color(0xFFFDB515))),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Text(loc.translate('manageStaffs_subtitle'),
                    style: TextStyle(color: Color(0xFFAA820C), fontSize: 13)),
                SizedBox(height: 15),
                Row(
                  children: [
                    // Search
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
                          hintText: loc.translate('manageStaffs_search_hint'),
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

                    // Filter by Role (Multi-select)
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
                        itemBuilder: (context) {
                          final roles = {
                            "admin": loc.translate('manageStaffs_role_admin'),
                            "staff": loc.translate('manageStaffs_role_staff'),
                            "asnaf": loc.translate('manageStaffs_role_asnaf'),
                          };
                          return roles.entries.map((entry) => CheckedPopupMenuItem(
                            value: entry.key,
                            checked: selectedRoles.contains(entry.key),
                            child: Text(entry.value),
                          )).toList();
                        },
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
                              Text(loc.translate('manageStaffs_filter_button'), style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Sort by dropdown
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
                                child: Text(loc.translate('manageStaffs_sort_date')),
                              ),
                              DropdownMenuItem(
                                value: 'name',
                                child: Text(loc.translate('manageStaffs_sort_name')),
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
                      child: Text(loc.translateWithArgs('manageStaffs_error_generic', {'error': snapshot.error.toString()}),
                          style: TextStyle(color: Colors.white)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text(loc.translate('manageStaffs_no_users_found'),
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