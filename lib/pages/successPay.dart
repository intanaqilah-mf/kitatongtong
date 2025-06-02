import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class SuccessPay extends StatefulWidget {
  const SuccessPay({Key? key}) : super(key: key); // Constructor can remain simple

  @override
  _SuccessPayState createState() => _SuccessPayState();
}

class _SuccessPayState extends State<SuccessPay> {
  int _selectedIndex = 0;
  Map<String, dynamic>? receivedArguments; // Use a generic name for clarity

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch arguments once
    if (receivedArguments == null) {
      receivedArguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Your existing navigation logic for bottom nav bar
      if (index == 0) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => HomePage()), (route) => false);
      }
      // Handle other indices if necessary
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = "Donation Payment is Successful!";
    List<Widget> detailWidgets = [];

    if (receivedArguments != null) {
      // Check if it's from the web redirect (will have 'billcode')
      if (receivedArguments!['billcode'] != null) {
        detailWidgets.add(Text("Source: Web Transaction", style: const TextStyle(fontSize: 14, color: Colors.grey)));
        detailWidgets.add(SizedBox(height: 8));
        detailWidgets.add(Text("Bill Code: ${receivedArguments!['billcode']}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        detailWidgets.add(Text("Reference No: ${receivedArguments!['refno'] ?? 'N/A'}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        // Note: Original amount/donor details are not directly in web redirect arguments
        // unless explicitly added or fetched separately.
        detailWidgets.add(const SizedBox(height: 10));
        detailWidgets.add(const Text("Payment confirmed via online gateway.", style: TextStyle(fontSize: 16, color: Colors.white70)));

      }
      // Check if it's from the mobile flow (will have original donationData keys like 'amount', 'name')
      else if (receivedArguments!['amount'] != null && receivedArguments!['name'] != null) {
        detailWidgets.add(Text("Source: Mobile Transaction", style: const TextStyle(fontSize: 14, color: Colors.grey)));
        detailWidgets.add(SizedBox(height: 8));
        detailWidgets.add(Text("Amount (RM): ${receivedArguments!['amount']}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        detailWidgets.add(Text("Donor Name: ${receivedArguments!['name']}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        if (receivedArguments!['email'] != null) {
          detailWidgets.add(Text("Email: ${receivedArguments!['email']}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        }
        if (receivedArguments!['contact'] != null) {
          detailWidgets.add(Text("Contact: ${receivedArguments!['contact']}", style: const TextStyle(fontSize: 18, color: Colors.white)));
        }
      }
      // Fallback for other argument structures, e.g., minimal mobile deep link
      else if (receivedArguments!['status_from_deeplink'] == 'success' || receivedArguments!['status'] == '1') {
        detailWidgets.add(const Text("Payment confirmation received.", style: TextStyle(fontSize: 18, color: Colors.white)));
      }
      else {
        detailWidgets.add(const Text("Payment details processed.", style: TextStyle(fontSize: 18, color: Colors.white)));
      }
    } else {
      detailWidgets.add(const Text("No payment details available.", style: TextStyle(color: Colors.white, fontSize: 16)));
    }

    return Scaffold(
      backgroundColor: Color(0xFF1C1C1C), // Ensuring background color consistency
      appBar: AppBar(
        title: const Text('Payment Successful'),
        backgroundColor: Colors.green, // Keeping consistent app bar color
        automaticallyImplyLeading: false,
      ),
      body: Center( // Center the content vertically and horizontally
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/check.png', height: 120), // Slightly larger image
              const SizedBox(height: 24),
              Text(
                displayTitle,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFFCF40)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...detailWidgets, // Spread the list of detail widgets
              const Spacer(), // Pushes button to the bottom if content is short, or use SizedBox
              SizedBox(height: 30), // Ensure some space before button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  HomePage()), (route) => false);
                },
                child: const Text("OK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCF40),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(280, 50), // Adjusted size
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}