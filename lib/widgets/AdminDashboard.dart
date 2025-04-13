import 'package:flutter/material.dart';
import 'package:projects/pages/verifyApplications.dart';
import 'package:projects/pages/issueReward.dart';
import 'package:projects/pages/manageStaffs.dart';

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
                        MaterialPageRoute(builder: (context) => VerifyApplicationsScreen()),
                      );
                    }
                    else if (i ==2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IssueReward()),
                      );
                    }
                    else if (i ==4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManageStaffsScreen()),
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
                width: 85, // Limit the width of the text
                child: Text(
                  getTextForIndex(i),
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

String getTextForIndex(int index) {
  switch (index) {
    case 1:
      return "Verify Applications";
    case 2:
      return "Issue Reward";
    case 3:
      return "View Reports";
    case 4:
      return "Manage User";
    default:
      return "";
  }
}