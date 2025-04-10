import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class SuccessPay extends StatefulWidget {
  @override
  _SuccessPayState createState() => _SuccessPayState();
}

class _SuccessPayState extends State<SuccessPay> {
  int _selectedIndex = 0;
  Map<String, dynamic>? donationData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    donationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Successful')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/check.png', height: 100),
            const SizedBox(height: 20),
            const Text(
              "Donation Payment is Successful",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFCF40)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            donationData != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Amount (RM): ${donationData!['amount']}", style: const TextStyle(fontSize: 20, color: Colors.white)),
                Text("Donor Name: ${donationData!['name']}", style: const TextStyle(fontSize: 20, color: Colors.white)),
                Text("Email: ${donationData!['email']}", style: const TextStyle(fontSize: 20, color: Colors.white)),
                Text("Contact: ${donationData!['contact']}", style: const TextStyle(fontSize: 20, color: Colors.white)),
                // Show more info as needed
              ],
            )
                : const Text("No donation details available.", style: TextStyle(color: Colors.white)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
              },
              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                minimumSize: const Size(300, 45),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}
