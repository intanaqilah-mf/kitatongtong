import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/packageRedeem.dart';

class PackageKasihPage extends StatefulWidget {
  final int rmValue;
  PackageKasihPage({required this.rmValue});
  @override
  _PackageKasihPageState createState() =>
      _PackageKasihPageState();
}

class _PackageKasihPageState extends State<PackageKasihPage> {
  int _selectedIndex = 0;
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
          // Custom header replacing AppBar
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 80, 16, 15),
            child: Column(
              children: [
                Text(
                  "Package Kasih",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0),
                Text(
                  "List of available packages you can choose from.",
                  style: TextStyle(
                    color: Color(0xFFAA820C),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // List of packages from Firestore
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("package_kasih")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No Package Kasih available",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final valStr = (doc['value'] as String).replaceAll("RM ", "").trim();
                    final val = int.tryParse(valStr);
                    return val == widget.rmValue;
                  }).toList();

                  docs.sort((a, b) {
                    int valueA = int.tryParse(
                        (a['value'] as String).replaceAll("RM ", "")) ??
                        0;
                    int valueB = int.tryParse(
                        (b['value'] as String).replaceAll("RM ", "")) ??
                        0;
                    return valueA.compareTo(valueB);
                  });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final bannerUrl = data['bannerUrl'] ?? '';
                      final value = data['value'] ?? 'RM 0';
                      final items = data['items'] ?? [];
                      final label =
                      String.fromCharCode(65 + index);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PackageRedeemPage(
                                bannerUrl: bannerUrl,
                                packageLabel: label,
                                rmValue: int.tryParse(value.replaceAll("RM ", "")) ?? 0,
                                validityDays: 30,
                                items: items,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          padding: EdgeInsets.all(10),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              bannerUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  bannerUrl,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Container(
                                height: 100,
                                color: Colors.grey[300],
                                child: Center(child: Icon(Icons.image, color: Colors.grey)),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Package $label:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA67C00),
                                ),
                              ),
                              ...List.generate(items.length, (i) {
                                final item = items[i];
                                return Text(
                                  "${i + 1}. ${item['name']} ${item['unit']}",
                                  style: TextStyle(color: Color(0xFF303030)),
                                  textAlign: TextAlign.center,
                                );
                              }),
                              SizedBox(height: 10),
                              Divider(
                                thickness: 0,
                                color: Colors.black,
                                indent: 10,
                                endIndent: 10,
                              ),
                              Text(
                                "Value $value",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA67C00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
