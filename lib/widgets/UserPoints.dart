import 'package:flutter/material.dart';

class UserPoints extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column( // Wrap everything in a Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //SizedBox(height: 20), // Add this to create the gap
        GridView.count(
          childAspectRatio: 1.5, // Adjust aspect ratio for better alignment
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2, // Two columns for two boxes
          shrinkWrap: true,
          children: [
            // 1st Box - Points
            Column(
              children: [
                Container(
                  height: 76,
                  width: 180,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFDB515),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Stack(
                    children: [
                      // Points Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Points",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "159",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Smiley Icon (Overlay on the right)
                      Positioned(
                        top: 14, // Adjust this to position it relative to the top
                        right: 0, // Align it to the right
                        child: Image.asset(
                          "assets/Smiley.png",
                          height: 40, // Adjust the size here
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 2nd Box - Check-In Event
            Column(
              children: [
                Container(
                  height: 76, // Increased height for better alignment
                  width: 180,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFDB515),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Stack(
                    children: [
                      // Check-In Event Text
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Check-In Event",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Earn points by confirming\nyour attendance",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Calendar Icon (Stacked)
                      Positioned(
                        bottom: 0, // Positioned at the bottom of the container
                        right: 0, // Aligned to the right
                        child: Image.asset(
                          "assets/calendar.png", // Replace with your asset
                          height: 50, // Adjust the size here
                          width: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

