import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';

void main () {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF303030),
      ),
      routes: {
        "/" : (context) => HomePage(),
      },
    );
  }
}