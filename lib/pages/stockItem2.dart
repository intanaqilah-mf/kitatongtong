import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/services/price_service.dart';

import 'package:projects/services/search_service.dart';

class StockItem extends StatefulWidget {
  @override
  _StockItemState createState() => _StockItemState();
}

class _StockItemState extends State<StockItem> {
  bool isVoucherSelected = true;
  String selectedVoucherType = "Cash Voucher";
  String selectedValue = "RM 10";
  int? voucherValue;
  File? _selectedImage;
  String? _selectedImageUrl;
  List<String> packageItems = [];
  String? selectedPackageItem;
  TextEditingController packageItemController = TextEditingController();
  List<int> minRedeemablePointsOptions = [100, 200, 500, 800, 1000, 1250, 1500, 2000, 3000, 4000, 5000];
  int minRedeemablePointsIndex = 0;
  List<int> rmScalingOptions = [50, 100, 150, 200, 250];
  int rmScalingIndex = 0;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> detailedPackageItems = [];
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemNumberController = TextEditingController();
  String selectedCategory = "";
  List<Map<String, dynamic>> itemSuggestions = [];

  String? selectedItemId;    // Firestore document ID of the chosen item
  double selectedPrice = 0.0; // “average_price” from your price catcher

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickImage(Function setModalState) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setModalState(() { // ✅ Update UI inside modal
        _selectedImage = imageFile;
      });

      print("📸 Image selected: ${pickedFile.path}");

