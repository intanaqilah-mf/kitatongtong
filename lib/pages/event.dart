import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Req
import 'package:projects/pages/eventReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
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
            child: isCreateEvent ? buildCreateEventForm() : buildEventList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("event").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No Events Available",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> event = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                child: Text(
                event["eventName"] ?? "No Name",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.50, // Set line height to 1.50
                  ),
                  textAlign: TextAlign.center,
                ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Event Name: ${event["eventName"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Points per attendance: ${event["points"] ?? "0"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Organiser's name: ${event["organiserName"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Organiser’s Number: ${event["organiserNumber"] ?? "N/A"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Location: ${event["location"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Event Date: ${event["eventDate"] ?? "Unknown"}",
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      "Attendance Code: ${event["attendanceCode"] ?? "N/A"}",
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
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
            buildTextField("Points per attendance", "points"),
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
