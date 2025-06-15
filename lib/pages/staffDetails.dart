import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class StaffDetailScreen extends StatefulWidget {
  final String documentId;
  StaffDetailScreen({required this.documentId});

  @override
  _StaffDetailScreenState createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  int _selectedIndex = 0;
  String selectedRole = "";
  bool _roleLoaded = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateRole() async {
    final loc = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.documentId)
          .update({
        'role': selectedRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('staffDetails_update_success'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translateWithArgs('staffDetails_update_error', {'error': e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.documentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                loc.translate('staffDetails_no_data'),
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var name = userData['name'] ?? 'N/A';
          var email = userData['email'] ?? 'N/A';
          var phone = userData['phone'] ?? 'N/A';
          var nric = userData['nric'] ?? 'N/A';
          var address = userData['address'] ?? '';
          var city = userData['city'] ?? '';
          var postcode = userData['postcode'] ?? '';
          var photoUrl = userData['photoUrl'] ?? '';
          var points = (userData['points'] ?? 'N/A').toString();
          var currentRole = userData['role'] ?? 'staff';

          var fullAddress = [address, city, postcode]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          if (fullAddress.isEmpty) fullAddress = 'N/A';

          String formattedDate(Timestamp? timestamp) {
            if (timestamp == null) return 'N/A';
            return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
          }

          var createdAt = formattedDate(userData['created_at'] as Timestamp?);
          var lastLogin = formattedDate(userData['last_login'] as Timestamp?);

          // Updated logic for eKYC status
          var ekycTimestamp = userData['ekycVerifiedOn'] as Timestamp?;
          var ekycVerifiedOn = ekycTimestamp == null
              ? loc.translate('staffDetails_not_applicable')
              : DateFormat('dd MMM yyyy, hh:mm a').format(ekycTimestamp.toDate());


          if (!_roleLoaded) {
            selectedRole = currentRole.toString().toLowerCase();
            _roleLoaded = true;
          }

          String getDisplayRole(String roleKey) {
            switch (roleKey.toLowerCase()) {
              case 'admin':
                return loc.translate('staffDetails_role_admin');
              case 'staff':
                return loc.translate('staffDetails_role_staff');
              case 'asnaf':
                return loc.translate('staffDetails_role_asnaf');
              default:
                return roleKey;
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 50.0),
                  Text(
                    loc.translate('staffDetails_title'),
                    style: TextStyle(
                      color: Color(0xFFFDB515),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15.0),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
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
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty
                                ? Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF303030),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        textRow(loc.translate('staffDetails_label_fullName'), name),
                        textRow(loc.translate('staffDetails_label_nric'), nric),
                        textRow(loc.translate('staffDetails_label_email'), email),
                        textRow(loc.translate('staffDetails_label_phone'), phone),
                        textRow(loc.translate('staffDetails_label_address'), fullAddress),
                        textRow(loc.translate('staffDetails_label_role'), getDisplayRole(currentRole)),
                        textRow(loc.translate('staffDetails_label_account_created'), createdAt),
                        textRow(loc.translate('staffDetails_label_last_login'), lastLogin),
                        textRow(loc.translate('staffDetails_label_ekyc_verified'), ekycVerifiedOn),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(loc.translate('staffDetails_label_role'), style: TextStyle(color: Colors.white, fontSize: 16)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        items: ["admin", "staff", "asnaf"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              getDisplayRole(value),
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedRole = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFDB515),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        loc.translate('staffDetails_submit_button'),
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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