import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class StockItem extends StatefulWidget {
  @override
  _StockItemState createState() => _StockItemState();
}

class _StockItemState extends State<StockItem> {
  bool isVoucherSelected = true;
  String selectedVoucherType = "Cash Voucher";
  int? voucherValue;
  DateTime? validityDate;
  File? _selectedImage;
  int minRedeemablePoints = 500; // Default minimum points for redeemable voucher
  double multiplier = 2.0; // Default geometric progression multiplier

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

                        // Validity Date
                        Text("Validity Date", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        GestureDetector(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setModalState(() {
                                validityDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                            color: Color(0xFFFFCF40),
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              validityDate == null
                                  ? "Select Validity Date"
                                  : DateFormat('dd MMM yyyy').format(validityDate!),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Upload Voucher Banner
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
                            activeTrackColor: Color(0xFFF1D789), // ✅ Updated slider line color
                            inactiveTrackColor: Color(0xFFF1D789), // ✅ Updated slider line color
                            thumbColor: Color(0xFFEFBF04), // ✅ Updated slider dot (cursor) color
                            overlayColor: Color(0xFFEFBF04).withOpacity(0.3),
                            trackHeight: 4.0, // Adjust thickness if needed
                          ),
                          child: Slider(
                            value: minRedeemablePoints.toDouble(),
                            min: 500,
                            max: 5000,
                            divisions: 9,
                            label: "$minRedeemablePoints points",
                            onChanged: (value) {
                              setModalState(() {
                                minRedeemablePoints = value.round();
                              });
                            },
                          ),
                        ),

                        // Geometric Progression Slider
                        Text("Geometric Scaling Factor", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1D789))),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Color(0xFFF1D789), // ✅ Updated slider line color
                            inactiveTrackColor: Color(0xFFF1D789), // ✅ Updated slider line color
                            thumbColor: Color(0xFFEFBF04), // ✅ Updated slider dot (cursor) color
                            overlayColor: Color(0xFFEFBF04).withOpacity(0.3),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: multiplier,
                            min: 2,
                            max: 5,
                            divisions: 3,
                            label: "x$multiplier",
                            onChanged: (value) {
                              setModalState(() {
                                multiplier = value;
                              });
                            },
                          ),
                        ),
                        Center(
                          child: Text(
                            "Auto-generated voucher redemption:\n"
                                "${minRedeemablePoints} pts → RM1\n"
                                "${(minRedeemablePoints * multiplier).round()} pts → RM2\n"
                                "${(minRedeemablePoints * multiplier * multiplier).round()} pts → RM4\n"
                                "${(minRedeemablePoints * multiplier * multiplier * multiplier).round()} pts → RM8\n",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                            textAlign: TextAlign.center, // ✅ Ensures text alignment is centered
                          ),
                        ),
                      ],

                      SizedBox(height: 20),

                      // Submit Button
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

      floatingActionButton: isVoucherSelected
          ? FloatingActionButton(
        backgroundColor: Color(0xFFFDB515),
        child: Icon(Icons.add, color: Colors.black),
        onPressed: _showAddVoucherForm,
      )
          : null,
    );
  }
}
