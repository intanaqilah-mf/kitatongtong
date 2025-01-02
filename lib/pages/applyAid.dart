import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:file_picker/file_picker.dart';
import '../pages/PDFViewerScreen.dart';

class ApplyAid extends StatefulWidget {
  @override
  _ApplyAidState createState() => _ApplyAidState();
}

class _ApplyAidState extends State<ApplyAid> {
  int currentStep = 1; // Tracks the current step (e.g., 1/5)
  final int totalSteps = 5; // Total number of steps
  int _selectedIndex = 0; // For BottomNavBar selected index

  String? fileName1;
  String? fileName2;
  String? fileName3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
            padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (currentStep > 1) {
                          setState(() {
                            currentStep--;
                          });
                        } else {
                          Navigator.pop(context); // Exit the page if on the first step
                        }
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),

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
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: MediaQuery.of(context).size.width * 0.74 * progressValue,
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
                    Text(
                      "$currentStep/$totalSteps",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding to the entire form
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20), // Padding between progress tracker and title
            Center(
              child: Column(
                children: [
                  Text(
                    currentStep == 1
                        ? "Share your personal details"
                        : currentStep == 2
                        ? "Check your eligibility"
                        : currentStep == 3
                        ? "Upload required documents"
                        : "Upload required Documents",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDB515),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentStep == 1
                        ? "Fill in your personal details to begin your application"
                        : currentStep == 2
                        ? "Answer a few simple questions to see if you meet our eligibility criteria"
                        : currentStep == 3
                        ? "We need to verify your identity and financial status. Please upload the required documents"
                        : "We need to verify your identity and financial status. Please upload the required documents",
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
            // Display form fields based on the current step
            Expanded(
              child: ListView(
                children: currentStep == 1
                    ? buildPersonalDetailsForm()
                    : currentStep == 2
                    ? buildEligibilityForm()
                    : currentStep == 3
                    ? buildUploadDocumentsForm()
                    : buildFourthPage(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Push the content upwards from the bottom
                children: [
                  Divider(
                    color: Colors.white,
                    thickness: 1,
                  ),
                  SizedBox(height: 2), // Space between divider and button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), // Add space from the bottom
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFCF40), // Button background color
                        foregroundColor: Colors.black, // Text color
                      ),
                      onPressed: () {
                        if (currentStep < totalSteps) {
                          setState(() {
                            currentStep++;
                          });
                        }
                      },
                      child: Text(currentStep == totalSteps ? "Submit" : "Next"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex, // Pass the selected index
        onItemTapped: _onItemTapped, // Pass the tap handler
      ),
    );
  }

  // Define the forms here
  List<Widget> buildPersonalDetailsForm() {
    return [
      buildTextField("NRIC"),
      SizedBox(height: 10),
      buildTextField("Full Name"),
      SizedBox(height: 10),
      buildTextField("Email"),
      SizedBox(height: 10),
      buildMobileNumberField(),
      SizedBox(height: 10),
      buildTextField("Address Line 1"),
      SizedBox(height: 10),
      buildTextField("Address Line 2"),
      SizedBox(height: 10),
      buildTextField("City"),
      SizedBox(height: 10),
      buildTextField("Postcode"),
    ];
  }

  List<Widget> buildEligibilityForm() {
    return [
      buildTextField("Residency Status"),
      SizedBox(height: 10),
      buildTextField("Employment Status"),
      SizedBox(height: 10),
      buildTextField("Monthly Income"),
      SizedBox(height: 10),
      buildLongTextField("Justification of Application"),
    ];
  }

  List<Widget> buildUploadDocumentsForm() {
    return [
      buildFileUploadField(
        "Snapshot of NRIC/License/Passport", // Title outside the box
        "Proof of identity",                 // Label inside the box
        "Format: jpeg/jpg/pdf",
        1,
      ),
      SizedBox(height: 10),
      buildFileUploadField(
        "Proof of Address (e.g. Utility Bill)",
        "Proof of address",
        "Format: jpeg/jpg/pdf",
        2,
      ),
      SizedBox(height: 10),
      buildFileUploadField(
        "Proof of Income",
        "Proof of income",
        "Format: jpeg/jpg/pdf",
        3,
      ),
    ];
  }

  List<Widget> buildFourthPage() {
    return [
      buildFileDisplayField("Snapshot of NRIC/License/Passport", fileName1),
      SizedBox(height: 10),
      buildFileDisplayField("Proof of Address (e.g. Utility Bill)", fileName2),
      SizedBox(height: 10),
      buildFileDisplayField("Proof of Income", fileName3),
    ];
  }

  Widget buildFileDisplayField(String title, String? fileName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the box
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Title color
          ),
        ),
        SizedBox(height: 8), // Spacing between title and box

        // File display box
        GestureDetector(
          onTap: () async {
            if (fileName == null) {
              // Allow new file upload if no file exists
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['jpeg', 'jpg', 'pdf'],
              );

              if (result != null) {
                setState(() {
                  // Assign the uploaded file name based on the title
                  if (title.contains("NRIC")) fileName1 = result.files.single.name;
                  if (title.contains("Address")) fileName2 = result.files.single.name;
                  if (title.contains("Income")) fileName3 = result.files.single.name;
                });
              }
            } else {
              // If file exists, view the file (for simplicity, open a dialog)
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("View File"),
                  content: Text("File Name: $fileName"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close"),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFCF40),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/docAsnaf.png', height: 24), // Document icon
                    SizedBox(width: 10),
                    Text(
                      fileName ?? "No file uploaded", // Display file name
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Image.asset('assets/trash.png', height: 24), // Trash icon asset
                  onPressed: () {
                    setState(() {
                      // Clear the file name based on the title
                      if (title.contains("NRIC")) fileName1 = null;
                      if (title.contains("Address")) fileName2 = null;
                      if (title.contains("Income")) fileName3 = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFileUploadField(String title, String label, String subtitle, int index) {
    String? uploadedFileName; // Variable to store the file name

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, // Title outside the box
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFCF40), // Match your box design
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
              ),
              onPressed: () async {
                try {
                  // Open file picker to select a file
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpeg', 'jpg', 'pdf'], // Accepted file types
                  );

                  if (result != null) {
                    setState(() {
                      uploadedFileName = result.files.single.name; // Store the selected file name
                      if (index == 1) fileName1 = uploadedFileName;
                      if (index == 2) fileName2 = uploadedFileName;
                      if (index == 3) fileName3 = uploadedFileName;
                    });
                  }
                } catch (e) {
                  debugPrint("Error while picking file: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to pick file. Please try again.")),
                  );
                }
              },
              child: Container(
                height: 90, // Maintain the original box height
                width: double.infinity, // Match the original box width
                child: Center(
                  child: uploadedFileName == null // If no file is uploaded
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/uploadAsnaf.png',
                        height: 24, // Icon size
                      ),
                      SizedBox(height: 6), // Space between icon and label
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4), // Space between label and subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                      : Text(
                    uploadedFileName!, // Display the file name
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  Widget buildLongTextField(String label) {
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
          height: 120, // Make the container taller
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            maxLines: null, // Allows multi-line input
            expands: true, // Makes the field expand to fill the container
            textAlignVertical: TextAlignVertical.top, // Align text to the top
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

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
