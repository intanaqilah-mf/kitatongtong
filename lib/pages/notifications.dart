import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedIndex = 3;
  Stream<QuerySnapshot> _notificationsStream = Stream.empty();
  String? _userRole;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // pages/notifications.dart

  Future<void> _initializeNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("DEBUG: No user is currently logged in.");
      if (mounted) {
        setState(() {
          _notificationsStream = Stream.empty();
        });
      }
      return;
    }

    _userId = user.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();

    if (mounted) {
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _userRole = data['role'] ?? 'asnaf';
      } else {
        _userRole = 'asnaf'; // Default role if user doc doesn't exist
      }

      // This single query block correctly handles all cases.
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('notifications');

      if (_userRole == 'staff') {
        // For Staff: Fetch notifications where recipients array contains 'ROLE_STAFF' OR the specific staff's user ID.
        query = query.where('recipients', arrayContainsAny: ['ROLE_STAFF', _userId!]);
      } else if (_userRole == 'admin') {
        // For Admin: Fetch notifications where recipients array contains 'ROLE_ADMIN'.
        query = query.where('recipients', arrayContains: 'ROLE_ADMIN');
      } else {
        // For Asnaf: Fetch notifications where recipients array contains the specific asnaf's user ID.
        query = query.where('recipients', arrayContains: _userId);
      }

      // Set the state only ONCE with the final, correct query.
      setState(() {
        _notificationsStream = query.orderBy('createdAt', descending: true).snapshots();
      });

      print("DEBUG: Notifications stream initialized for role: $_userRole");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizations.translate('notifications_title'),
          style: TextStyle(
            color: Color(0xFFFDB515),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFFDB515)));
          }
          if (snap.hasError) {
            print("DEBUG: Firestore Stream Error: ${snap.error}"); // Add error logging
            return Center(
              child: Text(
                "${localizations.translate('notifications_error_loading')}\n${snap.error}",
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          print("DEBUG: Found ${docs.length} notifications."); // Log how many docs are found
          if (docs.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('notifications_none'),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;
              final time = timestamp != null
                  ? DateFormat("dd MMMiotsit, hh:mm a").format(timestamp.toDate())
                  : localizations.translate('notifications_no_date');
              final message = data['message'] ?? localizations.translate('notifications_no_message');

              return Card(
                color: Colors.grey[850],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notifications, color: Color(0xFFFDB515), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(color: Colors.white, fontSize: 14),
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
