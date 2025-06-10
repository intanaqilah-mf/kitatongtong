import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import '../widgets/HomeAppBar.dart';
import '../widgets/AsnafDashboard.dart';
import '../widgets/AdminDashboard.dart';
import '../widgets/StaffDashboard.dart';
import '../widgets/UserPoints.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/EventDetailPage.dart'; // <-- 1. IMPORT THE NEW PAGE

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
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'asnaf';
        });
      }
    }
  }

  Future<void> _fetchSections() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection("event").get();

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

  @override
  Widget build(BuildContext context) {
    // --- Start of modification for Upcoming Activities ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingEventsList = sectionEvents["Upcoming Activities"] ?? [];

    final validUpcomingEvents = upcomingEventsList.where((event) {
      String eventEndDateString = event["eventEndDate"] ?? "";
      if (eventEndDateString.isNotEmpty) {
        try {
          DateTime eventEndDate = DateFormat('dd MMM yyyy HH:mm').parse(eventEndDateString);
          return !eventEndDate.isBefore(today);
        } catch (e) {
          print("Error parsing date: $e");
          return false;
        }
      }
      return true; // Keep events without an end date
    }).toList();

    validUpcomingEvents.sort((a, b) {
      Timestamp aTimestamp = a["updatedAt"];
      Timestamp bTimestamp = b["updatedAt"];
      return bTimestamp.compareTo(aTimestamp);
    });
    // --- End of modification ---

    final _widgetOptions = <Widget>[
      SingleChildScrollView(
        // Wrap the content in SingleChildScrollView for scrolling
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
                  userRole == null ? CircularProgressIndicator() : _getDashboard(),
                  UserPoints(),
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
                        // Display the event list horizontally
                        Container(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: validUpcomingEvents.length, // Changed here
                            itemBuilder: (context, index) {
                              var event = validUpcomingEvents[index]; // Changed here
                              // v-- 2. WRAP EVENT CARD WITH GESTUREDETECTOR --v
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailPage(event: event),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Container(
                                    width: 160,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Event Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            event["bannerUrl"] ?? '',
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Event Name
                                        SizedBox(
                                          height: 36,
                                          child: Text(
                                            event["eventName"] ?? "Unknown",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        // Points and Date
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
                                                Expanded(
                                                  child: Text(
                                                    event["eventEndDate"] ?? "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ...sectionEvents.entries
                            .where((entry) => entry.key != "Upcoming Activities")
                            .map((entry) => _buildSectionRow(entry.key, entry.value)),
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
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildSectionRow(String sectionName, List<DocumentSnapshot> events) {
    // --- Start of modification ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final validEvents = events.where((event) {
      String eventEndDateString = event["eventEndDate"] ?? "";
      if (eventEndDateString.isNotEmpty) {
        try {
          DateTime eventEndDate = DateFormat('dd MMM yyyy HH:mm').parse(eventEndDateString);
          return !eventEndDate.isBefore(today);
        } catch (e) {
          print("Error parsing date: $e");
          return false;
        }
      }
      return true; // Keep events without an end date
    }).toList();


    validEvents.sort((a, b) {
      // --- End of modification ---
      Timestamp aTimestamp = a["updatedAt"];
      Timestamp bTimestamp = b["updatedAt"];
      return bTimestamp.compareTo(aTimestamp);
    });
    if (validEvents.isEmpty) {
      return SizedBox.shrink();
    }

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
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: validEvents.length, // Changed here
              itemBuilder: (context, index) {
                var event = validEvents[index]; // Changed here
                // v-- 3. WRAP THIS CARD WITH GESTUREDETECTOR AS WELL --v
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: event),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event["bannerUrl"] ?? '',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Event Name
                          SizedBox(
                            height: 36,
                            child: Text(
                              event["eventName"] ?? "Unknown",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Points and Date
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
                                  Expanded(
                                    child: Text(
                                      event["eventEndDate"] ?? "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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