import 'package:flutter/material.dart';
import 'package:projects/pages/verifyApplications.dart';
import 'package:projects/pages/issueReward.dart';
import 'package:projects/pages/manageStaffs.dart';
import 'package:projects/pages/viewReports.dart';
import 'package:projects/localization/app_localizations.dart';

class AdminDashboard extends StatelessWidget {
  Widget build(BuildContext context) {
    return GridView.count(
      childAspectRatio: 0.7,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      shrinkWrap: true,
      children: [
        for (int i = 1; i < 5; i++)
          Column(
            children: [
              Container(
                height: 85,
                width: 85,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFF1D789),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: InkWell(
                  onTap: () {
                    if (i == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VerifyApplicationsScreen()),
                      );
                    } else if (i == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IssueReward()),
                      );
                    } else if (i == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewReportsScreen()),
                      );
                    } else if (i == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ManageStaffsScreen()),
                      );
                    }
                  },
                  child: Image.asset(
                    "assets/iconAdmin$i.png",
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: 85,
                child: Text(
                  getTextForIndex(context, i), // Pass context here
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// Updated function to accept context and use AppLocalizations
String getTextForIndex(BuildContext context, int index) {
  final localizations = AppLocalizations.of(context);
  switch (index) {
    case 1:
      return localizations.translate('dashboard_verify_applications');
    case 2:
      return localizations.translate('dashboard_issue_reward');
    case 3:
      return localizations.translate('dashboard_view_reports');
    case 4:
      return localizations.translate('dashboard_manage_user');
    default:
      return "";
  }
}