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
import 'package:projects/pages/EventDetailPage.dart';
import 'package:url_launcher/url_launcher.dart';


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
                          height: 230,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: validUpcomingEvents.length, // Changed here
                            itemBuilder: (context, index) {
                              var eventData = validUpcomingEvents[index].data() as Map<String, dynamic>;
                              var eventDoc = validUpcomingEvents[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailPage(event: eventDoc),
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
                                            eventData["bannerUrl"] ?? '',
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(height: 100, color: Colors.grey.shade300, child: Icon(Icons.image_not_supported)),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Event Name
                                        SizedBox(
                                          height: 36,
                                          child: Text(
                                            eventData["eventName"] ?? "Unknown",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Points
                                        Text(
                                          "Get ${eventData["points"] ?? "0"} pts",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Date
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: Colors.red, size: 14),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                eventData["eventEndDate"] ?? "",
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
                                        SizedBox(height: 4),
                                        // Location
                                        _buildLocationRow(eventData['location']),
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

  Widget _buildLocationRow(dynamic locationData) {
    String address = "No location";
    bool isTappable = false;

    if (locationData is Map) {
      address = locationData['address'] ?? 'No location';
      isTappable = locationData['latitude'] != null && locationData['longitude'] != null;
    } else if (locationData is String && locationData.isNotEmpty) {
      address = locationData;
    }

    return GestureDetector(
      onTap: () async {
        if (isTappable) {
          final lat = locationData['latitude'];
          final lng = locationData['longitude'];
          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: isTappable ? Colors.blue.shade800 : Colors.grey, size: 14),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionRow(String sectionName, List<DocumentSnapshot> events) {
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
      return true;
    }).toList();

    validEvents.sort((a, b) {
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
          Text(
            sectionName,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Container(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: validEvents.length,
              itemBuilder: (context, index) {
                var eventDoc = validEvents[index];
                var eventData = eventDoc.data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: eventDoc),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              eventData["bannerUrl"] ?? '',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(height: 100, color: Colors.grey.shade300, child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: Text(
                              eventData["eventName"] ?? "Unknown",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Get ${eventData["points"] ?? "0"} pts",
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
                                  eventData["eventEndDate"] ?? "",
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
                          SizedBox(height: 4),
                          _buildLocationRow(eventData['location']),
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