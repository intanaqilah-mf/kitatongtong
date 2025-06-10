import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/services/search_service.dart';

class StockItem extends StatefulWidget {
  @override
  _StockItemState createState() => _StockItemState();
}

class _StockItemState extends State<StockItem> with TickerProviderStateMixin {
  File? _selectedImage;
  String? _selectedImageUrl;
  List<String> packageItems = [];
  String? selectedPackageItem;
  TextEditingController packageItemController = TextEditingController();
  int _selectedIndex = 0;
  List<Map<String, dynamic>> detailedPackageItems = [];
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();
  String selectedCategory = "";
  List<Map<String, dynamic>> itemSuggestions = [];

  String? selectedItemId; // Firestore document ID of the chosen item
  double selectedPrice = 0.0; // “average_price” from your price catcher

  // Animation Controller for the loading indicator
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Color palette for the loading indicator animation
    _colorAnimation = _animationController.drive(
      ColorTween(
        begin: Color(0xFFF9F295),
        end: Color(0xFFB88A44),
      ),
    );

    _animationController.repeat(reverse: true);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    itemNameController.dispose();
    itemNumberController.dispose();
    packageItemController.dispose();
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  // --- LOADING OVERLAY ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: _colorAnimation,
                        strokeWidth: 6,
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                Text(
                  "Submitting Package...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // --- EDIT PACKAGE NAME DIALOG ---
  Future<void> _editPackageName(DocumentSnapshot doc) async {
    final Map<String, dynamic> pkg = doc.data() as Map<String, dynamic>;
    final List<dynamic> items = pkg['items'] as List<dynamic>? ?? [];

    if (items.isEmpty) return; // Cannot edit if there are no items

    final String currentName = items.first['name'] as String? ?? '';
    final TextEditingController editController = TextEditingController(text: currentName);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF3F3F3F),
          title: Text('Edit Package Name', style: TextStyle(color: Color(0xFFFDB515))),
          content: TextField(
            controller: editController,
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new package name",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFDB515)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFDB515)),
              child: Text('Update', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                final String newName = editController.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  // Create a new list with the updated name
                  List<Map<String, dynamic>> updatedItems = List<Map<String, dynamic>>.from(items.map((item) => Map<String, dynamic>.from(item)));
                  updatedItems[0]['name'] = newName;

                  // Update the document in Firestore
                  await doc.reference.update({'items': updatedItems});
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<double> fetchExpectedTotalRemote(
      List<Map<String, dynamic>> items) async {
    final resp = await http.post(
      Uri.parse(
          "https://us-central1-kita-tongtong.cloudfunctions.net/getPackagePrice"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"items": items}),
    );
    final body = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw Exception(body["error"] ?? "Price lookup failed");
    }
    return (body["expectedTotal"] as num).toDouble();
  }

  void _AddPackageKasih() {
    TextEditingController itemNameController = TextEditingController();

    List<Map<String, dynamic>> detailedPackageItems = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF3F3F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Add Package Kasih",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDB515)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text("Item Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1D789))),
                      Column(
                        children:
                        List.generate(detailedPackageItems.length, (index) {
                          final item = detailedPackageItems[index];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFCF40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(item["name"],
                                        style: TextStyle(color: Colors.black))),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      detailedPackageItems.removeAt(index);
                                    });
                                  },
                                  child: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: itemNameController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFFFFCF40),
                                    hintText: "Type to search item…",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (pattern) async {
                                    if (pattern.trim().isEmpty) {
                                      setModalState(() {
                                        itemSuggestions = [];
                                      });
                                      return;
                                    }
                                    try {
                                      final results =
                                      await SearchService.searchItems(
                                          pattern);
                                      setModalState(() {
                                        itemSuggestions = results;
                                      });
                                    } catch (e) {
                                      print("Error in searchItems: $e");
                                      setModalState(() {
                                        itemSuggestions = [];
                                      });
                                    }
                                  },
                                ),
                                if (itemSuggestions.isNotEmpty)
                                  Container(
                                    constraints:
                                    BoxConstraints(maxHeight: 200),
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: itemSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion =
                                        itemSuggestions[index];
                                        return ListTile(
                                          title: Text(suggestion['item_name']
                                          as String),
                                          subtitle: Text(
                                            "RM ${(suggestion['average_price'] as num).toStringAsFixed(2)}",
                                          ),
                                          onTap: () {
                                            setModalState(() {
                                              itemNameController.text =
                                              suggestion['item_name']
                                              as String;
                                              itemSuggestions = [];
                                              selectedItemId =
                                              suggestion['id'] as String;
                                              selectedPrice =
                                                  (suggestion['average_price']
                                                  as num)
                                                      .toDouble();
                                              selectedCategory =
                                                  suggestion['item_group']
                                                  as String? ??
                                                      "";
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),

                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              final name = itemNameController.text.trim();
                              final int qty = 1;

                              setModalState(() {
                                detailedPackageItems.add({
                                  "name": name,
                                  "price": selectedPrice,
                                  "category": selectedCategory,
                                  "number": qty,
                                });

                                itemNameController.clear();
                              });
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (detailedPackageItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Please add at least one item to the package first.")),
                            );
                            return;
                          }

                          _showLoadingDialog(); // Show loading overlay

                          try {
                            double totalPrice = 0.0;
                            for (var item in detailedPackageItems) {
                              final double p =
                              (item["price"] as num).toDouble();
                              final int qty = item["number"] as int;
                              totalPrice += p * qty;
                            }
                            final priceResponse = await http.post(
                              Uri.parse(
                                  "https://us-central1-kita-tongtong.cloudfunctions.net/getPackagePrice"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"items": detailedPackageItems}),
                            );
                            if (priceResponse.statusCode != 200) {
                              throw Exception(
                                  "getPackagePrice failed: ${priceResponse.body}");
                            }
                            final priceData = jsonDecode(priceResponse.body)
                            as Map<String, dynamic>;
                            final double expectedTotal =
                            (priceData["expectedTotal"] as num).toDouble();
                            final bannerResponse = await http.post(
                              Uri.parse(
                                  "https://us-central1-kita-tongtong.cloudfunctions.net/generatePackageKasihImage"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"items": detailedPackageItems}),
                            );
                            if (bannerResponse.statusCode != 200) {
                              throw Exception(
                                  "generatePackageKasihImage failed: ${bannerResponse.body}");
                            }
                            final bannerData = jsonDecode(bannerResponse.body)
                            as Map<String, dynamic>;
                            final String bannerUrl =
                            bannerData["image_url"] as String;

                            final packagesRef = FirebaseFirestore.instance
                                .collection('package_kasih');
                            await packagesRef.add({
                              "price": totalPrice,
                              "items": detailedPackageItems
                                  .map((item) => {
                                "name": item["name"],
                                "price": item["price"],
                                "category": item["category"],
                              })
                                  .toList(),
                              "bannerUrl": bannerUrl,
                              "createdAt": Timestamp.now(),
                            });

                            Navigator.pop(context); // Close the bottom sheet
                          } catch (e) {
                            print("❌ ERROR inserting package: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Error creating package: ${e.toString()}')),
                            );
                          } finally {
                            _hideLoadingDialog(); // Hide loading overlay
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child: Center(
                          child: Text("Submit Package",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 70, left: 16, right: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFFDB515),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Package Kasih",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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
                  Text(
                    "Package Kasih",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("package_kasih")
                        .orderBy("price", descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No Package Kasih available",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return Column(
                        children: docs.map((doc) {
                          final pkg = doc.data() as Map<String, dynamic>;
                          final bannerUrl = pkg["bannerUrl"] ?? "";
                          final value = pkg["price"] ?? 0.0;

                          final items = pkg['items'] as List<dynamic>? ?? [];
                          final String title = items.isNotEmpty ? items.first['name'] as String? ?? 'Unnamed Package' : 'Unnamed Package';
                          final String category = items.isNotEmpty ? items.first['category'] as String? ?? 'No Category' : 'No Category';

                          // --- SWIPE-TO-DELETE IMPLEMENTED ---
                          return Dismissible(
                            key: Key(doc.id), // Unique key for each item
                            direction: DismissDirection.endToStart, // Swipe left
                            onDismissed: (direction) async {
                              // Delete from Firestore
                              await doc.reference.delete();

                              // Show confirmation SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"$title" has been deleted.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            // Background shown during swipe
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            // The actual card content
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
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
                                    child: Center(
                                      child: Icon(Icons.image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _editPackageName(doc),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.edit, size: 16, color: Colors.black54),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Category: $category",
                                    style: TextStyle(
                                        color: Colors.grey[800],
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Price: RM ${value.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFDB515),
        child: Icon(Icons.add, color: Colors.black),
        onPressed: _AddPackageKasih,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}