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
  String selectedFilter = "All";
  String selectedSort = "Date";
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
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
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    },
                    items: ["All", "Pending", "Approve", "Reject"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child:
                          Text(value, style: TextStyle(color: Colors.black)),
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
                      setState(() {
                        selectedSort = newValue!;
                      });
                    },
                    items: ["Date", "Name", "Status"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Center(
                          child:
                          Text(value, style: TextStyle(color: Colors.black)),
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
              stream: FirebaseFirestore.instance.collection('applications').snapshots(),
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
                    'submittedBy': appData['submittedBy'], // Keep as dynamic type
                    'statusApplication': appData['statusApplication'] ?? 'Pending',
                    'applicationCode': appData.containsKey('applicationCode')
                        ? appData['applicationCode']
                        : "No Code",
                    'id': doc.id,
                    'userId': appData['userId'], // Keep as dynamic type
                  };
                }).toList();

                if (selectedFilter != "All") {
                  applications = applications.where((app) {
                    return app['statusApplication'].toString().toLowerCase() == selectedFilter.toLowerCase();
                  }).toList();
                }

                if (searchQuery.isNotEmpty) {
                  applications = applications.where((app) {
                    return app['fullname'].toString().toLowerCase().contains(searchQuery);
                  }).toList();
                }

                applications.sort((a, b) {
                  if (selectedSort == "Name") {
                    return a['fullname'].compareTo(b['fullname']);
                  } else if (selectedSort == "Status") {
                    return a['statusApplication'].compareTo(b['statusApplication']);
                  } else {
                    DateTime dateA = a['date'] != '' ? DateTime.parse(a['date']) : DateTime(1900);
                    DateTime dateB = b['date'] != '' ? DateTime.parse(b['date']) : DateTime(1900);
                    return dateB.compareTo(dateA);
                  }
                });

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    var app = applications[index];
                    String formattedDate = app['date'] != ''
                        ? DateFormat("dd MMM yyyy")
                        .format(DateTime.parse(app['date']))
                        : 'No date provided';

                    String uniqueCode = app['applicationCode'] ?? 'No Code';
                    String userId = app['userId'] ?? '';

                    // **FIX:** Check if userId is valid before trying to fetch from Firestore.
                    if (userId.isNotEmpty) {
                      // This is an Asnaf submission, fetch the user's photo.
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
                      // **FIX:** This is a Staff submission, so there's no user photo to fetch.
                      // Build the card directly with an empty photo URL.
                      return buildApplicationCard(app, formattedDate, uniqueCode, "");
                    }
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

  Widget buildApplicationCard(Map<String, dynamic> app, String formattedDate, String uniqueCode, String photoUrl) {
    String statusApplication = app['statusApplication'] ?? 'Pending';
    var submittedByData = app['submittedBy'];
    String submittedByText;

    // **FIX:** Check the type of 'submittedBy' to display the correct name.
    if (submittedByData is Map) {
      // If it's a map (staff submission), get the name from it.
      submittedByText = submittedByData['name'] ?? 'Unknown Staff';
    } else if (submittedByData is String) {
      // If it's a string (asnaf submission), use it directly.
      submittedByText = submittedByData;
    } else {
      submittedByText = 'Unknown';
    }

    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell( // Use InkWell for splash effect on tap
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
                      Container(width: 40, height: 40, color: Colors.grey.shade700, child: Icon(Icons.person)),
                )
                    : Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade700,
                  child: Icon(Icons.person, color: Colors.white70),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['fullname'],
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(Icons.circle, color: Colors.grey, size: 5),
                        ),
                        Flexible(
                          child: Text(
                            uniqueCode,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    submittedByText,
                    style: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusApplication == "Pending"
                          ? Colors.orange.withOpacity(0.2)
                          : statusApplication == "Approve"
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusApplication,
                      style: TextStyle(
                        color: statusApplication == "Pending"
                            ? Colors.orange
                            : statusApplication == "Approve"
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