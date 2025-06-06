import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:file_picker/file_picker.dart';
import '../pages/PDFViewerScreen.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/applicationReviewScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:projects/pages/ekyc_screen.dart';

class ApplyAid extends StatefulWidget {
  @override
  _ApplyAidState createState() => _ApplyAidState();
}

class _ApplyAidState extends State<ApplyAid> {
  // Added state variable to store user role
  String? userRole;
  bool _isEkycComplete = false;

  void initState() {
    super.initState();
    _fetchUserData();
  }
  int currentStep = 1; // Tracks the current step (e.g., 1/5)
  final int totalSteps = 5; // Total number of steps
  int _selectedIndex = 0;
  TextEditingController nricController = TextEditingController();
  TextEditingController fullnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController add1Controller = TextEditingController();
  TextEditingController add2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postcodeController = TextEditingController();
  TextEditingController residencyController = TextEditingController();
  TextEditingController employmentController = TextEditingController();
  TextEditingController incomeController = TextEditingController();
  TextEditingController justificationController = TextEditingController();

  final Map<String, dynamic> formData = {};

  String generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return "#" + String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  String? fileName1;
  String? fileName2;
  String? fileName3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void uploadToFirebase(Map<String, dynamic> data) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final DateTime now = DateTime.now(); // Get current date & time

      String applicationCode = generateUniqueCode();
      data['date'] = now.toIso8601String(); // Store date as ISO8601 string
      data['userId'] = userId; // Store user ID for reference
      data['applicationCode'] = applicationCode; // Store the unique application code
      data['statusApplication'] = "Pending"; // Set status to Pending

      // Add the new submittedBy field based on user role
      if (userRole != null && userRole!.toLowerCase() == 'asnaf') {
        data['submittedBy'] = 'system';
      } else if (userRole != null && userRole!.toLowerCase() == 'staff') {
        // For staff, fetch the name from the users collection; fullnameController is populated in _fetchUserData
        data['submittedBy'] = fullnameController.text;
      } else {
        data['submittedBy'] = ''; // Default value if role is not defined
      }

