import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PickupFail extends StatefulWidget {
  final String name;
  final String phone;
  final String reward;
  final String pickupCode;
  final String pickedUpAt;


  const PickupFail({
    Key? key,
    required this.name,
    required this.phone,
    required this.reward,
    required this.pickupCode,
    required this.pickedUpAt,

  }) : super(key: key);

  @override
  _PickupFailState createState() => _PickupFailState();
}

class _PickupFailState extends State<PickupFail> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    fetchItemRedeemed();
  }

  void fetchItemRedeemed() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('redeemedKasih')
        .where('pickupCode', isEqualTo: widget.pickupCode)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final List<dynamic> itemList = data['itemRedeemed'] ?? [];

      setState(() {
        items = itemList.cast<Map<String, dynamic>>();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/fail.png',
                        height: 100,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Invalid Pick-Up Attempt",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14),
                      Text(
                        "This package was already picked up on ${widget.pickedUpAt}.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Participant's Name: ${widget.name}",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "Participant's Number: ${widget.phone}",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "Reward Redeemed: ${widget.reward}",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      if (items.isNotEmpty) ...[
                        Text(
                          "Item(s) Picked Up:",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        for (int i = 0; i < items.length; i++)
                          Text(
                            "${i + 1}. ${items[i]['name']} - ${items[i]['number']} ${items[i]['unit']}",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(300, 45),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                );
              },
              child: Text(
                "OK",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
