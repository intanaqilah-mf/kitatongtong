import 'package:flutter/material.dart';

class ItemsWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return GridView.count(
      childAspectRatio: 1.0,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      shrinkWrap: true,
      children: [
        for(int i = 1; i<5; i++)
          Container(
            height: 200,
            width: 55,
            padding: EdgeInsets.only(left: 15, right: 10, top: 10),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Color(0xFFF1D789),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              InkWell(
                onTap: () {
                  //Navigator.pushNamed(context, itemPage);
                },
                child: Container(
                  margin: EdgeInsets.all(5),
                  child: SizedBox(
                    child: Image.asset(
                      alignment: Alignment.center,
                      "assets/iconhome$i.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
                Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Text(
                    getTextForIndex(i),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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