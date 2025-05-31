import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:projects/pages/eventReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:intl/intl.dart';

File? _selectedImage;
String? _uploadedImageUrl;
String? _editingDocId;
String? selectedSection = 'Upcoming Activities';
Map<String, bool> eventSections = {
  "Upcoming Activities": true,
  "Others": true
};

final TextEditingController _attendanceCodeController = TextEditingController();
final TextEditingController _eventNameController = TextEditingController();
final TextEditingController _pointsController = TextEditingController();
final TextEditingController _organiserNameController = TextEditingController();
final TextEditingController _organiserNumberController = TextEditingController();
final TextEditingController _locationController = TextEditingController();
final TextEditingController _endDateController = TextEditingController();

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool isCreateEvent = false; // Toggle switch state
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  Map<String, String> formData = {};
  int _selectedIndex = 0;
  String? _editingDocId;
  double _pointsValue = 10.0;
  bool _isTodayBetween(DateTime start, DateTime end) {
    final today = DateTime.now();
    return !today.isBefore(start) && !today.isAfter(end);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _resetForm() {
    setState(() {
      _editingDocId = null; // Ensure no document is being edited
      _dateController.clear();
      _endDateController.clear();
      _controller.clear();
      _sectionController.clear();
      _attendanceCodeController.clear();
      _eventNameController.clear();
      _pointsController.clear();
      _organiserNameController.clear();
      _organiserNumberController.clear();
      _locationController.clear();
      _pointsValue = 10.0;
      formData.clear(); // Clear all form data
      _uploadedImageUrl = null;
      selectedSection = 'Upcoming Activities'; // Reset dropdown
    });
  }

  void _onCreateEvent() {
    _resetForm(); // Reset form first
    setState(() {
      isCreateEvent = true;
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
      formData["eventEndDate"] = event["eventEndDate"] ?? "";
      _uploadedImageUrl = event["bannerUrl"] ?? "";
      selectedSection = event["sectionEvent"] ?? "Upcoming Activities"; // Retrieve section

      // ✅ Ensure controllers update dynamically
      _dateController.text = formData["eventDate"]!;
      _endDateController.text = formData["eventEndDate"]!;
      _controller.text = formData["organiserNumber"]!;
      _attendanceCodeController.text = formData["attendanceCode"]!;
      _eventNameController.text = formData["eventName"]!;
      _pointsController.text = formData["points"]!;
      _organiserNameController.text = formData["organiserName"]!;
      _organiserNumberController.text = formData["organiserNumber"]!;
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
  Future<void> _fetchSections() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("event").get();

    // Clear previous sections
    eventSections.clear();
    eventSections["Upcoming Activities"] = true;
    eventSections["Others"] = true;

    // Count events per section
    Map<String, int> sectionCount = {};

    for (var doc in snapshot.docs) {
      String section = doc["sectionEvent"] ?? "";
      if (section.isNotEmpty) {
        sectionCount[section] = (sectionCount[section] ?? 0) + 1;
      }
    }

    // Only add sections that have at least one event
    sectionCount.forEach((section, count) {
      if (count > 0) {
        eventSections[section] = true;
      }
    });

    setState(() {});
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
        formData["bannerUrl"] = downloadUrl;
      });

      if (_editingDocId != null) {
        await FirebaseFirestore.instance.collection("event").doc(_editingDocId).update({
          "bannerUrl": downloadUrl,
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }
  Widget buildEndDatePicker() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Event's End Date",
            style: TextStyle(
              color: Color(0xFFBB86FC), // Use a different accent color
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
                String formattedDate =
                DateFormat("dd MMM yyyy").format(pickedDate);
                setState(() {
                  _endDateController.text = formattedDate;
                  formData["eventEndDate"] = formattedDate;
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFFBB86FC).withOpacity(0.2), // distinct background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _endDateController.text.isEmpty
                        ? "Select Event End Date"
                        : _endDateController.text,
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(Icons.calendar_today, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchSections(); // Fetch sections when the page loads
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
                        _onCreateEvent(); // Call reset method before opening form
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCreateEvent ? Colors.white : Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Create Events",
                          style: TextStyle(
                            color: isCreateEvent ? Color(0xFFFDB515) : Colors.white,
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
                          isCreateEvent = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isCreateEvent ? Colors.white : Color(0xFFFDB515),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "List of Events",
                          style: TextStyle(
                            color: !isCreateEvent ? Color(0xFFFDB515) : Colors.white,
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

  // ✅ Ensuring "Points" field only accepts numbers

  Widget buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("event").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(
            child: Text(
              "No Events Available",
              style: TextStyle(color: Colors.white),
            ),
          );

        return ListView(
          padding: EdgeInsets.all(16),
          children: snapshot.data!.docs.map((doc) {
            final event = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            // ── NEW: parse your saved strings into DateTimes ──
            final fmt = DateFormat('dd MMM yyyy');
            DateTime? startDate, endDate;
            try {
              startDate = fmt.parse(event['eventDate'] ?? '');
              endDate   = fmt.parse(event['eventEndDate'] ?? '');
            } catch (_) {}
            final now = DateTime.now();
            final isOngoing = startDate != null
                && endDate   != null
                && !now.isBefore(startDate)
                && !now.isAfter(endDate);

            return GestureDetector(
              onTap: () {
                setState(() {
                  isCreateEvent = true;
                  _populateForm(event, docId);
                });
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
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
                          height: 1.5,
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

                    // ── NEW: only show when today ∈ [startDate, endDate] ──
                    if (isOngoing) SizedBox(height: 8),
                    if (isOngoing)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Event QR Code'),
                              // --- START OF CHANGE ---
                              content: SizedBox( // Wrap QrImageView with SizedBox
                                width: 200.0,
                                height: 200.0,
                                child: qr.QrImageView(
                                  data: event['attendanceCode'] ?? '',
                                  version: qr.QrVersions.auto,
                                  size: 200.0,
                                ),
                              ),
                              // --- END OF CHANGE ---
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.qr_code, color: Colors.white),
                        label: Text(
                          'Generate QR Code',
                          style: TextStyle(color: Colors.white),
                        ),
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

            // Event form fields
            buildTextField("Enter Attendance Code", "attendanceCode", _attendanceCodeController),
            buildTextField("Event Name", "eventName", _eventNameController),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Points per attendance",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF1D789),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFFF1D789),
                      inactiveTrackColor: Color(0xFFF1D789),
                      thumbColor: Color(0xFFEFBF04),
                      overlayColor: Color(0xFFEFBF04).withOpacity(0.3),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _pointsValue,
                      min: 10,
                      max: 100,
                      divisions: 9, // steps of 10
                      label: "${_pointsValue.round()} pts",
                      onChanged: (value) {
                        setState(() {
                          _pointsValue = value;
                          formData["points"] = value.round().toString();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            buildTextField("Organiser’s name", "organiserName", _organiserNameController),

            // Organiser's Number field
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organiser’s Number",
                    style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(color: Color(0xFFFDB515), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "+60",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: Colors.black, // Divider color
                        ),
                        SizedBox(width: 8),
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

            // Location Field
            buildTextField("Location", "location", _locationController),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Event’s start date",
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Event’s end date",
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
                          _endDateController.text = formattedDate;
                          formData["eventEndDate"] = formattedDate;
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
                            _endDateController.text.isEmpty ? "Select Event End Date" : _endDateController.text,
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
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Event Section",
                  style: TextStyle(color: Color(0xFFFDB515), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFDB515), // ✅ Set background color
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: eventSections.containsKey(selectedSection) ? selectedSection : null,
                      items: eventSections.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: Colors.black)), // ✅ Ensure text is visible
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSection = newValue;
                        });
                      },
                      dropdownColor: Color(0xFFFDB515), // ✅ Ensure dropdown matches field color
                    ),
                  ),
                ),

                if (selectedSection == 'Others')
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515), // ✅ Background color applied
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _sectionController,
                        style: TextStyle(color: Colors.black), // ✅ Ensure text is visible
                        decoration: InputDecoration(
                          labelText: "Enter Custom Section Name",
                          labelStyle: TextStyle(color: Colors.black), // ✅ Label color for visibility
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // ✅ Border color when focused
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // ✅ Border color when not focused
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ✅ Better spacing
                          filled: true,
                          fillColor: Color(0xFFFDB515), // ✅ Ensure background color remains inside
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

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

            // Submit Button
            ElevatedButton(
              onPressed: () async {
                if (formData["attendanceCode"] == null ||
                    formData["eventName"] == null ||
                    formData["points"] == null ||
                    formData["organiserName"] == null ||
                    formData["organiserNumber"] == null ||
                    formData["location"] == null ||
                    formData["eventDate"] == null ||
                    formData["eventEndDate"] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields!")),
                  );
                  return;
                }

                try {
                  if (_selectedImage != null) {
                    await _uploadImageToFirebase();
                  }

                  // Store Section Info
                  String sectionEvent = selectedSection == "Others" ? (_sectionController.text.isEmpty ? "Custom Section" : _sectionController.text) : selectedSection ?? "Upcoming Activities";


                  Map<String, dynamic> eventData = {
                    "attendanceCode": formData["attendanceCode"],
                    "eventName": formData["eventName"],
                    "points": formData["points"],
                    "organiserName": formData["organiserName"],
                    "organiserNumber": formData["organiserNumber"],
                    "location": formData["location"],
                    "eventDate": formData["eventDate"],
                    "eventEndDate": formData["eventEndDate"] ?? "",
                    "bannerUrl": _uploadedImageUrl ?? "",
                    "sectionEvent": sectionEvent,
                    "updatedAt": Timestamp.now(),
                  };

                  if (_editingDocId != null) {
                    // UPDATE EXISTING EVENT
                    await FirebaseFirestore.instance.collection("event").doc(_editingDocId).update(eventData);
                  } else {
                    // CREATE NEW EVENT
                    await FirebaseFirestore.instance.collection("event").add(eventData);
                  }

                  // Reset editing state
                  _editingDocId = null;

                  // Refresh UI and navigate
                  setState(() {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventReview()),
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
