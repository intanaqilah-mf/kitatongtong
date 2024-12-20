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
                        Container(
                          height: 23,
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
                          height: 23, // Same height as background
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered Title and Subtitle
          Center(
            child: Column(
              children: [
                Text(
                  "Share your personal details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDB515),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Fill in your personal details to begin your application",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.yellow[200],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // NRIC Field
          buildTextField("NRIC"),
          SizedBox(height: 10),
          // Full Name Field
          buildTextField("Full Name"),
          SizedBox(height: 10),
          // Email Field
          buildTextField("Email"),
          SizedBox(height: 10),
          // Mobile Number Field
          buildMobileNumberField(),
          SizedBox(height: 10),
          buildTextField("Address Line 1"),
          SizedBox(height: 10),
          buildTextField("Address Line 2"),
          SizedBox(height: 10),
          buildTextField("City"),
          SizedBox(height: 10),
          buildTextField("Postcode"),
          SizedBox(height: 10),
          Spacer(), // Push the button to the bottom
          Divider(color: Colors.white, thickness: 1), // White horizontal line
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFCF40), // Background color (was primary)
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
          ),
        ],
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
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to create the mobile number field
  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "+60",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              VerticalDivider(color: Colors.black, thickness: 1),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
