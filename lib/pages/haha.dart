import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Req
import 'package:projects/pages/eventReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
  final String documentId;
  EventPage({required this.documentId});
}

class _EventPageState extends State<EventPage> {
  bool isCreateEvent = false; // Toggle switch state
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _controller = TextEditingController();
  Map<String, String> formData = {};
  int _selectedIndex = 0;

  // Function to handle BottomNavBar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<DocumentSnapshot> fetchApplicationData(String documentId) async {
    return await FirebaseFirestore.instance.collection('applications').doc(documentId).get();
  }

  Future<DocumentSnapshot> fetchUserData(String userId) async {
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 70, left: 16, right: 16), // Move it lower
            child: Container(
              height: 50, // Increase height for better spacing
              decoration: BoxDecoration(
                color: Color(0xFFFDB515), // Match background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isCreateEvent = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isCreateEvent ? Color(0xFFFDB515) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "List of Events",
                          style: TextStyle(
                            color: !isCreateEvent ? Colors.white : Color(0xFFFDB515),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isCreateEvent = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCreateEvent ? Color(0xFFFDB515) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Create Events",
                          style: TextStyle(
                            color: isCreateEvent ? Colors.white : Color(0xFFFDB515),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Display Content Based on Switch
          Expanded(
            child: isCreateEvent ? buildCreateEventForm() : Center(child: Text("No Events Available", style: TextStyle(color: Colors.white))),
          ),
          FutureBuilder<DocumentSnapshot>(
            future: fetchApplicationData(widget.documentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('No data found for this applicant.'));
              }

              var applicationData = snapshot.data!;
              var fullname = applicationData['fullname'] ?? 'N/A';
              var mobileNumber = applicationData['mobileNumber'] ?? 'No phone number available';
              var email = applicationData['email'] ?? 'No email available';
              var addressLine1 = applicationData['addressLine1'] ?? 'No address available';
              var addressLine2 = applicationData['addressLine2'] ?? 'No address available';
              var city = applicationData['city'] ?? 'No address available';
              var postcode = applicationData['postcode'] ?? 'No address available';
              var justificationApplication = applicationData['justificationApplication'] ?? 'No justification available';
              var monthlyIncome = applicationData['monthlyIncome'] ?? 'No income available';
              var nric = applicationData['nric'] ?? 'No NRIC available';
              var userId = applicationData['userId'];
              var residencyStatus = applicationData['residencyStatus'] ?? 'Unknown';
              var employmentStatus = applicationData['employmentStatus'] ?? 'Unknown';
              var date = applicationData['date'] ?? 'No date available';
              var applicationCode = applicationData['applicationCode'] ?? 'No Code';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.16, 0.38, 0.58, 0.88],
                          colors: [
                            Color(0xFFF9F295),
                            Color(0xFFE0AA3E),
                            Color(0xFFF9F295),
                            Color(0xFFB88A44),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: fetchUserData(userId),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }
                              if (userSnapshot.hasError) {
                                return Text('Error: ${userSnapshot.error}');
                              }
                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, color: Colors.white),
                                );
                              }

                              var userData = userSnapshot.data!;
                              var photoUrl = userData['photoUrl'];

                              return CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(photoUrl ?? ''),
                                child: photoUrl == null
                                    ? Icon(Icons.person, size: 50, color: Colors.white)
                                    : null,
                              );
                            },
                          ),
                          SizedBox(height: 10),

                          // Application Code (Centered)
                          Text(
                            applicationCode,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Full Name: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: fullname, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Asnaf NRIC: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: nric, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Phone number: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: "60$mobileNumber", style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Address: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: "$addressLine1, $addressLine2, $postcode, $city", style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Residency Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: residencyStatus, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Employment Status: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: employmentStatus, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Monthly Income: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: monthlyIncome, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                                Text.rich(TextSpan(
                                  children: [
                                    TextSpan(text: "Justification of application: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    TextSpan(text: justificationApplication, style: TextStyle(fontSize: 16)),
                                  ],
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status and Reason sections
                    SizedBox(height: 20),

                    // Status Dropdown Section
                    Text("Status", style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),

                    ),

                    SizedBox(height: 20),

                    // Reason TextField
                    Text("Reason", style: TextStyle(color: Colors.white, fontSize: 16)),

                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Form UI
  Widget buildCreateEventForm() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            Text(
              "Create Events",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              "Create event here",
              style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            buildTextField("Enter Attendance Code", "attendanceCode"),
            buildTextField("Event Name", "eventName"),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Points per attendance",
                    style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFDB515),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          formData["points"] = value;
                        });
                      },
                      keyboardType: TextInputType.number, // Ensure numeric keyboard
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Restrict input to numbers only
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: "Enter points",
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            buildTextField("Organiser’s name", "organiserName"),

            // Phone Number Field
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organiser’s number",
                    style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFDB515),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                        Container( // Ensure Vertical Divider is visible
                          width: 1,
                          height: 42,
                          color: Colors.black, // Adjust color for visibility
                        ),
                        SizedBox(width: 8), // Space between divider and input field
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (value) {
                              setState(() {
                                formData["organiserNumber"] = value;
                              });
                            },
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(8),
                              hintText: "Enter your mobile number",
                              hintStyle: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            buildTextField("Location", "location"),

            // Event Date Picker
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Event’s date",
                    style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        String formattedDate = DateFormat("dd MMM yyyy").format(pickedDate);
                        setState(() {
                          _dateController.text = formattedDate;
                          formData["eventDate"] = formattedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dateController.text.isEmpty ? "Select Event Date" : _dateController.text,
                            style: TextStyle(color: Colors.black),
                          ),
                          Icon(Icons.calendar_today, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Ensure all required fields are filled before submitting
                if (formData["attendanceCode"] == null ||
                    formData["eventName"] == null ||
                    formData["points"] == null ||
                    formData["organiserName"] == null ||
                    formData["organiserNumber"] == null ||
                    formData["location"] == null ||
                    formData["eventDate"] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields!")),
                  );
                  return;
                }

                try {
                  // Store data in Firestore (Collection: "event")
                  await FirebaseFirestore.instance.collection("event").add({
                    "attendanceCode": formData["attendanceCode"],
                    "eventName": formData["eventName"],
                    "points": formData["points"],
                    "organiserName": formData["organiserName"],
                    "organiserNumber": formData["organiserNumber"],
                    "location": formData["location"],
                    "eventDate": formData["eventDate"],
                    "createdAt": Timestamp.now(), // Store timestamp
                  });

                  // Navigate to eventReview.dart
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventReview()), // Ensure EventReviewPage is implemented
                  );
                } catch (e) {
                  print("Error storing event: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to store event. Please try again.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFDB515),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Center(child: Text("Submit", style: TextStyle(fontSize: 16, color: Colors.black))),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Text Field Widget
  Widget buildTextField(String label, String key) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFDB515),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  formData[key] = value;
                });
              },
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
