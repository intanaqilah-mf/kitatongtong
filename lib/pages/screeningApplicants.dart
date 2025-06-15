import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
        SnackBar(content: Text("Application status updated successfully!")),
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
          "Screening Applicant",
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
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data found for this applicant.', style: TextStyle(color: Colors.white)));
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
          _buildInfoRow(Icons.badge_outlined, "NRIC", appData['nric'] ?? 'N/A'),
          _buildInfoRow(Icons.phone_outlined, "Mobile", "60${appData['mobileNumber'] ?? 'N/A'}"),
          _buildInfoRow(Icons.email_outlined, "Email", appData['email'] ?? 'N/A'),
          _buildInfoRow(Icons.home_outlined, "Address", address),
          _buildInfoRow(Icons.flag_outlined, "Residency", appData['residencyStatus'] ?? 'N/A'),
          _buildInfoRow(Icons.work_outline, "Employment", appData['employmentStatus'] ?? 'N/A'),
          if (appData['employmentStatus'] == 'Employed') ...[
            _buildInfoRow(Icons.business_center_outlined, "Occupation", appData['occupation'] ?? 'N/A'),
            _buildInfoRow(Icons.attach_money_outlined, "Income", "RM ${appData['monthlyIncome'] ?? 'N/A'}"),
          ],
          if (appData['employmentStatus'] == 'Unemployed' && appData['isAsnaf'] == 'Yes')
            _buildInfoRow(Icons.groups_outlined, "Asnaf In", appData['asnafIn'] ?? 'N/A'),
          _buildInfoRow(Icons.lightbulb_outline, "Justification", appData['justificationApplication'] ?? 'N/A'),
          Divider(color: Colors.black54, thickness: 1, height: 24),
          _buildDocumentSection(appData),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> appData, dynamic userId, bool isStaffSubmission) {
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
                appData['applicationCode'] ?? 'No Code',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (isStaffSubmission)
                Text(
                  "Submitted by: ${appData['submittedBy']['name'] ?? 'Staff'}",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Uploaded Documents", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
        SizedBox(height: 8),
        _buildDocumentLink("Proof of Address", appData['proofOfAddress']),
        if (appData['employmentStatus'] == 'Employed')
          _buildDocumentLink("Proof of Income", appData['proofOfIncome']),
      ],
    );
  }

  Widget _buildDocumentLink(String label, String? filePath) {
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
                Text("Not Provided", style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic)),
              if(hasFile)
                Icon(Icons.visibility_outlined, color: Colors.black, size: 20)
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(String filePath) async {
    // This is a simplified version. For a real app, you'd handle file storage and retrieval
    // (e.g., from Firebase Storage) and use a proper viewer. This example assumes a local path.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Viewing: $filePath")));
    // In a real app, you would use a package like `open_file` or a custom viewer screen.
    // For example:
    // await OpenFile.open(filePath);
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Update Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              items: ["Approve", "Reject", "Pending"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Reason / Remarks", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            hintText: "Enter reason for status update (optional)...",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
          "Submit Status",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
