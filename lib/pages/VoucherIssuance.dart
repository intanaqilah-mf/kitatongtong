import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/reviewIssueReward.dart';
import 'package:intl/intl.dart';

class VoucherIssuance extends StatefulWidget {
  final String documentId;

  VoucherIssuance({required this.documentId});

  @override
  _VoucherIssuanceState createState() => _VoucherIssuanceState();
}

class _VoucherIssuanceState extends State<VoucherIssuance> {
  int _selectedIndex = 0;
  String selectedRewardAmount = "RM50";
  bool isRecurring = false;
  String selectedRecurrence = "2 Weeks";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      DocumentSnapshot appSnapshot = await fetchApplicationData();
      if (appSnapshot.exists) {
        var appData = appSnapshot.data() as Map<String, dynamic>;
        setState(() {
          selectedRewardAmount = appData['reward'] ?? "RM50";
          isRecurring = appData['isRecurring'] ?? false;
          selectedRecurrence = appData['recurrencePeriod'] ?? "2 Weeks";
        });
      }
    } catch (e) {
      print("Error loading initial data: $e");
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<DocumentSnapshot> fetchApplicationData() {
    return FirebaseFirestore.instance.collection('applications').doc(widget.documentId).get();
  }

  Future<DocumentSnapshot?> fetchUserData(String? userId) {
    if (userId == null || userId.isEmpty) {
      return Future.value(null);
    }
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  void submitRewardDetails() async {
    try {
      DateTime? nextEligibleDate;
      if (isRecurring) {
        final now = DateTime.now();
        switch (selectedRecurrence) {
          case "2 Weeks": nextEligibleDate = now.add(Duration(days: 14)); break;
          case "1 Month": nextEligibleDate = now.add(Duration(days: 30)); break;
          case "3 Months": nextEligibleDate = now.add(Duration(days: 90)); break;
          case "6 Months": nextEligibleDate = now.add(Duration(days: 180)); break;
          case "9 Months": nextEligibleDate = now.add(Duration(days: 270)); break;
          case "1 Year": nextEligibleDate = now.add(Duration(days: 365)); break;
        }
      }

      DocumentSnapshot appSnapshot = await fetchApplicationData();
      if (!appSnapshot.exists) {
        throw Exception("Application not found");
      }
      var appData = appSnapshot.data() as Map<String, dynamic>;
      String? userId = appData['userId'];

      await FirebaseFirestore.instance.collection('applications').doc(widget.documentId).update({
        'rewardType': 'Voucher Package Kasih',
        'eligibilityDetails': 'Asnaf Application',
        'reward': selectedRewardAmount,
        'statusReward': 'Issued',
        'isRecurring': isRecurring,
        'recurrencePeriod': isRecurring ? selectedRecurrence : null,
        'nextEligibleDate': isRecurring ? Timestamp.fromDate(nextEligibleDate!) : null,
        'lastRedeemed': null,
      });

      if (userId != null && userId.isNotEmpty) {
        final String adminVoucherId = "admin_${DateTime.now().millisecondsSinceEpoch}";
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'voucherReceived': FieldValue.arrayUnion([{
            'voucherGranted': selectedRewardAmount,
            'eligibility': 'Asnaf Application',
            'rewardType': 'Voucher Package Kasih',
            'voucherId': adminVoucherId,
            'redeemedAt': Timestamp.now()
          }])
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reward details updated successfully!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ReviewIssueReward()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update reward details: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      appBar: AppBar(
        title: Text("Voucher Issuance", style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF303030),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFDB515)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: fetchApplicationData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Application not found', style: TextStyle(color: Colors.white)));
          }

          var appData = snapshot.data!.data() as Map<String, dynamic>;
          String? userId = appData['userId'];

          return FutureBuilder<DocumentSnapshot?>(
            future: fetchUserData(userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB515))));
              }

              Map<String, dynamic>? userData = userSnapshot.data?.data() as Map<String, dynamic>?;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApplicantInfoCard(appData, userData),
                    SizedBox(height: 24),
                    _buildRewardSection(),
                    SizedBox(height: 24),
                    _buildRecurringSection(),
                    SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
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

  Widget _buildApplicantInfoCard(Map<String, dynamic> appData, Map<String, dynamic>? userData) {
    String address = [
      appData['addressLine1'],
      appData['addressLine2'],
      appData['postcode'],
      appData['city'],
      appData['state']
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    String submittedByText;
    if (appData['submittedBy'] is Map) {
      submittedByText = "Submitted by Staff: ${appData['submittedBy']['name'] ?? 'N/A'}";
    } else {
      submittedByText = "Submitted by: ${appData['fullname']}";
    }
    String? photoUrl = userData?['photoUrl'];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9F295), Color(0xFFB88A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black26,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person, size: 30, color: Colors.white70) : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appData['fullname'] ?? 'N/A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    SizedBox(height: 4),
                    Text(appData['applicationCode'] ?? 'No Code', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.black38, height: 24),
          _buildInfoRow(Icons.badge_outlined, "NRIC", appData['nric'] ?? 'N/A'),
          _buildInfoRow(Icons.phone_outlined, "Mobile", "60${appData['mobileNumber'] ?? 'N/A'}"),
          _buildInfoRow(Icons.work_outline, "Employment", appData['employmentStatus'] ?? 'N/A'),
          if (appData['employmentStatus'] == 'Employed')
            _buildInfoRow(Icons.attach_money_outlined, "Income", "RM ${appData['monthlyIncome'] ?? 'N/A'}"),
          _buildInfoRow(Icons.home_outlined, "Address", address),
          _buildInfoRow(Icons.lightbulb_outline, "Justification", appData['justificationApplication'] ?? 'N/A'),
          SizedBox(height: 8),
          Text(submittedByText, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
        ],
      ),
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
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  TextSpan(text: value, style: TextStyle(color: Colors.black87)),
                ],
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Reward Amount", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRewardAmount,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFFDB515)),
              style: TextStyle(color: Colors.white, fontSize: 16),
              items: ["RM50", "RM100", "RM150", "RM200", "RM250"].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => selectedRewardAmount = newValue!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Aid Recurrence", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SwitchListTile(
          title: Text("Issue Recurring Aid", style: TextStyle(color: Colors.white)),
          value: isRecurring,
          onChanged: (bool value) => setState(() => isRecurring = value),
          activeColor: Color(0xFFFDB515),
          inactiveTrackColor: Colors.grey[600],
          tileColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        if (isRecurring) ...[
          SizedBox(height: 16),
          Text("Recurrence Period", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRecurrence,
                isExpanded: true,
                dropdownColor: Colors.grey[800],
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFFFDB515)),
                style: TextStyle(color: Colors.white, fontSize: 16),
                items: ["2 Weeks", "1 Month", "3 Months", "6 Months", "9 Months", "1 Year"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => selectedRecurrence = newValue!),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: submitRewardDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFDB515),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "Issue Reward",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
