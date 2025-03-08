import 'package:flutter/material.dart';

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool isCreateEvent = false; // Toggle state for switch button
  final TextEditingController _controller = TextEditingController();
  Map<String, String> formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Events"),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          // Switch Buttons
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isCreateEvent = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: !isCreateEvent ? Colors.white : Colors.transparent,
                    ),
                    child: Text(
                      "List of Events",
                      style: TextStyle(
                        color: !isCreateEvent ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isCreateEvent = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isCreateEvent ? Colors.white : Colors.transparent,
                    ),
                    child: Text(
                      "Create Events",
                      style: TextStyle(
                        color: isCreateEvent ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Display Content Based on Switch
          Expanded(
            child: isCreateEvent ? buildCreateEventForm() : Center(child: Text("No Events Available")),
          ),
        ],
      ),
    );
  }

  // Form UI
  Widget buildCreateEventForm() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Events",
              style: TextStyle(
                color: Color(0xFFFDB515),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              "Create events here.",
              style: TextStyle(
                color: Color(0xFFAA820C),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            buildTextField("Enter Attendance Code", "attendanceCode"),
            buildTextField("Event Name", "eventName"),
            buildTextField("Points per attendance", "points"),
            buildTextField("Organiser’s name", "organiserName"),

            // Phone Number Field
            Text("Organiser’s number"),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
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
                      controller: _controller,
                      onChanged: (value) {
                        setState(() {
                          formData["organiserNumber"] = value;
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

            SizedBox(height: 12),
            buildTextField("Location", "location"),
            buildTextField("Event’s date (YYYY-MM-DD HH:mm)", "eventDate"),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle form submission logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
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
          Text(label),
          SizedBox(height: 4),
          TextField(
            onChanged: (value) {
              setState(() {
                formData[key] = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
