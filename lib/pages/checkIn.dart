import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successCheckIn.dart';
import 'package:projects/pages/qr_scanner_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


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
  Timer? _debounce;
  int _selectedIndex = 0;
  String? _role;
  String? _staffName;
  String? _participantDocId;

  LatLng? _eventLocation;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _fetchEventDetails(String code) async {
    final trimmedCode = code.trim();

    if (trimmedCode.isEmpty) {
      _clearForm();
      return;
    }

    final eventQuery = await FirebaseFirestore.instance
        .collection('event')
        .where('attendanceCode', isEqualTo: trimmedCode)
        .limit(1)
        .get();

    if (mounted && eventQuery.docs.isNotEmpty) {
      final eventData = eventQuery.docs.first.data();
      final locationData = eventData['location'];

      setState(() {
        _eventNameController.text = eventData['eventName'] ?? '';
        _pointsController.text = eventData['points'].toString();

        if (locationData is Map && locationData['latitude'] != null && locationData['longitude'] != null) {
          _eventLocation = LatLng(locationData['latitude'], locationData['longitude']);
        } else {
          _eventLocation = null;
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Attendance Code.")),
      );
      _clearForm();
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
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
        _fetchEventDetails(qrCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR scan cancelled or no data found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening QR scanner: $e")),
      );
    }
  }

  // Debounced search for Asnaf by NRIC
  void _onNricChanged(String nric) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 10), () {
      if (nric.trim().isNotEmpty) {
        _fetchAsnafDetailsByNric(nric.trim());
      } else {
        _participantNameController.clear();
        _participantNumberController.clear();
        setState(() => _participantDocId = null);
      }
    });
  }


  void _fetchAsnafDetailsByNric(String nric) async {
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('nric', isEqualTo: nric)
        .limit(1)
        .get();

    if (!mounted) return;

    if (userQuery.docs.isNotEmpty) {
      final asnafData = userQuery.docs.first.data();
      setState(() {
        _participantNameController.text = asnafData['name'] ?? 'No Name Found';
        _participantNumberController.text = asnafData['phone'] ?? 'No Phone Found';
        _participantDocId = userQuery.docs.first.id;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user found with this NRIC.")),
      );
      setState(() {
        _participantNameController.clear();
        _participantNumberController.clear();
        _participantDocId = null;
      });
    }
  }

  void _initUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (mounted && userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        _role = userData['role'] ?? 'asnaf';
        _staffName = userData['name'];

        if (_role == 'asnaf') {
          _participantNameController.text = userData['name'] ?? '';
          _participantNumberController.text = userData['phone'] ?? '';
        } else {
          _participantNameController.clear();
          _participantNumberController.clear();
          _nricController.clear();
        }
      });
    }
  }

  void _clearForm() {
    _attendanceCodeController.clear();
    _eventNameController.clear();
    _pointsController.clear();
    _eventLocation = null;

    if (_role == 'staff') {
      _nricController.clear();
      _participantNameController.clear();
      _participantNumberController.clear();
      _participantDocId = null;
    }
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
                "I am participating in an event",
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
                              onChanged: _fetchEventDetails,
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
                  label: "Event",
                  controller: _eventNameController,
                  hint: "Event name will appear here",
                  isReadOnly: true),
              if (_role == 'staff')
                buildTextField(
                    label: "Enter Asnaf NRIC",
                    controller: _nricController,
                    hint: "e.g., 990101-01-5555",
                    onChanged: _onNricChanged), // Use debounced function
              buildTextField(
                  label: "Participant's Name",
                  controller: _participantNameController,
                  hint: _role == 'staff' ? "Asnaf's name will appear here" : "Enter your name",
                  isReadOnly: _role == 'staff'),
              buildParticipantNumberField(),
              buildTextField(
                  label: "Points per attendance",
                  controller: _pointsController,
                  hint: "Points will appear here",
                  isReadOnly: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitCheckIn,
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

  Future<void> _submitCheckIn() async {
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid event code.")),
      );
      return;
    }
    if (_role == 'staff' && _participantDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid NRIC to find an Asnaf.")),
      );
      return;
    }
    if (_eventLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event location is not available for verification.")),
      );
      return;
    }


    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Verifying location..."),
            ]),
          ),
        ),
      );

      final Position? currentPosition = await _determinePosition();
      Navigator.pop(context); // Dismiss loading dialog

      if (currentPosition == null) return;

      final double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _eventLocation!.latitude,
        _eventLocation!.longitude,
      );

      if (distanceInMeters > 10000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Check-in failed: You are more than 10km away from the event.")),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser!;
      final pointsToAdd = int.tryParse(_pointsController.text) ?? 0;

      final submittedBy = _role == 'staff'
          ? {"uid": currentUser.uid, "name": _staffName, "role": _role}
          : "system";

      final eventQuery = await FirebaseFirestore.instance
          .collection('event')
          .where('attendanceCode', isEqualTo: _attendanceCodeController.text.trim())
          .limit(1)
          .get();

      final eventDate = eventQuery.docs.isNotEmpty
          ? eventQuery.docs.first.data()['eventDate']
          : "Unknown";

      await FirebaseFirestore.instance.collection("checkIn_list").add({
        "attendanceCode": _attendanceCodeController.text.trim(),
        "eventName": _eventNameController.text,
        "points": pointsToAdd,
        "participantName": _participantNameController.text,
        "participantNumber": _participantNumberController.text,
        "checkedInAt": Timestamp.now(),
        "eventDate": eventDate,
        "submittedBy": submittedBy,
        "participantId": _role == 'staff' ? _participantDocId : currentUser.uid,
      });

      String participantToUpdateId = _role == 'staff' ? _participantDocId! : currentUser.uid;

      final participantDocRef = FirebaseFirestore.instance.collection("users").doc(participantToUpdateId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final participantSnapshot = await transaction.get(participantDocRef);
        final currentPoints = participantSnapshot.data()?['points'] ?? 0;
        transaction.update(participantDocRef, {'points': currentPoints + pointsToAdd});
      });


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => successCheckIn()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Check-in successful!")),
      );

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print("Error during check-in submission: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to check in. An unexpected error occurred.")),
      );
    }
  }

  Widget buildParticipantNumberField() {
    return Padding(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "+60",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                Container(width: 1, height: 48, color: Colors.black45),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _participantNumberController,
                    readOnly: _role == 'staff',
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                      hintText: _role == 'staff' ? "Asnaf's phone number" : "Your phone number",
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = "",
    bool isReadOnly = false,
    Function(String)? onChanged,
  }) {
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
                hintText: hint,
                hintStyle: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
