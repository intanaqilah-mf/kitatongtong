import 'package:flutter/material.dart';

class ItemsWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return GridView.count(
      //childAspectRatio: 0.72,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      shrinkWrap: true,
      children: [
        for(int i = 1; i<5; i++)
          Container(
            //15:46
            height: 100,
            width: 100,
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
                    width: 55,
                    height: 55,
                    child: Image.asset(
                      alignment: Alignment.center,
                      //width: 100,
                     //height: 100,
                      "assets/iconhome$i.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],),
          ),
      ],
    );
  }
}
