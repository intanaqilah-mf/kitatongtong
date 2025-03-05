import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyApplicationsScreen extends StatefulWidget {
  @override
  _VerifyApplicationsScreenState createState() => _VerifyApplicationsScreenState();
}

class _VerifyApplicationsScreenState extends State<VerifyApplicationsScreen> {
  String searchQuery = "";
  String filterOption = "All";
  String sortOption = "Date";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Verify Applications", style: TextStyle(color: Colors.amber)),
        iconTheme: IconThemeData(color: Colors.amber),
      ),
      body: Column(
        children: [
          // Search and filter row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: "Search Asnaf",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Filter Button
                DropdownButton<String>(
                  value: filterOption,
                  onChanged: (newValue) {
                    setState(() {
                      filterOption = newValue!;
                    });
                  },
                  items: ["All", "Pending", "Approved", "Rejected"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8),
                // Sort Button
                DropdownButton<String>(
                  value: sortOption,
                  onChanged: (newValue) {
                    setState(() {
                      sortOption = newValue!;
                    });
                  },
                  items: ["Date", "Name"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('applications').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var applications = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where((app) => searchQuery.isEmpty || app['name'].toLowerCase().contains(searchQuery))
                    .where((app) => filterOption == "All" || app['status'] == filterOption)
                    .toList();

                if (sortOption == "Date") {
                  applications.sort((a, b) => b['date'].compareTo(a['date']));
                } else if (sortOption == "Name") {
                  applications.sort((a, b) => a['name'].compareTo(b['name']));
                }

                return ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    var app = applications[index];
                    return Card(
                      color: Colors.black87,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage("assets/avatar_placeholder.png"), // Replace with user image if available
                        ),
                        title: Text(app['name'], style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app['date'], style: TextStyle(color: Colors.grey)),
                            Text("Submitted by: ${app['submitted_by']}", style: TextStyle(color: Colors.amber)),
                          ],
                        ),
                        trailing: Text(
                          app['status'],
                          style: TextStyle(
                            color: app['status'] == "Pending"
                                ? Colors.orange
                                : app['status'] == "Approved"
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationDetailScreen(application: app),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Detail Page for Application Review
class ApplicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> application;

  ApplicationDetailScreen({required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Application Details", style: TextStyle(color: Colors.amber)),
        iconTheme: IconThemeData(color: Colors.amber),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${application['name']}", style: TextStyle(fontSize: 18, color: Colors.white)),
            Text("Date: ${application['date']}", style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text("Submitted by: ${application['submitted_by']}", style: TextStyle(fontSize: 16, color: Colors.amber)),
            Text("Status: ${application['status']}", style: TextStyle(fontSize: 16, color: Colors.white)),

            SizedBox(height: 20),

            // Buttons to Approve/Reject
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('applications')
                        .doc(application['id']) // Ensure `id` is stored in each application document
                        .update({'status': 'Approved'});

                    Navigator.pop(context);
                  },
                  child: Text("Approve"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('applications')
                        .doc(application['id'])
                        .update({'status': 'Rejected'});

                    Navigator.pop(context);
                  },
                  child: Text("Reject"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
