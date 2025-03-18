import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<String> packageItems = [];
  String? selectedPackageItem;
  TextEditingController packageItemController = TextEditingController();
  List<int> minRedeemablePointsOptions = [100, 200, 500, 800, 1000, 1250, 1500, 2000, 3000, 4000, 5000];
  int minRedeemablePointsIndex = 0;
  List<int> rmScalingOptions = [1, 2, 5, 10, 15, 20];
  int rmScalingIndex = 0;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
                          onTap: _pickImage,
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
                                // **Update existing Cash Voucher**
                                await vouchersRef.doc(existingVoucher.docs.first.id).update({
                                  "voucherValue": voucherValue ?? 0,
                                  "bannerVoucher": _selectedImage != null ? _selectedImage!.path : null,
                                  "updatedAt": Timestamp.now(),
                                });
                                print("🔥 Updated Cash Voucher");
                              } else {
                                // **Create Cash Voucher if none exist**
                                await vouchersRef.add({
                                  "typeVoucher": "Cash Voucher",
                                  "voucherValue": voucherValue ?? 0,
                                  "bannerVoucher": _selectedImage != null ? _selectedImage!.path : null,
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

                              if (voucherCount == 4) {
                                // **Update the 4 existing vouchers**
                                for (int i = 0; i < 4; i++) {
                                  await vouchersRef.doc(existingVouchers.docs[i].id).update({
                                    "points": pointsList[i],
                                    "valuePoints": valuesList[i],
                                    "updatedAt": Timestamp.now(),
                                  });
                                  print("✅ Updated: ${pointsList[i]} pts → RM${valuesList[i]}");
                                }
                              }
                              else if (voucherCount == 0) {
                                // **Create 4 new vouchers if none exist**
                                List<DocumentReference> createdDocs = [];
                                for (int i = 0; i < 4; i++) {
                                  DocumentReference newDoc = await vouchersRef.add({
                                    "typeVoucher": "Points",
                                    "points": pointsList[i],
                                    "valuePoints": valuesList[i],
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
                                for (int i = voucherCount; i < 4; i++) {
                                  DocumentReference newDoc = await vouchersRef.add({
                                    "typeVoucher": "Points",
                                    "points": pointsList[i],
                                    "valuePoints": valuesList[i],
                                    "createdAt": Timestamp.now(),
                                  });
                                  print("🔥 Created missing voucher: ${pointsList[i]} pts → RM${valuesList[i]}");
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
                        Text("Package Kasih Banner", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        GestureDetector(
                          onTap: _pickImage,
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
      body: Column(
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

          Expanded(
            child: Center(
              child: Text(
                isVoucherSelected ? "No vouchers here" : "No package kasih here",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
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
