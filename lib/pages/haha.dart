import 'package:flutter/material.dart';
import '../widgets/HomeAppBar.dart';
import '../widgets/AsnafDashboard.dart';
import '../widgets/AdminDashboard.dart';
import '../widgets/StaffDashboard.dart';
import '../widgets/UserPoints.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? userRole;
  Map<String, List<DocumentSnapshot>> sectionEvents = {};

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _fetchSections();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'asnaf';
        });
      }
    }
  }

  Future<void> _fetchSections() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("event").get();

    for (var doc in snapshot.docs) {
      String section = doc["sectionEvent"] ?? "Upcoming Activities"; // Default to "Upcoming Activities"
      if (!sectionEvents.containsKey(section)) {
        sectionEvents[section] = [];
      }
      sectionEvents[section]!.add(doc);
    }
    setState(() {}); // Refresh the UI with the new data
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getDashboard() {
    switch (userRole) {
      case 'admin':
        return AdminDashboard();
      case 'staff':
        return StaffDashboard();
      case 'asnaf':
      default:
        return AsnafDashboard();
    }
  }

  Widget _buildUpcomingActivities() {
    sectionEvents["Upcoming Activities"]?.sort((a, b) {
      Timestamp aTimestamp = a["updatedAt"];
      Timestamp bTimestamp = b["updatedAt"];
      return bTimestamp.compareTo(aTimestamp); // Descending order
    });
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.16, 0.38, 0.58, 0.88],
          colors: [
            Color(0xFFF9F295),
            Color(0xFFE0AA3E),
            Color(0xFFF9F295),
            Color(0xFFB88A44),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _widgetOptions = <Widget>[
      SingleChildScrollView(  // Wrap the entire content in SingleChildScrollView for scrolling
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 1),
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: userRole == 'admin'
                                    ? "Admin here..."
                                    : userRole == 'staff'
                                    ? "Staff here..."
                                    : "Asnaf here...",
                              ),
                            ),
                          ),
                        ),
                        ShaderMask(
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
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  userRole == null
                      ? CircularProgressIndicator()
                      : _getDashboard(),
                  UserPoints(),
                  _buildUpcomingActivities(),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 1),
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.16, 0.38, 0.58, 0.88],
                        colors: [
                          Color(0xFFF9F295),
                          Color(0xFFE0AA3E),
                          Color(0xFFF9F295),
                          Color(0xFFB88A44),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Upcoming Activities",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Fetch Events from Firestore and display horizontally
                        Container(
                          height: 200,  // Height of the container for the event list
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: sectionEvents["Upcoming Activities"]!.length,
                            itemBuilder: (context, index) {
                              var event = sectionEvents["Upcoming Activities"]![index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          event["bannerUrl"] ?? '',
                                          height: 120,
                                          width: double.infinity, // use full available width of container
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        event["eventName"] ?? "Unknown",
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.start,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),

                                      SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Get ${event["points"] ?? "0"} pts",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, color: Colors.red, size: 14),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    event["eventEndDate"] ?? "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ...sectionEvents.entries
                            .where((entry) => entry.key != "Upcoming Activities")
                            .map(
                              (entry) => _buildSectionRow(entry.key, entry.value),
                        ), // Add other event sections below "Upcoming Activities"
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Center(child: Text('Search Page')),
      Center(child: Text('Shopping Page')),
      Center(child: Text('Inbox Page')),
      Center(child: Text('Profile Page')),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // Display the selected page content
    );
  }

  Widget _buildSectionRow(String sectionName, List<DocumentSnapshot> events) {

    events.sort((a, b) {
      Timestamp aTimestamp = a["updatedAt"];
      Timestamp bTimestamp = b["updatedAt"];
      return bTimestamp.compareTo(aTimestamp); // Descending order
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            sectionName,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Container(
            height: 250,  // Height of the container for the event list
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                var event = events[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    width: 160,  // Adjust the width of each item for better space management
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            event["bannerUrl"] ?? '',
                            height: 120,
                            width: double.infinity, // use full available width of container
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event["eventName"] ?? "Unknown",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.start,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),

                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Get ${event["points"] ?? "0"} pts",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.red, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      event["eventEndDate"] ?? "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
