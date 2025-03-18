import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class Rewards extends StatefulWidget {
  @override
  _RewardsState createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  bool isRewards = false;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 70, left: 16, right: 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFFDB515),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isRewards = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isRewards ? Colors.white : Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Redeem Rewards",
                          style: TextStyle(
                            color: isRewards ? Color(0xFFFDB515) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isRewards = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isRewards ? Colors.white : Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Rewards",
                          style: TextStyle(
                            color: !isRewards ? Color(0xFFFDB515) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isRewards
                ? Center(child: Text("Create Event Form Here"))  // Placeholder for the form
                : Center(child: Text("List of Events Here")),   // Placeholder for the event list
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex, // Pass the selected index
        onItemTapped: _onItemTapped, // Pass the tap handler
      ),
    );
  }
}
