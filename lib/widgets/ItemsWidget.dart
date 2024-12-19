import 'package:flutter/material.dart';

class ItemsWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return GridView.count(
      childAspectRatio: 0.7, // Keep the boxes square
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      shrinkWrap: true,
      children: [
        for (int i = 1; i < 5; i++)
          Column(
            children: [
              Container(
                height: 85, // Fixed height
                width: 85,  // Fixed width
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFF1D789),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: InkWell(
                  onTap: () {
                    //Navigator.pushNamed(context, itemPage);
                  },
                  child: Image.asset(
                    "assets/iconhome$i.png",
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                getTextForIndex(i),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
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
      return "Home";
    case 2:
      return "Documents";
    case 3:
      return "Messages";
    case 4:
      return "Gifts";
    default:
      return "";
  }
}
