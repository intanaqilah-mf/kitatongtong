import 'package:flutter/material.dart';
import '../widgets/HomeAppBar.dart';
import '../widgets/AsnafDashboard.dart';
import '../widgets/UserPoints.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          //HomeAppBar(),
          Container(
            padding: EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 5),
                        height: 50,
                        width: 300,
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search here...",
                          ),
                        ),
                      ),
                      Spacer(),
                      ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [0.16, 0.38, 0.58, 0.88],
                              colors: [
                                Color(0xFFF9F295), // Light Yellow
                                Color(0xFFE0AA3E), // Gold
                                Color(0xFFF9F295), // Light Yellow
                                Color(0xFFB88A44), // Brownish Gold
                              ],
                            ).createShader(bounds);
                          },
                        child: Icon(
                          Icons.search_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                AsnafDashboard(),
                UserPoints(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}