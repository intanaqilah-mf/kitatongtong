import 'package:flutter/material.dart';

class ApplyAid extends StatefulWidget {
  @override
  _ApplyAidState createState() => _ApplyAidState();
}

class _ApplyAidState extends State<ApplyAid> {
  int currentStep = 1; // Tracks the current step (e.g., 1/5)
  final int totalSteps = 5; // Total number of steps

  @override
  Widget build(BuildContext context) {
    double progressValue = currentStep / totalSteps; // Calculate progress percentage

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF303030), // Dark background for app bar
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back Arrow
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                // Progress Bar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      children: [
                        // Progress Bar Background
                        Container(
                          height: 15, // Increased height for visibility
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Progress Bar (Animated)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: MediaQuery.of(context).size.width * 0.74 * (currentStep / totalSteps),
                          height: 15, // Same height as background
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Progress Text
                Text(
                  "$currentStep/$totalSteps",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Share your personal details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Fill in your personal details to begin your application",
              style: TextStyle(
                fontSize: 14,
                color: Colors.yellow[200],
              ),
            ),
            SizedBox(height: 16),
            // NRIC Field
            buildTextField("NRIC"),
            SizedBox(height: 16),
            // Full Name Field
            buildTextField("Full Name"),
            SizedBox(height: 16),
            // Email Field
            buildTextField("Email"),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow, // Background color (was primary)
                foregroundColor: Colors.black, // Text color (was onPrimary)
              ),
              onPressed: () {
                if (currentStep < totalSteps) {
                  setState(() {
                    currentStep++;
                  });
                }
              },
              child: Text("Next"),
            ),

          ],
        ),
      ),
    );
  }

  // Helper method to create text fields
  Widget buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF1D789),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}