      await FirebaseFirestore.instance.collection("applications").add(data);
      await FirebaseFirestore.instance.collection("notifications").add({
        'recipientRole':    'Admin',
        'applicantId':      userId,
        'applicantName':    fullnameController.text,
        'applicationCode':  applicationCode,
        'createdAt':        now,
      });
      print("🔔 Notification sent for $applicationCode to Admin at $now");


      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ApplicationReviewScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Application submitted successfully!")),
      );

      // Reset form after submission
      setState(() {
        formData.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit application. Please try again.")),
      );
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Fetch the role from the users collection and assign it to userRole
        userRole = userData['role'] ?? '';

        // Split address into two lines
        final fullAddress = userData['address'] ?? '';
        final addressParts = fullAddress.split(',');

        // Populate the controllers
        setState(() {
          nricController.text = userData['nric'] ?? '';
          fullnameController.text = userData['name'] ?? '';
          emailController.text = FirebaseAuth.instance.currentUser!.email ?? '';
          mobileNumberController.text = userData['phone'] ?? '';
          add1Controller.text = addressParts.length > 0 ? addressParts[0].trim() : '';
          add2Controller.text = addressParts.length > 1 ? addressParts[1].trim() : '';
          cityController.text = userData['city'] ?? '';
          postcodeController.text = userData['postcode'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch user details. Please try again.")),
      );
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        // Add horizontal padding to the entire form
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
                        : currentStep == 4
                        ? "Upload required Documents"
                        : "Kita Tongtong Agreement",
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
                        : currentStep == 4
                        ? "We need to verify your identity and financial status. Please upload the required documents"
                        : "By submitting your application for financial aid through the Kita Tongtong platform, you acknowledge and agree to the following Terms and Conditions. Please read these terms carefully before proceeding.",
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
                    : currentStep == 4
                    ? buildFourthPage()
                    : buildAgreementPage(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                // Push the content upwards from the bottom
                children: [
                  Divider(
                    color: Colors.white,
                    thickness: 1,
                  ),
                  SizedBox(height: 2), // Space between divider and button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    // Add space from the bottom
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
                        } else if (currentStep == totalSteps) {
                          consolidateAndUploadData(); // Upload the data to Firebase
                        }
                      },
                      child: Text(
                          currentStep == totalSteps ? "Submit" : "Next"),
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
      buildTextField("NRIC", "nric", nricController),
      SizedBox(height: 10),
      buildTextField("Full Name", "fullname", fullnameController),
      SizedBox(height: 10),
      buildTextField("Email", "email", emailController),
      SizedBox(height: 10),
      buildMobileNumberField("mobileNumber", mobileNumberController),
      SizedBox(height: 10),
      buildTextField("Address Line 1", "addressLine1", add1Controller),
      SizedBox(height: 10),
      buildTextField("Address Line 2", "addressLine2", add2Controller),
      SizedBox(height: 10),
      buildTextField("City", "city", cityController),
      SizedBox(height: 10),
      buildTextField("Postcode", "postcode", postcodeController),
    ];
  }

  List<Widget> buildEligibilityForm() {
    return [
      buildTextField("Residency Status", "residencyStatus", residencyController),
      SizedBox(height: 10),
      buildTextField("Employment Status", "employmentStatus", employmentController),
      SizedBox(height: 10),
      buildTextField("Monthly Income", "monthlyIncome", incomeController),
      SizedBox(height: 10),
      buildLongTextField("Justification of Application", "justificationApplication", justificationController),
    ];
  }

  List<Widget> buildUploadDocumentsForm() {
    return [
      buildEkycVerificationField(
        "Verify Your Identity (eKYC)",
        "Required for application",
      ),
      buildFileUploadField(
        "Proof of Address (e.g. Utility Bill)",
        "Proof of address",
        "Format: jpeg/jpg/pdf",
        "proofOfAddress",
        2,
      ),
      SizedBox(height: 10),
      buildFileUploadField(
        "Proof of Income",
        "Proof of income",
        "Format: jpeg/jpg/pdf",
        "proofOfIncome",
        3,
      ),
    ];
  }

  Widget buildEkycVerificationField(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Navigate to the EkycScreen and wait for a result
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EkycScreen()),
            );

            // The EkycScreen will pop with `true` if successful
            if (result == true) {
              setState(() {
                _isEkycComplete = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("eKYC Verification Successful!"),
                  backgroundColor: Colors.green,
                ),
              );
              // Optionally, you can now re-fetch user data to populate the NRIC
              // and Name fields on the first page if the user goes back.
              _fetchUserData();
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _isEkycComplete ? Colors.green : Color(0xFFFFCF40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEkycComplete ? "Verification Complete" : "Start eKYC Verification",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isEkycComplete ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> buildFourthPage() {
    return [
      buildFileDisplayField("Proof of Address (e.g. Utility Bill)", fileName2),
      SizedBox(height: 10),
      buildFileDisplayField("Proof of Income", fileName3),
    ];
  }

  // This method now updates all text field values into formData before uploading
  void consolidateAndUploadData() {
    // Update formData with the current text values from controllers
    formData["nric"] = nricController.text;
    formData["fullname"] = fullnameController.text;
    formData["email"] = emailController.text;
    formData["mobileNumber"] = mobileNumberController.text;
    formData["addressLine1"] = add1Controller.text;
    formData["addressLine2"] = add2Controller.text;
    formData["city"] = cityController.text;
    formData["postcode"] = postcodeController.text;
    formData["residencyStatus"] = residencyController.text;
    formData["employmentStatus"] = employmentController.text;
    formData["monthlyIncome"] = incomeController.text;
    formData["justificationApplication"] = justificationController.text;

    formData["proofOfAddress"] = fileName2 ?? "No file uploaded";
    formData["proofOfIncome"] = fileName3 ?? "No file uploaded";
    if (!_isEkycComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please complete the eKYC verification first."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop the submission
    }

    // Call a method to upload this data to Firebase
    uploadToFirebase(formData);
  }

  List<Widget> buildAgreementPage() {
    final ScrollController scrollController = ScrollController();

    return [
      SizedBox(height: 16),
      Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        // Show the scrollbar thumb
        thickness: 6,
        // Thickness of the scrollbar
        radius: Radius.circular(10),
        // Rounded corners for scrollbar
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point 1
                Text(
                  "1. Eligibility and Accuracy of Information",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCF40), // Color for the point
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '''
You confirm that all information provided in this application is true, complete, and accurate to the best of your knowledge.
You understand that providing false or misleading information may result in the rejection of your application and may impact your eligibility for future assistance.''',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9), // Color for the explanation
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                // Point 2
                Text(
                  "2. Use of Financial Aid",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCF40), // Color for the point
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '''
Financial aid provided through Kita Tongtong is intended solely for the purposes specified in the application, such as tuition fees, hostel fees, and other approved living expenses.
You agree to use any funds or vouchers received only as directed and for approved expenses within the platform’s guidelines.''',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9), // Color for the explanation
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                // Point 3
                Text(
                  "3. Privacy and Data Usage",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCF40), // Color for the point
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '''
By submitting this application, you consent to the collection, processing, and storage of your personal information as outlined in our Privacy Policy.
Your information will be used only to assess your eligibility for aid, manage fund disbursement, and ensure compliance with platform policies.''',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9), // Color for the explanation
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                // Point 4
                Text(
                  "4. Review and Verification Process",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCF40), // Color for the point
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '''
You acknowledge that Kita Tongtong may verify the information provided, which may include contacting relevant parties (such as universities, administrators) to validate your application.
Failure to provide requested information within the specified timeline may result in application delays or denial.''',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9), // Color for the explanation
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                  // Assign the uploaded file path
                  if (title.contains("NRIC"))
                    fileName1 = result.files.single.path!;
                  if (title.contains("Address"))
                    fileName2 = result.files.single.path!;
                  if (title.contains("Income"))
                    fileName3 = result.files.single.path!;
                });
              }
            } else {
              // If file exists, view the file
              if (fileName.endsWith('.pdf')) {
                print("Opening file: $fileName"); // Print full file path
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerScreen(filePath: fileName),
                  ),
                );
              }
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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/docAsnaf.png', height: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName != null ? path.basename(fileName) : "No file uploaded",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Image.asset('assets/trash.png', height: 24),
                  onPressed: () {
                    setState(() {
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

  Widget buildFileUploadField(String title, String label, String subtitle, String key, int index) {
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
                backgroundColor: Color(0xFFFFCF40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                try {
                  // Open file picker to select a file
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpeg', 'jpg', 'pdf'],
                  );
                  if (result != null) {
                    setState(() {
                      uploadedFileName = result.files.single.name;
                      if (index == 1) fileName1 = uploadedFileName;
                      if (index == 2) fileName2 = uploadedFileName;
                      if (index == 3) fileName3 = uploadedFileName;
                      formData[key] = uploadedFileName;
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
                height: 90,
                width: double.infinity,
                child: Center(
                  child: uploadedFileName == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/uploadAsnaf.png', height: 24),
                      SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
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
                    uploadedFileName!,
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

  Widget buildLongTextField(String label, String key, TextEditingController controller) {
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
          height: 120,
          decoration: BoxDecoration(
            color: Color(0xFFFFCF40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            onChanged: (value) {
              setState(() {
                formData[key] = value;
              });
            },
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label, String key, TextEditingController controller) {
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
            controller: controller,
            onChanged: (value) {
              setState(() {
                formData[key] = value;
              });
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMobileNumberField(String key, TextEditingController controller) {
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
                  controller: controller,
                  onChanged: (value) {
                    setState(() {
                      formData[key] = value;
                    });
                  },
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                    hintText: "Enter your mobile number",
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
