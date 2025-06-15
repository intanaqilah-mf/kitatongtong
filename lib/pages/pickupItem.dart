import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/pages/pickupSuccess.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/pickupFail.dart';
import 'package:intl/intl.dart';
import 'face_validation_screen.dart';
import 'qr_scanner_page.dart';

class PickUpItem extends StatefulWidget {
  @override
  _PickUpItemState createState() => _PickUpItemState();
}

class _PickUpItemState extends State<PickUpItem> {
  final TextEditingController _pickupCodeController = TextEditingController();
  final TextEditingController _rewardRedeemedController = TextEditingController();
  final TextEditingController _asnafNameController = TextEditingController();
  final TextEditingController _asnafNumberController = TextEditingController();

  int _selectedIndex = 0;
  String? docIdToUpdate;
  bool _isLoading = false;
  bool _isVerified = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _scanQRCode() async {
    final loc = AppLocalizations.of(context)!;
    try {
      final String? qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );

      if (!mounted) return;

      // This delay prevents camera resource conflicts
      await Future.delayed(const Duration(milliseconds: 300));

      if (qrCode != null && qrCode.isNotEmpty) {
        _pickupCodeController.text = qrCode;
        _initiateVerification();
      }
    } catch (e) {
      _showError("${loc.translate('pickupItem_error_scan')}$e");
    }
  }

  Future<void> _initiateVerification() async {
    final loc = AppLocalizations.of(context)!;
    final String code = _pickupCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('pickupItem_error_no_code'))));
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerified = false;
      _clearAllFields();
    });

    try {
      final pickupSnapshot = await FirebaseFirestore.instance
          .collection('redeemedKasih')
          .where('pickupCode', isEqualTo: code)
          .limit(1)
          .get();

      if (pickupSnapshot.docs.isEmpty) {
        _showError(loc.translate('pickupItem_error_not_found'));
        return;
      }

      final pickupData = pickupSnapshot.docs.first.data();
      docIdToUpdate = pickupSnapshot.docs.first.id;

      if(pickupData['pickedUp'] == 'yes') {
        _showError(loc.translate('pickupItem_error_already_picked_up'));
        return;
      }

      if(pickupData['processedOrder'] != 'yes') {
        _showError(loc.translate('pickupItem_error_not_processed'));
        return;
      }

      final String userId = pickupData['userId'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists || userDoc.data()?['selfieImageUrl'] == null) {
        _showError(loc.translate('pickupItem_error_no_ekyc'));
        return;
      }
      final userData = userDoc.data()!;
      final String ekycSelfieUrl = userData['selfieImageUrl'];

      if (!mounted) return;
      final bool? isMatch = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceValidationScreen(ekycSelfieImageUrl: ekycSelfieUrl),
        ),
      );

      if (isMatch == true) {
        setState(() {
          _rewardRedeemedController.text = pickupData['valueRedeemed']?.toString() ?? 'N/A';
          _asnafNameController.text = pickupData['userName'] ?? 'N/A';
          _asnafNumberController.text = userData['phone'] ?? 'N/A';
          _isVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.translate('pickupItem_success_validation')),
          backgroundColor: Colors.green,
        ));
      } else {
        _showError(loc.translate('pickupItem_error_validation_failed'));
      }
    } catch (e) {
      _showError("${loc.translate('pickupItem_error_generic')}$e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitPickup() async {
    final loc = AppLocalizations.of(context)!;
    if (!_isVerified || docIdToUpdate == null) {
      _showError(loc.translate('pickupItem_error_verify_first'));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      await FirebaseFirestore.instance.collection("redeemedKasih").doc(docIdToUpdate!).update({
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
      _showError("${loc.translate('pickupItem_error_submit_failed')}$e");
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
      setState(() { _isLoading = false; _pickupCodeController.clear(); _clearAllFields(); });
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
    final loc = AppLocalizations.of(context)!;
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
                loc.translate('pickupItem_page_title'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                loc.translate('pickupItem_page_subtitle'),
                style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              buildPickupCodeField(),
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
                  child: Text(loc.translate('pickupItem_verify_button'), style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              SizedBox(height: 20),
              Divider(color: Colors.white24),
              SizedBox(height: 10),
              buildInfoTextField(loc.translate('pickupItem_reward_redeemed_label'), _rewardRedeemedController),
              buildInfoTextField(loc.translate('pickupItem_asnaf_name_label'), _asnafNameController),
              buildMobileField(loc.translate('pickupItem_asnaf_number_label'), _asnafNumberController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerified && !_isLoading ? _submitPickup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.green : Colors.grey[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(loc.translate('pickupItem_submit_button'), style: TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget buildPickupCodeField() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.translate('pickupItem_code_field_label'), style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pickupCodeController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      hintText: loc.translate('pickupItem_code_field_hint'),
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: Color(0xFFFDB515)),
                  onPressed: _scanQRCode,
                  tooltip: loc.translate('pickupItem_scan_qr_tooltip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: true,
            style: TextStyle(color: Colors.white70),
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
