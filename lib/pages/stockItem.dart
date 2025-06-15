import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/localization/app_localizations.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/services/search_service.dart';

class StockItem extends StatefulWidget {
  @override
  _StockItemState createState() => _StockItemState();
}

class _StockItemState extends State<StockItem> with TickerProviderStateMixin {
  // UI State
  bool isPackageKasihSelected = true;
  int _selectedIndex = 0;

  // Shared Controllers & State
  TextEditingController itemNameController = TextEditingController();
  List<Map<String, dynamic>> itemSuggestions = [];
  String? selectedItemId;
  double selectedPrice = 0.0;
  String selectedCategory = "";

  // Package Hamper Specific State
  final TextEditingController hamperNameController = TextEditingController();
  List<Map<String, dynamic>> detailedHamperItems = [];
  int selectedHamperVoucherValue = 50; // Default value
  final List<int> hamperVoucherOptions = [50, 100, 150, 200, 250];

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
    hamperNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- LOADING OVERLAY ---
  void _showLoadingDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black54,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  loc.translate('stockItem_loading_dialog'),
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
  // --- Helper function for Warning Dialog ---
  Future<void> _showWarningDialog(String title, String message) async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF3F3F3F),
          title: Text(title, style: TextStyle(color: Color(0xFFFDB515))),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message, style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(loc.translate('stockItem_ok_button'), style: TextStyle(color: Color(0xFFFDB515), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- EDIT PACKAGE NAME DIALOG (Kasih)---
  Future<void> _editPackageName(DocumentSnapshot doc, String currentName) async {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController editController =
    TextEditingController(text: currentName);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF3F3F3F),
          title: Text(loc.translate('stockItem_edit_package_name_title'),
              style: TextStyle(color: Color(0xFFFDB515))),
          content: TextField(
            controller: editController,
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: loc.translate('stockItem_edit_package_name_hint'),
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
              child: Text(loc.translate('stockItem_cancel_button'), style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: Color(0xFFFDB515)),
              child: Text(loc.translate('stockItem_update_button'), style: TextStyle(color: Colors.black)),
              onPressed: () async {
                final String newName = editController.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  await doc.reference.update({'name': newName});
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- ADD PACKAGE KASIH (Single Item) ---
  void _addPackageKasih() {
    final loc = AppLocalizations.of(context)!;
    print("---EXECUTING _addPackageKasih FUNCTION---");
    itemNameController.clear();
    itemSuggestions = [];
    selectedPrice = 0.0;
    selectedCategory = "";

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
                          loc.translate('stockItem_add_kasih_title'),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDB515)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(loc.translate('stockItem_item_name_label'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1D789))),
                      SizedBox(height: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: itemNameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFFFCF40),
                              hintText: loc.translate('stockItem_search_hint'),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (pattern) async {
                              if (pattern.trim().isEmpty) {
                                setModalState(() => itemSuggestions = []);
                                return;
                              }
                              try {
                                final results =
                                await SearchService.searchItems(pattern);
                                setModalState(() => itemSuggestions = results);
                              } catch (e) {
                                setModalState(() => itemSuggestions = []);
                              }
                            },
                          ),
                          if (itemSuggestions.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: itemSuggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = itemSuggestions[index];
                                  return ListTile(
                                    title: Text(suggestion['item_name']),
                                    subtitle: Text(
                                        "RM ${suggestion['average_price'].toStringAsFixed(2)}"),
                                    onTap: () {
                                      setModalState(() {
                                        itemNameController.text =
                                        suggestion['item_name'];
                                        selectedPrice =
                                        suggestion['average_price'];
                                        selectedCategory =
                                            suggestion['item_category'] ?? "";
                                        itemSuggestions = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final String itemName = itemNameController.text.trim();
                          if (itemName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      loc.translate('stockItem_select_item_warning'))),
                            );
                            return;
                          }

                          _showLoadingDialog();

                          final singleItem = {
                            "name": itemName,
                            "price": selectedPrice,
                            "category": selectedCategory,
                            "number": 1,
                          };

                          try {
                            final bannerResponse = await http.post(
                              Uri.parse(
                                  "https://us-central1-kita-tongtong.cloudfunctions.net/generatePackageKasihImage"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "items": [singleItem]
                              }),
                            );

                            if (bannerResponse.statusCode != 200) {
                              throw Exception(
                                  "Image generation failed: ${bannerResponse.body}");
                            }

                            final bannerData = jsonDecode(bannerResponse.body);
                            final String bannerUrl = bannerData["image_url"];

                            await FirebaseFirestore.instance
                                .collection('package_kasih')
                                .add({
                              "price": selectedPrice,
                              "name": itemName,
                              "items": [singleItem], // Still store as a list
                              "bannerUrl": bannerUrl,
                              "createdAt": Timestamp.now(),
                            });

                            Navigator.pop(context); // Close the bottom sheet
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${loc.translate('stockItem_create_package_error')}${e.toString()}')),
                            );
                          } finally {
                            _hideLoadingDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(loc.translate('stockItem_submit_package_button'),
                            style:
                            TextStyle(fontSize: 16, color: Colors.black)),
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
  void _addPackageHamper() {
    final loc = AppLocalizations.of(context)!;
    hamperNameController.clear();
    itemNameController.clear();
    detailedHamperItems = [];
    itemSuggestions = [];
    selectedHamperVoucherValue = 50;

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
                          loc.translate('stockItem_add_hamper_title'),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDB515)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(loc.translate('stockItem_package_name_label'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1D789))),
                      SizedBox(height: 8),
                      TextField(
                        controller: hamperNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFFFCF40),
                          hintText: loc.translate('stockItem_hamper_name_hint'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(loc.translate('stockItem_voucher_value_label'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1D789))),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFFCF40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedHamperVoucherValue,
                            isExpanded: true,
                            dropdownColor: Color(0xFFFFCF40),
                            items: hamperVoucherOptions.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text("RM $value",
                                    style: TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setModalState(() {
                                if (newValue != null) {
                                  selectedHamperVoucherValue = newValue;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(loc.translate('stockItem_items_label'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF1D789))),
                      SizedBox(height: 8),
                      Column(
                        children: List.generate(detailedHamperItems.length,
                                (index) {
                              final item = detailedHamperItems[index];
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFCF40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                            "${item["name"]} (RM ${item["price"].toStringAsFixed(2)})",
                                            style:
                                            TextStyle(color: Colors.black))),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          detailedHamperItems.removeAt(index);
                                        });
                                      },
                                      child: Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ],
                                ),
                              );
                            }),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: itemNameController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFFFFCF40),
                                    hintText: loc.translate('stockItem_search_hint'),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (pattern) async {
                                    if (pattern.trim().isEmpty) {
                                      setModalState(
                                              () => itemSuggestions = []);
                                      return;
                                    }
                                    try {
                                      final results = await SearchService
                                          .searchItems(pattern);
                                      setModalState(
                                              () => itemSuggestions = results);
                                    } catch (e) {
                                      setModalState(
                                              () => itemSuggestions = []);
                                    }
                                  },
                                ),
                                if (itemSuggestions.isNotEmpty)
                                  Container(
                                    constraints:
                                    BoxConstraints(maxHeight: 150),
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius:
                                      BorderRadius.circular(16),
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
                                              "RM ${(suggestion['average_price'] as num).toStringAsFixed(2)}"),
                                          onTap: () {
                                            setModalState(() {
                                              itemNameController.text =
                                              suggestion['item_name']
                                              as String;
                                              itemSuggestions = [];
                                              selectedItemId =
                                              suggestion['id'] as String;
                                              selectedPrice = (suggestion[
                                              'average_price'] as num)
                                                  .toDouble();
                                              selectedCategory = suggestion[
                                              'item_group']
                                              as String? ??
                                                  "";
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              final name = itemNameController.text.trim();
                              if (name.isNotEmpty && selectedPrice > 0) {
                                setModalState(() {
                                  detailedHamperItems.add({
                                    "name": name,
                                    "price": selectedPrice,
                                    "category": selectedCategory,
                                    "number": 1,
                                  });
                                  itemNameController.clear();
                                  selectedPrice = 0.0;
                                  selectedCategory = "";
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final String hamperName =
                          hamperNameController.text.trim();
                          if (hamperName.isEmpty) {
                            _showWarningDialog(loc.translate('stockItem_warning_title_validation'), loc.translate('stockItem_hamper_name_warning'));
                            return;
                          }
                          if (detailedHamperItems.isEmpty) {
                            _showWarningDialog(loc.translate('stockItem_warning_title_validation'), loc.translate('stockItem_add_item_warning'));
                            return;
                          }

                          _showLoadingDialog();

                          try {
                            final priceResponse = await http.post(
                              Uri.parse(
                                  "https://us-central1-kita-tongtong.cloudfunctions.net/getPackagePrice"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"items": detailedHamperItems}),
                            ).timeout(const Duration(seconds: 90));

                            if (priceResponse.statusCode != 200) {
                              throw Exception(
                                  "Server price check failed. Status: ${priceResponse.statusCode}");
                            }

                            final responseData = jsonDecode(priceResponse.body);
                            final double serverSideTotalPrice =
                            (responseData['expectedTotal'] as num)
                                .toDouble();

                            final double voucherValue =
                            selectedHamperVoucherValue.toDouble();
                            final double maxAllowedPrice = voucherValue * 1.20;
                            final double minAllowedPrice = voucherValue * 0.80;

                            if (serverSideTotalPrice < minAllowedPrice) {
                              _hideLoadingDialog();
                              final double difference = minAllowedPrice - serverSideTotalPrice;
                              _showWarningDialog(loc.translate('stockItem_warning_title_failed'), loc.translateWithArgs('stockItem_price_low_warning', {'price': serverSideTotalPrice.toStringAsFixed(2), 'diff': difference.toStringAsFixed(2)}));
                              return;
                            }

                            if (serverSideTotalPrice > maxAllowedPrice) {
                              _hideLoadingDialog();
                              final double difference = serverSideTotalPrice - maxAllowedPrice;
                              _showWarningDialog(loc.translate('stockItem_warning_title_failed'), loc.translateWithArgs('stockItem_price_high_warning', {'price': serverSideTotalPrice.toStringAsFixed(2), 'diff': difference.toStringAsFixed(2)}));
                              return;
                            }

                            final bannerResponse = await http.post(
                              Uri.parse(
                                  "https://us-central1-kita-tongtong.cloudfunctions.net/generatePackageKasihImage"),
                              headers: {"Content-Type": "application/json"},
                              body:
                              jsonEncode({"items": detailedHamperItems}),
                            ).timeout(const Duration(seconds: 90));

                            if (bannerResponse.statusCode != 200) {
                              throw Exception(
                                  "Image generation failed. Status: ${bannerResponse.statusCode}");
                            }

                            final bannerData =
                            jsonDecode(bannerResponse.body);
                            final String bannerUrl = bannerData["image_url"];

                            await FirebaseFirestore.instance
                                .collection('package_hamper')
                                .add({
                              "name": hamperName,
                              "voucherValue": selectedHamperVoucherValue,
                              "totalPrice": serverSideTotalPrice,
                              "items": detailedHamperItems,
                              "bannerUrl": bannerUrl,
                              "createdAt": Timestamp.now(),
                            });

                            _hideLoadingDialog();
                            Navigator.pop(context); // Close the modal sheet

                            // Show success dialog on the main screen
                            _showWarningDialog(loc.translate('stockItem_warning_title_success'), "Package Hamper '$hamperName' has been successfully submitted.");

                          } catch (e) {
                            _hideLoadingDialog();
                            _showWarningDialog(loc.translate('stockItem_warning_title_error'), e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDB515),
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(loc.translate('stockItem_submit_hamper_button'),
                            style: TextStyle(
                                fontSize: 16, color: Colors.black)),
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Toggle Switch
            Padding(
              padding: const EdgeInsets.only(top: 70.0, left: 16, right: 16),
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
                        onTap: () =>
                            setState(() => isPackageKasihSelected = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isPackageKasihSelected
                                ? Colors.white
                                : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            loc.translate('stockItem_package_kasih'),
                            style: TextStyle(
                              color: isPackageKasihSelected
                                  ? Color(0xFFFDB515)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => isPackageKasihSelected = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isPackageKasihSelected
                                ? Colors.white
                                : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            loc.translate('stockItem_package_hamper'),
                            style: TextStyle(
                              color: !isPackageKasihSelected
                                  ? Color(0xFFFDB515)
                                  : Colors.white,
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

            // Conditional List View
            if (isPackageKasihSelected)
              buildPackageKasihList()
            else
              buildPackageHamperList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFDB515),
        child: Icon(Icons.add, color: Colors.black),
        onPressed:
        isPackageKasihSelected ? _addPackageKasih : _addPackageHamper,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // --- WIDGET BUILDER for Package Kasih List ---
  Widget buildPackageKasihList() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            loc.translate('stockItem_kasih_list_title'),
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
                    loc.translate('stockItem_no_packages_available'),
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
                  final title = (pkg['items'] as List<dynamic>? ?? []).isNotEmpty ? pkg['items'][0]['name'] ?? loc.translate('stockItem_unnamed_package') : loc.translate('stockItem_unnamed_package');
                  final items = pkg['items'] as List<dynamic>? ?? [];
                  final category = items.isNotEmpty
                      ? items.first['category'] ?? loc.translate('stockItem_no_category')
                      : loc.translate('stockItem_no_category');

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await doc.reference.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translateWithArgs('stockItem_package_deleted', {'title': title})),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
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
                          if (bannerUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                bannerUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Center(
                                  child: Icon(Icons.image, color: Colors.grey)),
                            ),
                          GestureDetector(
                            onTap: () => _editPackageName(doc, title),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 4.0),
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
                                  Icon(Icons.edit,
                                      size: 16, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            loc.translateWithArgs('stockItem_category_label', {'category': category}),
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            loc.translateWithArgs('stockItem_price_label', {'price': value.toStringAsFixed(2)}),
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
    );
  }

  // --- WIDGET BUILDER for Package Hamper List ---
  Widget buildPackageHamperList() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            loc.translate('stockItem_hamper_list_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("package_hamper")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    loc.translate('stockItem_no_hampers_available'),
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  final pkg = doc.data() as Map<String, dynamic>;
                  final bannerUrl = pkg["bannerUrl"] ?? "";
                  final title = pkg['name'] ?? loc.translate('stockItem_unnamed_hamper');
                  final voucherValue = pkg['voucherValue'] ?? 0;
                  final items = pkg['items'] as List<dynamic>? ?? [];

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await doc.reference.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translateWithArgs('stockItem_package_deleted', {'title': title})),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
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
                          if (bannerUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                bannerUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 100,
                              color: Colors.grey[300],
                              child: Center(
                                  child: Icon(Icons.image, color: Colors.grey)),
                            ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _editPackageName(doc, title),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 4.0),
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
                                  Icon(Icons.edit,
                                      size: 16, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${loc.translate('stockItem_items_label')}:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ...items.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    Map item = entry.value;
                                    return Text("${idx + 1}. ${item['name']}");
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            loc.translateWithArgs('stockItem_voucher_value_display', {'value': voucherValue.toString()}),
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
    );
  }
}
