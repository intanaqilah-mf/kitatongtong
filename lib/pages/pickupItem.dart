import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/pickupSuccess.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/pickupFail.dart';
import 'package:intl/intl.dart';
import 'face_validation_screen.dart'; // Import the new screen

class PickUpItem extends StatefulWidget {
  @override
  _PickUpItemState createState() => _PickUpItemState();
}

class _PickUpItemState extends State<PickUpItem> {
  // Use more descriptive names for controllers
  final TextEditingController _pickupCodeController = TextEditingController();
  final TextEditingController _rewardRedeemedController = TextEditingController();
  final TextEditingController _asnafNameController = TextEditingController();
  final TextEditingController _asnafNumberController = TextEditingController();

  int _selectedIndex = 0;
  String? docIdToUpdate;
  bool _isLoading = false;
  bool _isVerified = false; // To track if validation was successful

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Main function to start the verification flow
  Future<void> _initiateVerification() async {
    final String code = _pickupCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a pickup code.")));
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerified = false;
      _clearAllFields(); // Clear previous data
    });

    try {
      // 1. Find the pickup order in 'redeemedKasih' collection
      final pickupSnapshot = await FirebaseFirestore.instance
          .collection('redeemedKasih')
          .where('pickupCode', isEqualTo: code)
          .limit(1)
          .get();

      if (pickupSnapshot.docs.isEmpty) {
        _showError("Pickup code not found.");
        return;
      }

      final pickupData = pickupSnapshot.docs.first.data();
      docIdToUpdate = pickupSnapshot.docs.first.id;

      // 2. Fetch the user's data to get the selfie URL
      final String userId = pickupData['userId'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists || userDoc.data()?['selfieImageUrl'] == null) {
        _showError("Asnaf eKYC photo not found. User may not have completed the verification process.");
        return;
      }
      final userData = userDoc.data()!;
      final String ekycSelfieUrl = userData['selfieImageUrl'];

      // 3. Navigate to FaceValidationScreen
      if (!mounted) return;
      final bool? isMatch = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceValidationScreen(ekycSelfieImageUrl: ekycSelfieUrl),
        ),
      );

      // 4. Handle the result from the validation screen
      if (isMatch == true) {
        // If validation is successful, populate the fields
        setState(() {
          _rewardRedeemedController.text = pickupData['valueRedeemed']?.toString() ?? 'N/A';
          _asnafNameController.text = pickupData['userName'] ?? 'N/A';
          _asnafNumberController.text = userData['phone'] ?? 'N/A';
          _isVerified = true; // Mark as verified to enable the submit button
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Validation successful. Details loaded."),
          backgroundColor: Colors.green,
        ));
      } else {
        _showError("Face validation failed or was rejected by staff.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitPickup() async {
    if (!_isVerified || docIdToUpdate == null) {
      _showError("Please verify the Asnaf's identity first.");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final docRef = FirebaseFirestore.instance.collection("redeemedKasih").doc(docIdToUpdate!);
      final docSnap = await docRef.get();

      if(docSnap.data()?['pickedUp'] == 'yes') {
        final pickedUpAt = (docSnap.data()?['pickedUpAt'] as Timestamp?)?.toDate();
        String formattedPickedUpAt = pickedUpAt != null
            ? DateFormat("d MMM yyyy, h:mm a").format(pickedUpAt)
            : "an unknown date";
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => PickupFail(
          name: _asnafNameController.text,
          phone: _asnafNumberController.text,
          reward: _rewardRedeemedController.text,
          pickupCode: _pickupCodeController.text,
          pickedUpAt: formattedPickedUpAt,
        )), (route) => false,);
        return;
      }

      await docRef.update({
        "pickedUp": "yes",
        "pickedUpAt": FieldValue.serverTimestamp(),
      });

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => pickupSuccess(
        name: _asnafNameController.text,
        phone: _asnafNumberController.text,
        reward: _rewardRedeemedController.text,
        pickupCode: _pickupCodeController.text,
      )), (route) => false,);

    } catch (e) {
      _showError("Failed to submit pickup: $e");
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  void _clearAllFields() {
    _rewardRedeemedController.clear();
    _asnafNameController.clear();
    _asnafNumberController.clear();
    docIdToUpdate = null;
    _isVerified = false;
  }

  void _showError(String message) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
      setState(() { _isLoading = false; _clearAllFields(); });
    }
  }

  @override
  void dispose() {
    _pickupCodeController.dispose();
    _rewardRedeemedController.dispose();
    _asnafNameController.dispose();
    _asnafNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 70),
              Text(
                "Verify Pickup Code Here",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                "Enter pickup code to begin face validation",
                style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              buildTextField("Enter Pickup Code", _pickupCodeController, isReadOnly: false),
              SizedBox(height: 10),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _initiateVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFDB515),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text("Verify Asnaf Identity", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              SizedBox(height: 20),
              Divider(color: Colors.white24),
              SizedBox(height: 10),
              buildTextField("Reward Redeemed", _rewardRedeemedController, isReadOnly: true),
              buildTextField("Asnaf's Name", _asnafNameController, isReadOnly: true),
              buildMobileField("Asnaf's Number", _asnafNumberController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerified && !_isLoading ? _submitPickup : null, // Enabled only after successful verification
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.green : Colors.grey[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("Confirm & Submit Pickup", style: TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget buildTextField(String label, TextEditingController controller, {bool isReadOnly = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: isReadOnly,
            style: TextStyle(color: isReadOnly ? Colors.white70 : Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text("+60", style: TextStyle(fontSize: 16, color: Colors.white70)),
                ),
                Container(width: 1, height: 24, color: Colors.white24),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: true,
                    style: TextStyle(color: Colors.white70),
                    decoration: InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
