import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/screeningApplicants.dart';

class VerifyApplicationsScreen extends StatefulWidget {
  @override
  _VerifyApplicationsScreenState createState() =>
      _VerifyApplicationsScreenState();
}

class _VerifyApplicationsScreenState extends State<VerifyApplicationsScreen> {
  int _selectedIndex = 0;
  late Stream<QuerySnapshot> _applicationsStream;
  Map<int, bool> _expandedStates = {};
  String selectedFilter = "All";
  String selectedSort = "Date";

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

  // Generate a 6-character alphanumeric unique code starting with #
  String generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return "#" + String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<String> getOrCreateUniqueCode(String applicationId) async {
    DocumentReference docRef =
    FirebaseFirestore.instance.collection('applications').doc(applicationId);

    DocumentSnapshot docSnap = await docRef.get();

    if (docSnap.exists) {
      var data = docSnap.data() as Map<String, dynamic>;
      if (data.containsKey('applicationCode')) {
        return data['applicationCode']; // Return existing code if found
      } else {
        // Generate and store the new code if it doesn't exist
        String newCode = generateUniqueCode();
        await docRef.update({'applicationCode': newCode});
        return newCode;
      }
    }
    return generateUniqueCode(); // Fallback (should not happen)
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
                  "Verify Application",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15.0),
                Text(
                  "Track applications you’ve submitted or managed.",
                  style: TextStyle(
                    color: Color(0xFFAA820C),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
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
                    'submitted_by': appData['submitted_by'] ?? 'Unknown',
                    'statusApplication': appData['statusApplication'] ?? 'Pending',
                    'id': doc.id,
                    'userId': appData['userId'] ?? '',
                  };
                }).toList();

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    var app = applications[index];
                    bool isExpanded = _expandedStates[index] ?? false;
                    String formattedDate = app['date'] != ''
                        ? DateFormat("dd MMM yyyy").format(DateTime.parse(app['date']))
                        : 'No date provided';
                    String userId = app['userId'] ?? '';

                    return FutureBuilder<String>(
                      future: getOrCreateUniqueCode(app['id']),
                      builder: (context, codeSnapshot) {
                        if (codeSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        String uniqueCode = codeSnapshot.data ?? generateUniqueCode();

                        // Check if the userId is valid before querying Firestore
                        if (userId.isEmpty) {
                          // If userId is empty, show a default image (placeholder)
                          return buildApplicationCard(app, formattedDate, uniqueCode, '');
                        }

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

  // Function to build the application card
  Widget buildApplicationCard(Map<String, dynamic> app, String formattedDate, String uniqueCode, String photoUrl) {
    bool isExpanded = _expandedStates[app['id']] ?? false;

    // Fetch the correct 'statusApplication' field from Firestore
    String statusApplication = app['statusApplication'] ?? 'Pending'; // Default to 'Pending' if field is missing

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
              builder: (context) => ScreeningApplicants(
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 4),
                  Text(
                    statusApplication,  // Corrected to use 'statusApplication'
                    style: TextStyle(
                      color: statusApplication == "Pending"
                          ? Colors.orange
                          : statusApplication == "Approve"
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
  }

}
