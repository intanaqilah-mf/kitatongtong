import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/verifyReviewScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ScreeningApplicants extends StatefulWidget {
  final String documentId;

  ScreeningApplicants({required this.documentId});

  @override
  _ScreeningApplicantsState createState() => _ScreeningApplicantsState();
}

class _ScreeningApplicantsState extends State<ScreeningApplicants> {
  int _selectedIndex = 0;
  String selectedStatus = "Approve";
  TextEditingController reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplicationData();
  }

  void _loadApplicationData() async {
    var snapshot = await fetchApplicationData(widget.documentId);
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        reasonController.text = data['reasonStatus'] ?? '';
        selectedStatus = data['statusApplication'] ?? 'Approve';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<DocumentSnapshot> fetchApplicationData(String documentId) async {
    return await FirebaseFirestore.instance.collection('applications').doc(documentId).get();
  }

  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  void submitStatus() async {
    final loc = AppLocalizations.of(context)!;
    String finalStatus = selectedStatus;
    if (selectedStatus.isEmpty) {
      finalStatus = "Pending";
    }
    String rewardStatus = 'Pending';
    if (finalStatus == 'Reject') {
      rewardStatus = 'Reject';
    }

    try {
      await FirebaseFirestore.instance.collection('applications').doc(widget.documentId).update({
        'statusApplication': finalStatus,
        'reasonStatus': reasonController.text,
        'statusReward': rewardStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('screening_update_success'))),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => VerifyReviewScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        backgroundColor: Color(0xFF303030),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFDB515)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.translate('screening_title'),
          style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: fetchApplicationData(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
          }
          if (snapshot.hasError) {
            return Center(child: Text(loc.translateWithArgs('screening_error_generic', {'error': snapshot.error.toString()}), style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(loc.translate('screening_no_data'), style: TextStyle(color: Colors.white)));
          }

          final applicationData = snapshot.data!.data() as Map<String, dynamic>;
          final userId = applicationData['userId'];
          final submittedBy = applicationData['submittedBy'];
          final isStaffSubmission = submittedBy is Map;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoldenBox(applicationData, userId, isStaffSubmission),
                SizedBox(height: 24),
                _buildStatusSection(),
                SizedBox(height: 24),
                _buildReasonSection(),
                SizedBox(height: 30),
                _buildSubmitButton(),
              ],
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

  Widget _buildGoldenBox(Map<String, dynamic> appData, dynamic userId, bool isStaffSubmission) {
    final loc = AppLocalizations.of(context)!;
    String address = [
      appData['addressLine1'],
      appData['addressLine2'],
      appData['postcode'],
      appData['city'],
      appData['state']
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9F295),
            Color(0xFFE0AA3E),
            Color(0xFFF9F295),
            Color(0xFFB88A44),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(appData, userId, isStaffSubmission),
          Divider(color: Colors.black54, thickness: 1, height: 24),
          _buildInfoRow(Icons.badge_outlined, loc.translate('screening_nric_label'), appData['nric'] ?? 'N/A'),
          _buildInfoRow(Icons.phone_outlined, loc.translate('screening_mobile_label'), "60${appData['mobileNumber'] ?? 'N/A'}"),
          _buildInfoRow(Icons.email_outlined, loc.translate('screening_email_label'), appData['email'] ?? 'N/A'),
          _buildInfoRow(Icons.home_outlined, loc.translate('screening_address_label'), address),
          _buildInfoRow(Icons.flag_outlined, loc.translate('screening_residency_label'), appData['residencyStatus'] ?? 'N/A'),
          _buildInfoRow(Icons.work_outline, loc.translate('screening_employment_label'), appData['employmentStatus'] ?? 'N/A'),
          if (appData['employmentStatus'] == 'Employed') ...[
            _buildInfoRow(Icons.business_center_outlined, loc.translate('screening_occupation_label'), appData['occupation'] ?? 'N/A'),
            _buildInfoRow(Icons.attach_money_outlined, loc.translate('screening_income_label'), "RM ${appData['monthlyIncome'] ?? 'N/A'}"),
          ],
          if (appData['employmentStatus'] == 'Unemployed' && appData['isAsnaf'] == 'Yes')
            _buildInfoRow(Icons.groups_outlined, loc.translate('screening_asnaf_in_label'), appData['asnafIn'] ?? 'N/A'),
          _buildInfoRow(Icons.lightbulb_outline, loc.translate('screening_justification_label'), appData['justificationApplication'] ?? 'N/A'),
          Divider(color: Colors.black54, thickness: 1, height: 24),
          _buildDocumentSection(appData),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> appData, dynamic userId, bool isStaffSubmission) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        (userId != null)
            ? FutureBuilder<DocumentSnapshot>(
          future: fetchUserData(userId),
          builder: (context, userSnapshot) {
            String? photoUrl;
            if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData) {
              photoUrl = (userSnapshot.data!.data() as Map<String, dynamic>)['photoUrl'];
            }
            return CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black26,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, size: 28, color: Colors.white70) : null,
            );
          },
        )
            : CircleAvatar(
          radius: 28,
          backgroundColor: Colors.black26,
          child: Icon(Icons.person, size: 28, color: Colors.white70),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appData['fullname'] ?? 'N/A',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                appData['applicationCode'] ?? loc.translate('verifyApp_no_code'),
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (isStaffSubmission)
                Text(
                  loc.translateWithArgs('verifyApp_submitted_by', {'name': appData['submittedBy']['name'] ?? loc.translate('screening_unknown_staff')}),
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black87, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                Text(value, style: TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(Map<String, dynamic> appData) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('screening_documents_title'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
        SizedBox(height: 8),
        _buildDocumentLink(loc.translate('screening_doc_proof_address'), appData['proofOfAddress']),
        if (appData['employmentStatus'] == 'Employed')
          _buildDocumentLink(loc.translate('screening_doc_proof_income'), appData['proofOfIncome']),
      ],
    );
  }

  Widget _buildDocumentLink(String label, String? filePath) {
    final loc = AppLocalizations.of(context)!;
    bool hasFile = filePath != null && filePath.isNotEmpty && filePath != 'No file uploaded';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: hasFile ? () => _openFile(filePath) : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasFile ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: hasFile ? Colors.black : Colors.black38, size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text(label, style: TextStyle(color: hasFile ? Colors.black : Colors.black38, fontWeight: FontWeight.w600))),
              if (!hasFile)
                Text(loc.translate('screening_doc_not_provided'), style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic)),
              if(hasFile)
                Icon(Icons.visibility_outlined, color: Colors.black, size: 20)
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(String filePath) async {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translateWithArgs('screening_viewing_doc', {'file': filePath}))));
  }

  Widget _buildStatusSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('screening_update_status_title'), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFFDB515)),
              style: TextStyle(color: Colors.white, fontSize: 16),
              items: [
                {"value": "Approve", "label": loc.translate('verifyApp_status_approve')},
                {"value": "Reject", "label": loc.translate('verifyApp_status_reject')},
                {"value": "Pending", "label": loc.translate('verifyApp_status_pending')}
              ].map((Map<String, String> item) {
                return DropdownMenuItem<String>(
                  value: item["value"],
                  child: Text(item["label"]!),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStatus = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('screening_reason_title'), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextField(
          controller: reasonController,
          maxLines: 4,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: loc.translate('screening_reason_hint'),
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: submitStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFDB515),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          loc.translate('screening_submit_button'),
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
