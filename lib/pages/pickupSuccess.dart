import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class pickupSuccess extends StatefulWidget {
  final String name;
  final String phone;
  final String reward;
  final String pickupCode;

  const pickupSuccess({
    Key? key,
    required this.name,
    required this.phone,
    required this.reward,
    required this.pickupCode,
  }) : super(key: key);

  @override
  _pickupSuccessState createState() => _pickupSuccessState();
}

class _pickupSuccessState extends State<pickupSuccess> {
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
                        'assets/check.png',
                        height: 100,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Pick-Up is Successful",
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCF40),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Here is the pick-up detail.",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Participant's Name: ${widget.name}",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        "Participant's Number: ${widget.phone}",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      Text(
                        "Reward Redeemed: ${widget.reward}",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      SizedBox(height: 20),
                      if (items.isNotEmpty) ...[
                        Text(
                          "Item Redeemed:",
                          style: TextStyle(
                            color: Color(0xFFFFCF40),
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
                backgroundColor: Color(0xFFFFCF40),
                foregroundColor: Colors.black,
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
