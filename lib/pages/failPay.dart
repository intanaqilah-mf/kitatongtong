import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class FailPay extends StatefulWidget {
  @override
  _FailPayState createState() => _FailPayState();
}

class _FailPayState extends State<FailPay> {
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
      appBar: AppBar(title: const Text('Payment Failed')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/check.png', height: 100), // Consider a different image for failure
            const SizedBox(height: 20),
            const Text(
              "Donation Payment Failed",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
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
              ],
            )
                : const Text("No donation details available.", style: TextStyle(color: Colors.white)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Try Again: pop back to reinitiate payment
                Navigator.pop(context);
              },
              child: const Text("Try Again", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                minimumSize: const Size(300, 45),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
              },
              child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(300, 45),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
