import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class EventDetailPage extends StatelessWidget {
  final DocumentSnapshot event;

  const EventDetailPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely extract data
    final String bannerUrl = (event['bannerUrl'] ?? '').toString();
    final String eventName = (event['eventName'] ?? 'No Name').toString();
    final String points = (event['points'] ?? '0').toString();
    final String organiserName = (event['organiserName'] ?? 'Unknown').toString();
    final String organiserNumber = (event['organiserNumber'] ?? 'N/A').toString();
    final String startDateString = (event['eventDate'] ?? '').toString();
    final String endDateString = (event['eventEndDate'] ?? '').toString();

    // Handle both Map and String for location
    final dynamic locationData = event['location'];
    String locationAddress = 'Unknown';
    if (locationData is Map) {
      locationAddress = locationData['address'] ?? 'No location provided';
    } else if (locationData is String) {
      locationAddress = locationData;
    }

    // --- FIX 1: CORRECTED THE DATE FORMAT TO FIX THE isOngoing CHECK ---
    bool isOngoing = false;
    if (startDateString.isNotEmpty && endDateString.isNotEmpty) {
      try {
        // The date format was wrong here, causing the button to hide. It is now fixed.
        final fmt = DateFormat("dd MMM yyyy HH:mm");
        final DateTime startDate = fmt.parse(startDateString);
        final DateTime endDate = fmt.parse(endDateString);
        final now = DateTime.now();
        isOngoing = !now.isBefore(startDate) && now.isBefore(endDate);
      } catch (e) {
        print("Error parsing event dates on detail page: $e");
        isOngoing = false;
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFF303030),
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
                    _buildDetailRow(icon: Icons.location_on_rounded, label: "Location", value: locationAddress),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.person_rounded, label: "Organiser", value: organiserName),
                    _buildDivider(),
                    _buildDetailRow(icon: Icons.phone_rounded, label: "Contact", value: "+60$organiserNumber"),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // --- FIX 2: RESTORED AND STYLED QR BUTTON EXACTLY LIKE IN event.dart ---
              if (isOngoing)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFDB515),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final String attendanceCode = (event['attendanceCode'] ?? '').toString();
                    if (attendanceCode.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Event QR Code'),
                          content: SizedBox(
                            width: 200.0,
                            height: 200.0,
                            child: qr.QrImageView(
                              data: attendanceCode,
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Attendance code is not available for this event.")),
                      );
                    }
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
  }

  Widget _buildDivider() {
    return Divider(color: Colors.black.withOpacity(0.15), height: 1);
  }

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