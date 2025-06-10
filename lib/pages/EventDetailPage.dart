import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // <-- 1. IMPORT FOR DATE FORMATTING
import 'package:qr_flutter/qr_flutter.dart'; // <-- 2. IMPORT FOR QR CODE

class EventDetailPage extends StatelessWidget {
  final DocumentSnapshot event;

  const EventDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely extract data from the event document
    final String bannerUrl = event['bannerUrl'] ?? '';
    final String eventName = event['eventName'] ?? 'No Name';
    final String points = event['points'] ?? '0';
    final String organiserName = event['organiserName'] ?? 'Unknown';
    final String organiserNumber = event['organiserNumber'] ?? 'N/A';
    final String location = event['location'] ?? 'Unknown';
    final String startDateString = event['eventDate'] ?? '';
    final String endDateString = event['eventEndDate'] ?? '';

    // --- 3. LOGIC TO CHECK IF EVENT IS ONGOING ---
    bool isOngoing = false;
    if (startDateString.isNotEmpty && endDateString.isNotEmpty) {
      try {
        final fmt = DateFormat("dd MMM yyyy HH:mm");
        final DateTime startDate = fmt.parse(startDateString);
        final DateTime endDate = fmt.parse(endDateString);
        final now = DateTime.now();
        // Check if 'now' is between the start and end date
        isOngoing = !now.isBefore(startDate) && now.isBefore(endDate);
      } catch (e) {
        // Handle potential date parsing errors gracefully
        print("Error parsing event dates on detail page: $e");
        isOngoing = false;
      }
    }
    // --- END OF ONGOING LOGIC ---

    return Scaffold(
      backgroundColor: Color(0xFF303030), // Match existing background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFDB515)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Event Details',
          style: TextStyle(
            color: Color(0xFFFDB515),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Banner Image
              if (bannerUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    bannerUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Event Name Title
              Text(
                eventName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 16),

              // Gold Gradient Container for Details
              Container(
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
                  children: [
                    _buildDetailRow(icon: Icons.star_rounded, label: "Points to Earn", value: "$points pts"),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.calendar_today_rounded, label: "Starts On", value: startDateString),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.event_available_rounded, label: "Ends On", value: endDateString),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.location_on_rounded, label: "Location", value: location),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.person_rounded, label: "Organiser", value: organiserName),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.phone_rounded, label: "Contact", value: "+60$organiserNumber"),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // --- 4. CONDITIONALLY DISPLAY QR CODE BUTTON ---
              if (isOngoing)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFDB515),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final String attendanceCode = event['attendanceCode'] ?? '';
                    if (attendanceCode.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Scan for Attendance', textAlign: TextAlign.center),
                          content: SizedBox(
                            width: 250,
                            height: 250,
                            child: QrImageView(
                              data: attendanceCode,
                              version: QrVersions.auto,
                              size: 250.0,
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close', style: TextStyle(color: Color(0xFFFDB515), fontSize: 16)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Attendance code is not available for this event.")),
                      );
                    }
                  },
                  icon: Icon(Icons.qr_code_2_rounded, color: Colors.white),
                  label: Text(
                    'Show Attendance QR',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              // --- END OF QR CODE BUTTON ---
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to create a styled divider
  Widget _buildDivider() {
    return Divider(color: Colors.black.withOpacity(0.15), height: 1);
  }

  // Helper widget for each detail row to avoid repetition
  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}