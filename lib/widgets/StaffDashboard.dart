import 'package:flutter/material.dart';
import 'package:projects/pages/applyAid.dart';
import 'package:projects/pages/event.dart';
import 'package:projects/pages/trackApplication.dart';
import 'package:projects/pages/trackRewards.dart';
import 'package:projects/localization/app_localizations.dart';

class StaffDashboard extends StatelessWidget {
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
                        MaterialPageRoute(builder: (context) => ApplyAid()),
                      );
                    } else if (i == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TrackRewardsScreen()),
                      );
                    } else if (i == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrackApplicationsScreen()),
                      );
                    } else if (i == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventPage()),
                      );
                    }
                  },
                  child: Image.asset(
                    "assets/iconStaff$i.png",
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
      return localizations.translate('dashboard_submit_application');
    case 2:
      return localizations.translate('dashboard_asnaf_vouchers');
    case 3:
      return localizations.translate('dashboard_monitor_applications');
    case 4:
      return localizations.translate('dashboard_manage_events');
    default:
      return "";
  }
}