      // ✅ Upload image to Firebase Storage
      String fileName = isVoucherSelected
          ? "voucherBanner/${DateTime.now().millisecondsSinceEpoch}.jpg"
          : "package_kasih_banner/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // ✅ Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setModalState(() { // ✅ Update UI with Firebase URL
        _selectedImageUrl = downloadUrl; // Store Firebase URL
      });

      print("✅ Image uploaded to Firebase: $downloadUrl");
    } else {
      print("❌ No image selected");
    }
  }

  Future<String?> generateVoucherBannerImage(int points, int value) async {
    try {
      final url = Uri.parse("https://generatevoucherimage-m4nvbdigca-uc.a.run.app");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"points": points, "value": value}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['image_url'];
      } else {
        print("❌ Failed to generate image: ${response.body}");
      }
    } catch (e) {
      print("❌ Error calling function: $e");
    }
    return null;
  }

  Future<void> deleteOldVoucherImages(List<DocumentSnapshot> existingVouchers) async {
    final storage = FirebaseStorage.instance;

    for (var doc in existingVouchers) {
      final data = doc.data() as Map<String, dynamic>;
      final imageUrl = data['bannerVoucher'];

      if (imageUrl != null && imageUrl is String) {
        try {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
          print("Deleted old image: $imageUrl");
        } catch (e) {
          print("Failed to delete image $imageUrl: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    itemNumberController.dispose();
    packageItemController.dispose();
    super.dispose();
  }

  Future<double> fetchExpectedTotalRemote(
      List<Map<String, dynamic>> items) async {
    final resp = await http.post(
      Uri.parse("https://us-central1-kita-tongtong.cloudfunctions.net/getPackagePrice"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"items": items}),
    );
    final body = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw Exception(body["error"] ?? "Price lookup failed");
    }
    return (body["expectedTotal"] as num).toDouble();
  }

  void _showAddVoucherForm() {
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Add Voucher",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text("Type Voucher", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFFCF40), // ✅ Updated field box background color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedVoucherType,
                            isExpanded: true,
                            dropdownColor: Color(0xFFFFCF40), // ✅ Ensures dropdown matches field color
                            items: ["Cash Voucher", "Points"].map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: TextStyle(color: Colors.black)), // ✅ Ensures text is visible
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setModalState(() { // ✅ Use setModalState to update UI inside modal
                                selectedVoucherType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      if (selectedVoucherType == "Cash Voucher") ...[
                        Text("Voucher Value (RM)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFFFCF40),
                            border: OutlineInputBorder(),
                            hintText: "Enter voucher value",
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              voucherValue = int.tryParse(value);
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        Text("Voucher Banner", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        GestureDetector(
                          onTap: () async { // ✅ Fix: Make onTap an async function
                            await _pickImage(setModalState); // ✅ Calls function properly
                          },
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFCF40),
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              image: _selectedImageUrl != null
                                  ? DecorationImage(image: NetworkImage(_selectedImageUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _selectedImageUrl == null
                                ? Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                                : null,
                          ),
                        ),

                      ],

                      // If "Points" is selected
                      if (selectedVoucherType == "Points") ...[
                        Text("Minimum Redeemable Points", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Color(0xFFF1D789),
                            inactiveTrackColor: Color(0xFFF1D789),
                            thumbColor: Color(0xFFEFBF04),
                            overlayColor: Color(0xFFEFBF04).withOpacity(0.3),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: minRedeemablePointsIndex.toDouble(), // ✅ Use Index
                            min: 0,
                            max: (minRedeemablePointsOptions.length - 1).toDouble(),
                            divisions: minRedeemablePointsOptions.length - 1,
                            label: "${minRedeemablePointsOptions[minRedeemablePointsIndex]} points", // ✅ Corrected reference
                            onChanged: (value) {
                              setModalState(() {
                                minRedeemablePointsIndex = value.round();
                              });
                            },
                          ),
                        ),
                        Text("Scaling Factor (RM)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Color(0xFFF1D789),
                            inactiveTrackColor: Color(0xFFF1D789),
                            thumbColor: Color(0xFFEFBF04),
                            overlayColor: Color(0xFFEFBF04).withOpacity(0.3),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: rmScalingIndex.toDouble(), // ✅ Use Index
                            min: 0,
                            max: (rmScalingOptions.length - 1).toDouble(),
                            divisions: rmScalingOptions.length - 1,
                            label: "RM${rmScalingOptions[rmScalingIndex]}", // ✅ Corrected reference
                            onChanged: (value) {
                              setModalState(() {
                                rmScalingIndex = value.round();
                              });
                            },
                          ),
                        ),
                        Center(
                          child: Text(
                            "Auto-generated voucher redemption:\n"
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex]} pts → RM${rmScalingOptions[rmScalingIndex]}\n"
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex] * 2} pts → RM${rmScalingOptions[rmScalingIndex] * 2}\n"
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex] * 3} pts → RM${rmScalingOptions[rmScalingIndex] * 3}\n"
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex] * 4} pts → RM${rmScalingOptions[rmScalingIndex] * 4}\n"
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex] * 5} pts → RM${rmScalingOptions[rmScalingIndex] * 5}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                            textAlign: TextAlign.center, // ✅ Ensures text alignment is centered
                          ),
                        ),
                      ],

                      SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            CollectionReference vouchersRef = FirebaseFirestore.instance.collection("vouchers");

                            if (selectedVoucherType == "Cash Voucher") {
                              QuerySnapshot existingVoucher = await vouchersRef
                                  .where("typeVoucher", isEqualTo: "Cash Voucher")
                                  .limit(1)
                                  .get();

                              if (existingVoucher.docs.isNotEmpty) {
                                // ✅ Update Firestore with Firebase URL
                                await vouchersRef.doc(existingVoucher.docs.first.id).update({
                                  "voucherValue": voucherValue ?? 0,
                                  "bannerVoucher": _selectedImageUrl, // ✅ Store Firebase URL, NOT Local Path
                                  "updatedAt": Timestamp.now(),
                                });
                                print("🔥 Updated Cash Voucher");
                              } else {
                                // ✅ Create new Firestore entry with Firebase URL
                                await vouchersRef.add({
                                  "typeVoucher": "Cash Voucher",
                                  "voucherValue": voucherValue ?? 0,
                                  "bannerVoucher": _selectedImageUrl, // ✅ Store Firebase URL
                                  "createdAt": Timestamp.now(),
                                });
                                print("🔥 Created Cash Voucher");
                              }
                            }
                            else if (selectedVoucherType == "Points") {
                              // ✅ CORRECTION: Define 5 voucher levels
                              final int basePoints = minRedeemablePointsOptions[minRedeemablePointsIndex];
                              final int baseValue = rmScalingOptions[rmScalingIndex];

                              final List<int> pointsList = [
                                basePoints,
                                basePoints * 2,
                                basePoints * 3,
                                basePoints * 4,
                                basePoints * 5 // ✨ Added 5th level
                              ];
                              final List<int> valuesList = [
                                baseValue,
                                baseValue * 2,
                                baseValue * 3,
                                baseValue * 4,
                                baseValue * 5 // ✨ Added 5th level
                              ];

                              // Fetch all existing point vouchers
                              QuerySnapshot existingVouchers = await vouchersRef
                                  .where("typeVoucher", isEqualTo: "Points")
                                  .get();

                              int voucherCount = existingVouchers.docs.length;
                              await deleteOldVoucherImages(existingVouchers.docs); // Clean up old images first

                              // ✅ CORRECTION: The logic should now create/update 5 vouchers.
                              // We'll simplify by deleting all old point vouchers and creating 5 new ones.

                              // 1. Delete all existing "Points" vouchers to ensure a clean slate
                              for (var doc in existingVouchers.docs) {
                                await doc.reference.delete();
                              }
                              print("🗑️ Deleted all old point vouchers. Recreating...");

                              // 2. Create 5 new vouchers
                              for (int i = 0; i < 5; i++) { // ✨ Loop now runs 5 times
                                String? bannerUrl = await generateVoucherBannerImage(pointsList[i], valuesList[i]);

                                await vouchersRef.add({
                                  "typeVoucher": "Points",
                                  "points": pointsList[i],
                                  "valuePoints": valuesList[i],
                                  "bannerVoucher": bannerUrl ?? "",
                                  "createdAt": Timestamp.now(),
                                });
                                print("🔥 Created new: ${pointsList[i]} pts → RM${valuesList[i]}");
                              }
                            }

                            print("🎉 Firestore update complete!");
                            Navigator.pop(context);
                          } catch (e) {
                            print("❌ Firestore ERROR: $e");
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Center(child: Text("Submit", style: TextStyle(fontSize: 16, color: Colors.black))),
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text("Item Name", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                      Column(
                        children: List.generate(detailedPackageItems.length, (index) {
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
                                Expanded(child: Text(item["name"], style: TextStyle(color: Colors.black))),
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
                          // ────────────────────────────────────────────────────────────────────────
                          // 1) The “Item Name + suggestions” column (unchanged)
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Your existing TextField for itemNameController:
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
                                      final results = await SearchService.searchItems(pattern);
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
                                // If there are suggestions, show them:
                                if (itemSuggestions.isNotEmpty)
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 200),
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
                                        final suggestion = itemSuggestions[index];
                                        return ListTile(
                                          title: Text(suggestion['item_name'] as String),
                                          subtitle: Text(
                                            "RM ${(suggestion['average_price'] as num).toStringAsFixed(2)}",
                                          ),
                                          onTap: () {
                                            setModalState(() {
                                              itemNameController.text = suggestion['item_name'] as String;
                                              itemSuggestions = [];
                                              selectedItemId = suggestion['id'] as String;
                                              selectedPrice = (suggestion['average_price'] as num).toDouble();
                                              selectedCategory        = suggestion['item_group'] as String? ?? "";
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
                              final int qty  = 1;

                              setModalState(() {
                                detailedPackageItems.add({
                                  "name": name,
                                  "price": selectedPrice,          // <— include price
                                  "category": selectedCategory,
                                  "number": qty,
                                });

                                // Clear for the next entry:
                                itemNameController.clear();
                              });
                            },
                          ),

                        ],
                      ),

                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // 1) If no items have been added, warn and return:
                          if (detailedPackageItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please add at least one item to the package first.")),
                            );
                            return;
                          }

                          try {
                            double totalPrice = 0.0;
                            for (var item in detailedPackageItems) {
                              final double p = (item["price"] as num).toDouble();
                              final int qty = item["number"] as int;
                              totalPrice += p * qty;
                            }
                            final priceResponse = await http.post(
                              Uri.parse("https://us-central1-kita-tongtong.cloudfunctions.net/getPackagePrice"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"items": detailedPackageItems}),
                            );
                            if (priceResponse.statusCode != 200) {
                              throw Exception("getPackagePrice failed: ${priceResponse.body}");
                            }
                            final priceData = jsonDecode(priceResponse.body) as Map<String, dynamic>;
                            final double expectedTotal = (priceData["expectedTotal"] as num).toDouble();
                            final bannerResponse = await http.post(
                              Uri.parse("https://us-central1-kita-tongtong.cloudfunctions.net/generatePackageKasihImage"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"items": detailedPackageItems}),
                            );
                            if (bannerResponse.statusCode != 200) {
                              throw Exception("generatePackageKasihImage failed: ${bannerResponse.body}");
                            }
                            final bannerData = jsonDecode(bannerResponse.body) as Map<String, dynamic>;
                            final String bannerUrl = bannerData["image_url"] as String;

                            // 5) Finally, write the “package” document exactly as before:
                            final packagesRef = FirebaseFirestore.instance.collection('package_kasih');
                            await packagesRef.add({
                              "price": totalPrice,
                              "items": detailedPackageItems
                                  .map((item) => {
                                "name": item["name"],
                                // Add price & category so your UI can show it if needed:
                                "price": item["price"],
                                "category": item["category"],
                              })
                                  .toList(),
                              "bannerUrl": bannerUrl,
                              "createdAt": Timestamp.now(),
                            });

                            // 6) Close the bottom sheet and return to the list
                            Navigator.pop(context);
                          } catch (e) {
                            print("❌ ERROR inserting package: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creating package: ${e.toString()}')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Center(
                          child: Text("Submit Package",
                              style: TextStyle(fontSize: 16, color: Colors.black)),
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
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isVoucherSelected = true;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isVoucherSelected ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Vouchers",
                            style: TextStyle(
                              color: isVoucherSelected ? Color(0xFFFDB515) : Colors.white,
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
                            isVoucherSelected = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isVoucherSelected ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Package Kasih",
                            style: TextStyle(
                              color: !isVoucherSelected ? Color(0xFFFDB515) : Colors.white,
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
            if (isVoucherSelected)
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
                      "Vouchers",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("vouchers").snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              "No vouchers here",
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            Map<String, dynamic> voucher = doc.data() as Map<String, dynamic>;
                            String bannerUrl = voucher["bannerVoucher"] ?? "";
                            String valueText = voucher.containsKey("voucherValue")
                                ? "Value RM ${voucher["voucherValue"]}"
                                : "Value RM ${voucher["valuePoints"]}";

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.transparent, // ✅ Transparent Box
                                border: Border.all(color: Colors.black), // ✅ Black Border
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ Voucher Image
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
                                      child: Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    valueText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (!isVoucherSelected)
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
                      stream: FirebaseFirestore.instance.collection("package_kasih").snapshots(),
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
                        docs.sort((a, b) {
                          // Treat doc.data() as a Map; check whether it contains "price" first
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;

                          // --- Compute rawA safely ---
                          double rawA = 0.0;
                          if (dataA.containsKey('price')) {
                            final dynamic vA = dataA['price'];
                            if (vA is String) {
                              rawA = double.tryParse(vA.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                            } else if (vA is num) {
                              rawA = vA.toDouble();
                            } else {
                              rawA = 0.0;
                            }
                          }

                          // --- Compute rawB safely (same pattern) ---
                          double rawB = 0.0;
                          if (dataB.containsKey('price')) {
                            final dynamic vB = dataB['price'];
                            if (vB is String) {
                              rawB = double.tryParse(vB.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                            } else if (vB is num) {
                              rawB = vB.toDouble();
                            } else {
                              rawB = 0.0;
                            }
                          }

                          return rawA.compareTo(rawB);
                        });


                        return Column(
                          children: docs.asMap().entries.map((entry) {
                            final index = entry.key;
                            final doc = entry.value;
                            final pkg = doc.data() as Map<String, dynamic>;
                            final bannerUrl = pkg["bannerUrl"] ?? "";
                            final value = pkg["price"] ?? "RM 0";
                            final label = String.fromCharCode(65 + index); // A, B, C, ...

                            return Container(
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
                                      child: Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                  Text(
                                    "Package $label:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFA67C00),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 5),
                                  if (pkg["items"] != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: (pkg["items"] as List<dynamic>)
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final i = entry.key;
                                        final item = entry.value as Map<String, dynamic>;
                                        final String name = item['name'] as String? ?? "";
                                        final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                                        final String category = item['category'] as String? ?? "";
                                        return Column(
                                          children: [
                                            Text(
                                              "    Category: $category",
                                              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic, fontSize: 12),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 4),
                                          ],
                                        );
                                      }).toList(),
                                    ),

                                  SizedBox(height: 10),
                                  Text(
                                    "Price: RM $value",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
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

      // ✅ Calls different functions for each section
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFDB515),
        child: Icon(Icons.add, color: Colors.black),
        onPressed: isVoucherSelected ? _showAddVoucherForm : _AddPackageKasih, // ✅ Uses different functions
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

}
