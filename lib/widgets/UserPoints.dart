import 'package:flutter/material.dart';

class UserPoints extends StatelessWidget {
  Widget build(BuildContext context) {
    return GridView.count(
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
              width: 160,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFFDB515),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  // Points Title
                  Text(
                    "Points",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5), // Space between title and value
                  // Row with Points Value and Smiley Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "159",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 5),
                      Image.asset(
                        "assets/Smiley.png",
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ],
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
              height: 76,
              width: 160,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFFDB515),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                children: [
                  // Check-In Event Title
                  Text(
                    "Check-In Event",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4), // Space between title and description
                  // Row with Description and Calendar Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "Earn points by confirming your attendance",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 5), // Space between text and icon
                      Image.asset(
                        "assets/calendar.png", // Replace with your asset
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
