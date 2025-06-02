import 'package:flutter/material.dart';
import 'package:projects/pages/HomePage.dart';
// Assuming AmountPage is a valid page to navigate to for retrying amount-based donations
import 'package:projects/pages/amount.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class FailPay extends StatefulWidget {
  const FailPay({Key? key}) : super(key: key); // Constructor can remain simple

  @override
  _FailPayState createState() => _FailPayState();
}

class _FailPayState extends State<FailPay> {
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
            context, MaterialPageRoute(builder: (context) =>  HomePage()), (route) => false);
      }
      // Handle other indices if necessary
    });
  }

  @override
  Widget build(BuildContext context) {
    String mainTitle = "Payment Failed or Cancelled";
    String detailsMessage = "Unfortunately, the payment could not be completed or was cancelled.";
    IconData displayIcon = Icons.cancel_outlined;
    Color iconColor = Colors.red;
    bool isPending = false;

    if (receivedArguments != null) {
      String toyyibPayStatus = receivedArguments!['status']?.toString() ?? ""; // From web redirect
      String mobileStatus = receivedArguments!['status_from_deeplink']?.toString() ?? ""; // From mobile deeplink

      // Check for web redirect details
      if (receivedArguments!['billcode'] != null) {
        detailsMessage = "Bill Code: ${receivedArguments!['billcode']}\nReference No: ${receivedArguments!['refno'] ?? 'N/A'}";
        if (toyyibPayStatus == '2') {
          mainTitle = "Payment Pending";
          detailsMessage += "\n\nYour payment is currently pending. Please check with ToyyibPay or your bank for the status.";
          displayIcon = Icons.hourglass_empty_rounded;
          iconColor = Colors.orange;
          isPending = true;
        } else if (toyyibPayStatus == '3') {
          mainTitle = "Payment Failed";
          detailsMessage += "\n\nThe payment attempt was unsuccessful.";
        } else if (toyyibPayStatus.isNotEmpty && toyyibPayStatus != '1') { // Other non-success web status
          mainTitle = "Payment Not Successful";
          detailsMessage += "\n\nThe payment was not successful.";
        }
      }
      // Check for mobile flow details (original donationData)
      else if (receivedArguments!['amount'] != null && receivedArguments!['name'] != null) {
        mainTitle = "Payment Failed"; // Assuming failure if it reaches here from mobile
        detailsMessage = "Failed to complete donation of RM ${receivedArguments!['amount']}.\nDonor: ${receivedArguments!['name']}";
      }
      // Fallback for minimal mobile deep link if it indicated failure
      else if (mobileStatus == 'fail') {
        mainTitle = "Payment Not Successful";
        detailsMessage = "The payment process was not completed successfully.";
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFF1C1C1C),
      appBar: AppBar(
        title: Text(mainTitle),
        backgroundColor: iconColor, // Use iconColor for AppBar too
        automaticallyImplyLeading: false,
      ),
      body: Center( // Center the content
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(displayIcon, color: iconColor, size: 120), // Slightly larger icon
              const SizedBox(height: 24),
              Text(
                mainTitle,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: iconColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                detailsMessage,
                style: const TextStyle(fontSize: 17, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const Spacer(), // Pushes buttons to the bottom if content is short
              SizedBox(height: 30),
              if (!isPending) // Don't show "Try Again" if payment is pending
                ElevatedButton(
                  onPressed: () {
                    // Attempt to pop back, assuming the previous page is the donation form.
                    // This is generally safe. If it can't pop, nothing happens.
                    // Or, navigate to a specific form page if more appropriate.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // Fallback: Go to amount page if cannot pop (e.g. direct web redirect to fail)
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AmountPage()));
                    }
                  },
                  child: const Text("Try Again", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCF40),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(280, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  HomePage()), (route) => false);
                },
                child: Text(isPending ? "Back to Home" : "Cancel", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(280, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}