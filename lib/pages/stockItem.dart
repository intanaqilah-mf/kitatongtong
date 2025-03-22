import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<int> rmScalingOptions = [1, 2, 5, 10, 15, 20];
  int rmScalingIndex = 0;

  Future<void> _pickImage(Function setModalState) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setModalState(() { // ✅ Update UI inside modal
        _selectedImage = imageFile;
      });

      print("📸 Image selected: ${pickedFile.path}");

      // ✅ Upload image to Firebase Storage
      String fileName = "voucherBanner/${DateTime.now().millisecondsSinceEpoch}.jpg";
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
                                "${minRedeemablePointsOptions[minRedeemablePointsIndex] * 4} pts → RM${rmScalingOptions[rmScalingIndex] * 4}",
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
                              // Define the 4 voucher levels dynamically
                              List<int> pointsList = [
                                minRedeemablePointsOptions[minRedeemablePointsIndex],
                                minRedeemablePointsOptions[minRedeemablePointsIndex] * 2,
                                minRedeemablePointsOptions[minRedeemablePointsIndex] * 3,
                                minRedeemablePointsOptions[minRedeemablePointsIndex] * 4
                              ];
                              List<int> valuesList = [
                                rmScalingOptions[rmScalingIndex],
                                rmScalingOptions[rmScalingIndex] * 2,
                                rmScalingOptions[rmScalingIndex] * 3,
                                rmScalingOptions[rmScalingIndex] * 4
                              ];

                              // Fetch all existing point vouchers
                              QuerySnapshot existingVouchers = await vouchersRef
                                  .where("typeVoucher", isEqualTo: "Points")
                                  .get();

                              int voucherCount = existingVouchers.docs.length;
                              // Get existing vouchers of type "Points"
                              final existingPointsVouchers = await FirebaseFirestore.instance
                                  .collection('vouchers')
                                  .where('typeVoucher', isEqualTo: 'Points')
                                  .get();
                              await deleteOldVoucherImages(existingPointsVouchers.docs);


                              if (voucherCount == 4) {
                                // **Update the 4 existing vouchers**
                                for (int i = 0; i < 4; i++) {
                                  String? bannerUrl = await generateVoucherBannerImage(pointsList[i], valuesList[i]);

                                  String? oldBannerUrl = existingVouchers.docs[i]["bannerVoucher"];
                                  if (oldBannerUrl != null && oldBannerUrl.isNotEmpty) {
                                    try {
                                      final oldRef = FirebaseStorage.instance.refFromURL(oldBannerUrl);
                                      await oldRef.delete();
                                      print("🗑️ Deleted old banner: $oldBannerUrl");
                                    } catch (e) {
                                      print("⚠️ Failed to delete old banner: $e");
                                    }
                                  }
                                  await vouchersRef.doc(existingVouchers.docs[i].id).update({
                                    "points": pointsList[i],
                                    "valuePoints": valuesList[i],
                                    "bannerVoucher": bannerUrl ?? "",
                                    "updatedAt": Timestamp.now(),
                                  });
                                  print("✅ Updated: ${pointsList[i]} pts → RM${valuesList[i]}");
                                }
                              }
                              else if (voucherCount == 0) {
                                // **Create 4 new vouchers if none exist**
                                List<DocumentReference> createdDocs = [];
                                for (int i = 0; i < 4; i++) {
                                  String? bannerUrl = await generateVoucherBannerImage(pointsList[i], valuesList[i]);

                                  DocumentReference newDoc = await vouchersRef.add({
                                    "typeVoucher": "Points",
                                    "points": pointsList[i],
                                    "valuePoints": valuesList[i],
                                    "bannerVoucher": bannerUrl ?? "", // 🔥 Save generated banner
                                    "createdAt": Timestamp.now(),
                                  });
                                  createdDocs.add(newDoc);
                                  print("🔥 Created new: ${pointsList[i]} pts → RM${valuesList[i]}");
                                }

                                print("🎉 Successfully created 4 vouchers: ${createdDocs.map((doc) => doc.id).toList()}");
                              }
                              else {
                                // **If vouchers exist but not 0 or 4, force fix Firestore**
                                print("❌ ERROR: Expected 4 vouchers, but found $voucherCount. Fixing Firestore...");

                                // Delete extra vouchers if more than 4
                                if (voucherCount > 4) {
                                  for (int i = 4; i < voucherCount; i++) {
                                    await vouchersRef.doc(existingVouchers.docs[i].id).delete();
                                    print("🗑 Deleted extra voucher ID: ${existingVouchers.docs[i].id}");
                                  }
                                }

                                // If fewer than 4, create missing ones
                                for (int i = 0; i < 4; i++) {
                                  String? bannerUrl = await generateVoucherBannerImage(pointsList[i], valuesList[i]);

                                  if (bannerUrl != null) {
                                    await vouchersRef.doc(existingVouchers.docs[i].id).update({
                                      "points": pointsList[i],
                                      "valuePoints": valuesList[i],
                                      "bannerVoucher": bannerUrl,
                                      "updatedAt": Timestamp.now(),
                                    });
                                    print("✅ Updated with AI banner: ${pointsList[i]} pts → RM${valuesList[i]}");
                                  } else {
                                    print("❌ Failed to generate image for: ${pointsList[i]} pts");
                                  }
                                }
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
                      Text("Value Package Kasih", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFFCF40), // ✅ Updated field box background color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedValue,
                            isExpanded: true,
                            dropdownColor: Color(0xFFFFCF40), // ✅ Ensures dropdown matches field color
                            items: ["RM 10", "RM 20", "RM 30", "RM 40", "RM 50"].map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: TextStyle(color: Colors.black)), // ✅ Ensures text is visible
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setModalState(() { // ✅ Use setModalState to update UI inside modal
                                selectedValue = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      if (selectedValue == "RM 10" || selectedValue == "RM 20" || selectedValue == "RM 30") ...[
                        // Editable Multiple-Choice List (Google Forms Style)
                        Text("Package Item", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        Column(
                          children: List.generate(packageItems.length, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFCF40), // ✅ Box filled with required color
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Radio(
                                    value: packageItems[index],
                                    groupValue: selectedPackageItem,
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedPackageItem = value.toString();
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(packageItems[index], style: TextStyle(color: Colors.black)),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        packageItems.removeAt(index);
                                      });
                                    },
                                    child: Image.asset(
                                      'assets/trash.png', // ✅ Custom delete icon (replace with actual path)
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: packageItemController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFFFCF40),
                            border: OutlineInputBorder(),
                            hintText: "Add option",
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add, color: Colors.black),
                              onPressed: () {
                                if (packageItemController.text.trim().isNotEmpty) {
                                  setModalState(() {
                                    packageItems.add(packageItemController.text.trim());
                                    packageItemController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 16),
                        SizedBox(height: 16),
                        Text("Package Kasih Banner", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
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
                              image: _selectedImage != null
                                  ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _selectedImage == null
                                ? Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                                : null,
                          ),
                        ),
                      ],

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
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

                                // ✅ Voucher Value
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
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "No package kasih here",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
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
    );
  }

}
