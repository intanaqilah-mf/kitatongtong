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
                    if (event["bannerUrl"] != null && event["bannerUrl"].isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2), // Set border radius
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