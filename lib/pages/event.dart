import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:projects/pages/eventReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

File? _selectedImage;
String? _uploadedImageUrl;
String? _editingDocId;
final TextEditingController _attendanceCodeController = TextEditingController();
final TextEditingController _eventNameController = TextEditingController();
final TextEditingController _pointsController = TextEditingController();
final TextEditingController _organiserNameController = TextEditingController();
final TextEditingController _locationController = TextEditingController();

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

  void _populateForm(Map<String, dynamic> event, String docId) {
    setState(() {
      _editingDocId = docId; // Store the document ID for Firestore updates

      formData["attendanceCode"] = event["attendanceCode"] ?? "";
      formData["eventName"] = event["eventName"] ?? "";
      formData["points"] = event["points"] ?? "";
      formData["organiserName"] = event["organiserName"] ?? "";
      formData["organiserNumber"] = event["organiserNumber"] ?? "";
      formData["location"] = event["location"] ?? "";
      formData["eventDate"] = event["eventDate"] ?? "";
      _uploadedImageUrl = event["bannerUrl"] ?? "";

      // ✅ Ensure controllers update dynamically
      _dateController.text = formData["eventDate"]!;
      _controller.text = formData["organiserNumber"]!;
      _attendanceCodeController.text = formData["attendanceCode"]!;
      _eventNameController.text = formData["eventName"]!;
      _pointsController.text = formData["points"]!;
      _organiserNameController.text = formData["organiserName"]!;
      _locationController.text = formData["location"]!;
    });
  }

  Future<void> _pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }
}

Future<void> _uploadImageToFirebase() async {
  if (_selectedImage == null) return;

  try {
    String fileName = "event_banners/${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference ref = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(_selectedImage!);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      _uploadedImageUrl = downloadUrl;
      formData["bannerUrl"] = downloadUrl; // Store the URL in form data
    });
  } catch (e) {
    print("Error uploading image: $e");
  }
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
            String docId = doc.id; // Capture the document ID

            return GestureDetector(
              onTap: () {
                setState(() {
                  isCreateEvent = true; // Switch to Create Event form
                  _populateForm(event, docId); // Populate form fields
                });
              },
              child: Padding(
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
                      if (event["bannerUrl"] != null && event["bannerUrl"].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            event["bannerUrl"],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(height: 8),

                      Center(
                        child: Text(
                          event["eventName"] ?? "No Name",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.50,
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

            buildTextField("Enter Attendance Code", "attendanceCode", _attendanceCodeController),
            buildTextField("Event Name", "eventName", _eventNameController),
            buildTextField("Points per attendance", "points", _pointsController),
            buildTextField("Organiser’s name", "organiserName", _organiserNameController),
            buildTextField("Location", "location", _locationController),

            // ✅ Ensure Date Field is Pre-Filled Correctly
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

            // ✅ Event Banner Field
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Event Banner",
                    style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.circular(8),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_selectedImage == null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty))
                          ? Center(
                        child: Icon(Icons.add_a_photo, color: Colors.black, size: 40),
                      )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ✅ Submit Button Now Works for Both Create & Edit
            ElevatedButton(
              onPressed: () async {
                if (_editingDocId != null) {
                  await FirebaseFirestore.instance.collection("event").doc(_editingDocId).update(formData);
                } else {
                  await FirebaseFirestore.instance.collection("event").add(formData);
                }
                _editingDocId = null;
                Navigator.push(context, MaterialPageRoute(builder: (context) => EventReview()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFDB515),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Center(child: Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }


  // Reusable Text Field Widget
  Widget buildTextField(String label, String key, TextEditingController controller) {
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
              controller: controller, // ✅ Now fields will update dynamically
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
