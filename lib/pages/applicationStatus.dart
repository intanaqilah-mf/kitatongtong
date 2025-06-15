import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/pages/redeem_voucher_items_page.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import '../pages/HomePage.dart';
import 'package:intl/intl.dart';
import 'package:projects/localization/app_localizations.dart';

class ApplicationStatusPage extends StatefulWidget {
  final String documentId;
  const ApplicationStatusPage({Key? key, required this.documentId})
      : super(key: key);

  @override
  _ApplicationStatusPageState createState() => _ApplicationStatusPageState();
}

class _ApplicationStatusPageState extends State<ApplicationStatusPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }
  String _formatDate(String? dateString) {
    if (dateString == null) return AppLocalizations.of(context).translate('status_unknown_date');
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat.yMMMMd().add_jm().format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(
              child: Text(
                localizations.translate('status_no_app_found'),
                style: TextStyle(color: Colors.red),
              ),
            );

          final data = snapshot.data!.data()! as Map<String, dynamic>;
          final fullName = data['fullname'] ?? localizations.translate('status_unknown_name');
          final asnafUserId = data['userId'] as String?;
          final appCode = data['applicationCode'] ?? localizations.translate('status_unknown_code');
          final statusApplication = data['statusApplication'] ?? localizations.translate('applications_status_pending');
          final statusReward = data['statusReward'] as String?;
          final date = data['date'] as String?;
          final reasonStatus = data['reasonStatus'] ?? localizations.translate('status_no_reason');
          final reward = data['reward'] as String? ?? localizations.translate('status_default_reward');

          String completedSubtitle;
          if (statusApplication == "Approve") {
            completedSubtitle = localizations.translateWithArgs('status_accepted_subtitle', {'reason': reasonStatus});
          } else if (statusApplication == "Reject") {
            completedSubtitle = localizations.translateWithArgs('status_rejected_subtitle', {'reason': reasonStatus});
          } else {
            completedSubtitle = localizations.translate('status_reviewing_subtitle');
          }

          String rewardSubtitle = statusReward == "Issued"
              ? localizations.translateWithArgs('status_reward_issued_subtitle', {'reward': reward})
              : localizations.translate('status_reward_pending_subtitle');

          final color1 = _getStatusColor(stage: 1, statusApp: statusApplication, statusReward: statusReward);
          final color2 = _getStatusColor(stage: 2, statusApp: statusApplication, statusReward: statusReward);
          final color3 = _getStatusColor(stage: 3, statusApp: statusApplication, statusReward: statusReward);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 25, horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Text(
                      localizations.translate('status_page_title'),
                      style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                localizations.translate('status_label_app_code'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "$appCode",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                localizations.translate('status_label_full_name'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                fullName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Color(0xFF303030),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),

              statusTile(
                title: localizations.translate('status_title_submitted'),
                subtitle: localizations.translateWithArgs('status_subtitle_submitted', {'date': _formatDate(date)}),
                iconPath: "assets/applicationStatus1.png",
                circleColor: color1,
                showLine: true,
                lineColor: color1,
              ),

              statusTile(
                title: localizations.translate('status_title_reviewed'),
                subtitle: completedSubtitle,
                iconPath: "assets/applicationStatus3.png",
                circleColor: color2,
                showLine: true,
                lineColor: color3,
              ),

              statusTile(
                title: localizations.translate('status_title_rewards_issued'),
                subtitle: rewardSubtitle,
                iconPath: "assets/reward.png",
                circleColor: color3,
                showLine: false,
              ),

              Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => HomePage()),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations.translate('ok'),
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    if (statusReward == 'Issued') ...[
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final rewardValueString = reward.replaceAll(RegExp(r'[^0-9.]'), '');
                            final double rewardValue = double.tryParse(rewardValueString) ?? 0.0;

                            if (rewardValue > 0 && asnafUserId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RedeemVoucherWithItemsPage(
                                  voucherValue: rewardValue,
                                  voucherReceived: {
                                    'docId': widget.documentId,
                                  },
                                )),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Shop for Asnaf", // Consider adding to localization
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Color _getStatusColor({
    required int stage,
    required String statusApp,
    required String? statusReward,
  }) {
    if (stage == 1) {
      return Colors.green;
    }
    if (stage == 2) {
      if (statusApp == "Reject") return Colors.red;
      if (statusApp == "Approve") return Colors.green;
      return Colors.grey;
    }
    if (stage == 3) {
      if (statusApp == "Reject") {
        return Colors.red;
      }
      if (statusReward == "Issued" || statusReward == "Redeemed") {
        return Colors.green;
      }
      if(statusApp == "Approve"){
        return Colors.grey;
      }
      return Colors.grey;
    }
    return Colors.grey;
  }

  Widget statusTile({
    required String title,
    required String subtitle,
    required String iconPath,
    required Color circleColor,
    required bool showLine,
    Color? lineColor,
  }) {
    final connectorColor = lineColor ?? circleColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 65,
                height: 30,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (showLine)
                Container(
                  width: 5,
                  height: 90,
                  color: connectorColor,
                ),
            ],
          ),
          SizedBox(width: 15),
          Image.asset(iconPath, width: 45, height: 45),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
