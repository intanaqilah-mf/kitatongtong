import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:projects/pages/eventReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

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
final TextEditingController _dateController = TextEditingController();
enum EventFilter { Upcoming, Ongoing, Past }

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool isCreateEvent = false;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  Map<String, dynamic> formData = {};
  int _selectedIndex = 0;
  double _pointsValue = 10.0;
  EventFilter _selectedFilter = EventFilter.Upcoming;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _resetForm() {
    setState(() {
      _editingDocId = null;
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
      formData.clear();
      _selectedImage = null;
      _uploadedImageUrl = null;
      selectedSection = 'Upcoming Activities';
    });
  }

  void _onCreateEvent() {
    _resetForm();
    setState(() {
      isCreateEvent = true;
    });
  }

  void _populateForm(Map<String, dynamic> event, String docId) {
    setState(() {
      _editingDocId = docId;

      _dateController.text = event["eventDate"] ?? "";
      _endDateController.text = event["eventEndDate"] ?? "";
      _attendanceCodeController.text = event["attendanceCode"] ?? "";
      _eventNameController.text = event["eventName"] ?? "";
      _pointsController.text = event["points"] ?? "";
      _pointsValue = double.tryParse(event["points"] ?? '10.0') ?? 10.0;
      _organiserNameController.text = event["organiserName"] ?? "";
      _controller.text = event["organiserNumber"] ?? "";

      final locationData = event['location'];
      if (locationData is Map) {
        _locationController.text = locationData['address'] ?? '';
      } else if (locationData is String) {
        _locationController.text = locationData;
      }

      _uploadedImageUrl = event["bannerUrl"];
      selectedSection = event["sectionEvent"] ?? "Upcoming Activities";

      formData = Map<String, dynamic>.from(event);
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
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection("event").get();

    eventSections.clear();
    eventSections["Upcoming Activities"] = true;
    eventSections["Others"] = true;

    Map<String, int> sectionCount = {};

    for (var doc in snapshot.docs) {
      String section = doc["sectionEvent"] ?? "";
      if (section.isNotEmpty) {
        sectionCount[section] = (sectionCount[section] ?? 0) + 1;
      }
    }

    sectionCount.forEach((section, count) {
      if (count > 0) {
        eventSections[section] = true;
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    try {
      String fileName = "event_banners/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      _uploadedImageUrl = await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _selectDateTime(BuildContext context, TextEditingController controller, String key) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        String formattedDateTime = DateFormat("dd MMM yyyy HH:mm").format(fullDateTime);
        setState(() {
          controller.text = formattedDateTime;
          formData[key] = formattedDateTime;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 70, left: 16, right: 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFFDB515),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _onCreateEvent();
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
          if (!isCreateEvent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterButton(EventFilter.Upcoming, "Upcoming"),
                  _buildFilterButton(EventFilter.Ongoing, "Ongoing"),
                  _buildFilterButton(EventFilter.Past, "Past"),
                ],
              ),
            ),
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

  Widget _buildFilterButton(EventFilter filter, String text) {
    final isSelected = _selectedFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Color(0xFFFDB515),
        foregroundColor: isSelected ? Color(0xFFFDB515) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    );
  }

  Widget buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("event").orderBy("updatedAt", descending: true).snapshots(),
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

        final now = DateTime.now();
        final fmt = DateFormat("dd MMM yyyy HH:mm");

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final event = doc.data() as Map<String, dynamic>;
          DateTime? startDate, endDate;

          try {
            if (event['eventDate'] != null && event['eventDate'].isNotEmpty) {
              startDate = fmt.parse(event['eventDate']);
            }
            if (event['eventEndDate'] != null && event['eventEndDate'].isNotEmpty) {
              endDate = fmt.parse(event['eventEndDate']);
            }
          } catch (_) {
            return false;
          }

          if (startDate == null || endDate == null) return false;

          switch (_selectedFilter) {
            case EventFilter.Upcoming:
              return startDate.isAfter(now);
            case EventFilter.Ongoing:
              return !now.isBefore(startDate) && now.isBefore(endDate);
            case EventFilter.Past:
              return now.isAfter(endDate);
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              "No ${(_selectedFilter.toString().split('.').last)} Events",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: filteredDocs.map((doc) {
            final event = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            DateTime? startDate, endDate;
            try {
              startDate = fmt.parse(event['eventDate'] ?? '');
              endDate = fmt.parse(event['eventEndDate'] ?? '');
            } catch (_) {}

            final isOngoing = startDate != null &&
                endDate != null &&
                !now.isBefore(startDate) &&
                now.isBefore(endDate);

            final locationData = event['location'];
            String locationAddress = "Unknown";
            if (locationData is Map) {
              locationAddress = locationData['address'] ?? 'Unknown';
            } else if (locationData is String) {
              locationAddress = locationData;
            }


            return Dismissible(
              key: Key(docId),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                FirebaseFirestore.instance.collection("event").doc(docId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${event["eventName"]} deleted")),
                );
              },
              background: Container(
                color: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 20),
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: GestureDetector(
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
                      if (event["bannerUrl"] != null &&
                          event["bannerUrl"].isNotEmpty)
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Location: $locationAddress",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          if (locationData is Map && locationData['latitude'] != null && locationData['longitude'] != null)
                            IconButton(
                              icon: Icon(Icons.location_on, color: Colors.blue.shade800),
                              onPressed: () async {
                                final lat = locationData['latitude'];
                                final lng = locationData['longitude'];
                                // This URL will open Google Maps and place a pin at the coordinates.
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Could not open map.")),
                                  );
                                }
                              },
                            )
                        ],
                      ),
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
                                content: SizedBox(
                                  width: 200.0,
                                  height: 200.0,
                                  child: qr.QrImageView(
                                    data: event['attendanceCode'] ?? '',
                                    version: qr.QrVersions.auto,
                                    size: 200.0,
                                  ),
                                ),
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
              _editingDocId == null ? "Create Event" : "Edit Event",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDB515)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              "Fill in the details below",
              style: TextStyle(fontSize: 14, color: Color(0xFFAA820C)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
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
                      divisions: 9,
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organiser’s Number",
                    style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "+60",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 42,
                          color: Colors.black,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (value) {
                              formData["organiserNumber"] = value;
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
            buildLocationPicker("Location", "location", _locationController),
            buildDateTimePicker("Event’s start date & time", "eventDate", _dateController),
            buildDateTimePicker("Event’s end date & time", "eventEndDate", _endDateController),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Event Section",
                    style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFDB515),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSection,
                        isExpanded: true,
                        items: eventSections.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSection = newValue;
                          });
                        },
                        dropdownColor: Color(0xFFFDB515),
                      ),
                    ),
                  ),
                  if (selectedSection == 'Others')
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: buildTextField("Custom Section Name", "customSection", _sectionController),
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
                    style: TextStyle(
                        color: Color(0xFFFDB515),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB515),
                        borderRadius: BorderRadius.circular(8),
                        image: _selectedImage != null
                            ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover)
                            : (_uploadedImageUrl != null &&
                            _uploadedImageUrl!.isNotEmpty)
                            ? DecorationImage(
                            image: NetworkImage(_uploadedImageUrl!),
                            fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_selectedImage == null &&
                          (_uploadedImageUrl == null ||
                              _uploadedImageUrl!.isEmpty))
                          ? Center(
                        child: Icon(Icons.add_a_photo,
                            color: Colors.black, size: 40),
                      )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_dateController.text.isEmpty || _endDateController.text.isEmpty || _eventNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all required fields!")),
                  );
                  return;
                }

                if (_selectedImage != null) {
                  await _uploadImageToFirebase();
                }

                String sectionEvent = selectedSection == "Others" ? _sectionController.text : selectedSection ?? "Upcoming Activities";

                formData['attendanceCode'] = _attendanceCodeController.text;
                formData['eventName'] = _eventNameController.text;
                formData['organiserName'] = _organiserNameController.text;
                formData["bannerUrl"] = _uploadedImageUrl ?? "";
                formData["sectionEvent"] = sectionEvent;

                Map<String, dynamic> eventData = Map<String, dynamic>.from(formData);
                eventData["updatedAt"] = Timestamp.now();


                if (_editingDocId != null) {
                  await FirebaseFirestore.instance.collection("event").doc(_editingDocId).update(eventData);
                } else {
                  await FirebaseFirestore.instance.collection("event").add(eventData);
                }

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => EventReview()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFDB515),
                minimumSize: Size(double.infinity, 50),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Center(
                  child: Text("Submit",
                      style: TextStyle(fontSize: 16, color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLocationPicker(String label, String key, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: Color(0xFFFDB515),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapPickerPage()),
              );

              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  controller.text = result['address'];
                  formData[key] = result;
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
                  Expanded(
                    child: Text(
                      controller.text.isEmpty
                          ? "Pin location on map"
                          : controller.text,
                      style: TextStyle(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.map, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateTimePicker(String label, String key, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: Color(0xFFFDB515),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          GestureDetector(
            onTap: () => _selectDateTime(context, controller, key),
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
                    controller.text.isEmpty
                        ? "Select Date & Time"
                        : controller.text,
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

  Widget buildTextField(String label, String key, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                color: Color(0xFFFDB515),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFDB515),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              onChanged: (value) {
                formData[key] = value;
              },
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: label,
                hintStyle: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPickerPage extends StatefulWidget {
  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  Marker? _selectedMarker;
  static const LatLng _initialPosition = LatLng(3.1390, 101.6869); // Kuala Lumpur

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedMarker = Marker(
        markerId: MarkerId('selected-location'),
        position: position,
      );
    });
  }

  Future<void> _searchAndNavigate() async {
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 15.0,
          ),
        ));
        setState(() {
          _selectedMarker = Marker(
            markerId: MarkerId('selected-location'),
            position: LatLng(location.latitude, location.longitude),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location not found.")));
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error finding location.")));
    }
  }


  void _onConfirm() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a location on the map.")));
      return;
    }

    try {
      final position = _selectedMarker!.position;
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = "${placemark.name}, ${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
        Navigator.pop(context, {
          'address': address,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not get address for the location.")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pin Location'),
        backgroundColor: Color(0xFF303030),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 11.0,
            ),
            onTap: _onTap,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for an address',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      onSubmitted: (_) => _searchAndNavigate(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchAndNavigate,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: Icon(Icons.check),
              label: Text('Confirm Location'),
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFDB515),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          )
        ],
      ),
    );
  }
}