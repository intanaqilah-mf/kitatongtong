import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScreeningApplicants extends StatefulWidget {
  final Map<String, dynamic> applicationData;

  ScreeningApplicants({required this.applicationData});

  @override
  _ScreeningApplicantsState createState() => _ScreeningApplicantsState();
}

class _ScreeningApplicantsState extends State<ScreeningApplicants> {
  @override
  Widget build(BuildContext context) {
    // Use widget.applicationData to access the passed data
    return Scaffold(
      appBar: AppBar(title: Text('Screening Applicant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Full Name: ${widget.applicationData['fullname']}", style: TextStyle(color: Colors.white)),
            Text("Date: ${widget.applicationData['date']}", style: TextStyle(color: Colors.white)),
            Text("Submitted by: ${widget.applicationData['submitted_by']}", style: TextStyle(color: Colors.white)),
            Text("Status: ${widget.applicationData['status']}", style: TextStyle(color: Colors.white)),
            // Add other fields as needed
          ],
        ),
      ),
    );
  }
}
