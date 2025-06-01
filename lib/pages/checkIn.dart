import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successCheckIn.dart';
import 'package:projects/pages/qr_scanner_page.dart';

final TextEditingController _attendanceCodeController = TextEditingController();
final TextEditingController _eventNameController = TextEditingController();
final TextEditingController _pointsController = TextEditingController();
final TextEditingController _participantNameController = TextEditingController();
final TextEditingController _participantNumberController = TextEditingController();
final TextEditingController _nricController = TextEditingController();

class checkIn extends StatefulWidget {
  @override
  _checkInState createState() => _checkInState();
}

class _checkInState extends State<checkIn> {
  Map<String, String> formData = {};
  int _selectedIndex = 0;
  String? currentUserEmail;
  String? _role;
  String? _staffName;
  String? _participantDocId; // New variable to store the participant's document ID

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _fetchEventDetails(String code) async {
    final trimmed = code.trim();

    if (trimmed.isEmpty) {
      _clearForm();
      return;
    }

    final eventDoc = await FirebaseFirestore.instance
        .collection('event')
        .where('attendanceCode', isEqualTo: trimmed)
        .get();

    if (eventDoc.docs.isNotEmpty) {
      final eventData = eventDoc.docs.first.data();

      setState(() {
        _eventNameController.text = eventData['eventName'] ?? '';
        _pointsController.text = eventData['points'].toString();

        if (_role == 'staff') {
          _participantNameController.text = '';
          _participantNumberController.text = '';
          _participantDocId = null;
        }
      });
    } else {
      _clearForm();
    }
  }

  Future<void> _scanQRCode() async {
    try {
      final String? qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );

      if (!mounted) return;

      if (qrCode != null && qrCode.isNotEmpty) {
        _attendanceCodeController.text = qrCode;
        _fetchEventDetails(qrCode); // Fetch event details with the scanned code
      } else {
        // This can happen if the user navigates back without scanning
        // or if the scanner page pops with null.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR scan cancelled or no data found.")),
        );
      }
    } catch (e) {
      // This catch block is for potential errors during navigation or if the scanner page itself has an unhandled error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening QR scanner: $e")),
      );
      print("Error opening QR scanner: $e");
    }
  }

  void _fetchAsnafDetails(String nric) async {
    final trimmed = nric.trim();

    if (trimmed.isEmpty) {
      _participantNameController.clear();
      _participantNumberController.clear();
      setState(() {
        _participantDocId = null;
      });
      return;
    }

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('nric', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userData = userQuery.docs.first.data();
      setState(() {
        _participantNameController.text = userData['name'] ?? '';
        _participantNumberController.text = userData['phone'] ?? '';
        _participantDocId = userQuery.docs.first.id; // Store the doc ID when found
      });
    } else {
      _participantNameController.clear();
      _participantNumberController.clear();
      setState(() {
        _participantDocId = null;
      });
    }
  }

  void _initUserDetails() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        _role = userData['role'] ?? 'asnaf';
        _staffName = userData['name'] ?? '';

        if (_role == 'asnaf') {
          _participantNameController.text = userData['name'] ?? '';
          _participantNumberController.text = userData['phone'] ?? '';
        }
      });
    }
  }

  void _clearForm() {
    setState(() {
      _eventNameController.clear();
      _pointsController.clear();

      if (_role == 'staff') {
        _participantNameController.clear();
        _participantNumberController.clear();
        _nricController.clear();
        _participantDocId = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 70),
              Text(
                "Check-In Event",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDB515),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "I am participating event",
                style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter Attendance Code or Scan QR",
                      style: TextStyle(
                          color: Color(0xFFFDB515),
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                          color: Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _attendanceCodeController,
                              onChanged: (value) {
                                // You might want to add a debounce here if fetching on every keystroke
                                if (value.isNotEmpty) {
                                  _fetchEventDetails(value);
                                } else {
                                  _clearForm(); // Clear related fields if code is erased
                                }
                              },
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Enter code manually",
                                hintStyle: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner, color: Colors.black),
                            onPressed: _scanQRCode,
                            tooltip: 'Scan QR Code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              buildTextField(
                  "Event", "eventName", _eventNameController,
                  isReadOnly: true),
              if (_role == 'staff')
                buildTextField("Enter Asnaf NRIC", "nric", _nricController,
                    isReadOnly: false, onChanged: _fetchAsnafDetails),
              buildTextField("Participant's Name", "name",
                  _participantNameController,
                  isReadOnly: true),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Participant’s Number",
                      style: TextStyle(
                          color: Color(0xFFFDB515),
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                          color: Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "+60",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _participantNumberController,
                              readOnly: true,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Participant's phone number",
                                hintStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              buildTextField("Points per attendance", "points", _pointsController,
                  isReadOnly: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userId =
                        FirebaseAuth.instance.currentUser!.uid;
                    final userDoc = await FirebaseFirestore.instance
                        .collection("users")
                        .doc(userId)
                        .get();
                    final role = userDoc.data()?['role'] ?? 'asnaf';
                    final name = userDoc.data()?['name'] ?? '';
                    final pointsToAdd =
                        int.tryParse(_pointsController.text) ?? 0;

                    final submittedBy = role == 'staff'
                        ? {
                      "uid": userId,
                      "name": name,
                      "role": role,
                    }
                        : "system";

                    // Fetch event date before storing
                    final eventQuery = await FirebaseFirestore.instance
                        .collection('event')
                        .where('attendanceCode',
                        isEqualTo:
                        _attendanceCodeController.text.trim())
                        .limit(1)
                        .get();

                    final eventDate = eventQuery.docs.isNotEmpty
                        ? eventQuery.docs.first.data()['eventDate']
                        : "Unknown";

                    // Store the check-in details
                    await FirebaseFirestore.instance
                        .collection("checkIn_list")
                        .add({
                      "attendanceCode": _attendanceCodeController.text,
                      "eventName": _eventNameController.text,
                      "points": pointsToAdd,
                      "participantName": _participantNameController.text,
                      "participantNumber": _participantNumberController.text,
                      "checkedInAt": Timestamp.now(),
                      "eventDate": eventDate,
                      "submittedBy": submittedBy,
                    });

                    // Update participant points using the exact document ID.
                    // For staff, if a participant was looked up via NRIC, use that document.
                    // Otherwise (as asnaf) use the current user's UID.
                    String participantId;
                    if (role == 'staff' && _participantDocId != null) {
                      participantId = _participantDocId!;
                    } else {
                      participantId = FirebaseAuth.instance.currentUser!.uid;
                    }
                    final participantSnapshot = await FirebaseFirestore.instance
                        .collection("users")
                        .doc(participantId)
                        .get();
                    final participantPoints =
                        participantSnapshot.data()?['points'] ?? 0;
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(participantId)
                        .update(
                        {'points': participantPoints + pointsToAdd});

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => successCheckIn()),
                          (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Check-in successful!")),
                    );
                  } catch (e) {
                    print("Error storing check-in: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Failed to check in. Please try again.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFDB515),
                  padding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Center(
                    child: Text("Submit",
                        style: TextStyle(fontSize: 16, color: Colors.white))),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }


  Widget buildTextField(String label, String key,
      TextEditingController controller,
      {bool isReadOnly = false, Function(String)? onChanged}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: Color(0xFFFDB515),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
                color: Color(0xFFFDB515),
                borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              onChanged: onChanged,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
