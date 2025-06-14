import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages//payPackage.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({Key? key}) : super(key: key);

  @override
  _AmountPageState createState() => _AmountPageState();
}

class _AmountPageState extends State<PackagePage> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final Map<String, TextEditingController> _quantityControllers = {};
  int totalQuantity = 0;
  double  totalValue = 0.0;

  // Recomputes totals whenever a quantity field changes.
  void _updateTotals(List<QueryDocumentSnapshot> docs) {
    int sumQty = 0;
    double sumValue = 0.0;
    for (var doc in docs) {
      final id = doc.id;
      final packageValue = (doc['voucherValue'] as num?)?.toDouble() ?? 0.0;
      final qtyController = _quantityControllers[id];
      int qty = int.tryParse(qtyController?.text ?? "0") ?? 0;
      sumQty += qty;
      sumValue += qty * packageValue;
    }
    if (sumQty != totalQuantity || (sumValue - totalValue).abs() > 0.001) {
      setState(() {
        totalQuantity = sumQty;
        totalValue = sumValue; // Store the exact double value
      });
    }
  }

  @override
  void dispose() {
    _quantityControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      // CHANGED: Point stream to 'package_hamper' collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("package_hamper").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No package available", style: TextStyle(color: Colors.white)));
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          docs.sort((a, b) {
            double valueA = (a['voucherValue'] as num?)?.toDouble() ?? 0.0;
            double valueB = (b['voucherValue'] as num?)?.toDouble() ?? 0.0;
            return valueA.compareTo(valueB);
          });

          // Initialize quantity controllers if not already done.
          for (var doc in docs) {
            if (!_quantityControllers.containsKey(doc.id)) {
              _quantityControllers[doc.id] = TextEditingController(text: "0");
              _quantityControllers[doc.id]!.addListener(() {
                _updateTotals(docs);
              });
            }
          }

          return Stack(
            children: [
              // Main scrollable content with sticky header using CustomScrollView.
              CustomScrollView(
                slivers: [
                  // Sticky header – always visible at the top.
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(),
                  ),
                  // Main body content (column header row + package rows).
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                      const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Column header row: match your row flex ratios.
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  "Choice",
                                  style: TextStyle(
                                    color: const Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Quantity",
                                  style: TextStyle(
                                    color: const Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Value (RM)",
                                  style: TextStyle(
                                    color: const Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Build package rows.
                          Column(
                            children: docs.asMap().entries.map((entry) {
                              int index = entry.key;
                              QueryDocumentSnapshot doc = entry.value;
                              final data = doc.data() as Map<String, dynamic>;

                              // CHANGED: Use the 'name' field from the document for the label
                              final hamperName = data['name'] ?? 'Unnamed Hamper';
                              final bannerUrl = data['bannerUrl'] ?? "";
                              final packageValue = (data['voucherValue'] as num?)?.toDouble() ?? 0.0;
                              final items = data['items'] as List? ?? [];

                              // "Choice" box with a golden gradient.
                              Widget choiceWidget = Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
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
                                    Text(
                                      // CHANGED: Display the actual hamper name
                                      hamperName,
                                      style: const TextStyle(
                                        color: Color(0xFFA67C00),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    bannerUrl.toString().isNotEmpty
                                        ? Image.network(
                                      bannerUrl,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                        : Container(
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Center(
                                          child: Icon(Icons.image, color: Colors.grey)),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(items.length, (i) {
                                      final item = items[i];
                                      String itemName = item['name'] ?? "";
                                      // Logic to display item number is robust, no change needed
                                      String itemNumber = item.containsKey('number')
                                          ? item['number'].toString()
                                          : "";
                                      String itemUnit = item['unit'] ?? "";
                                      return Padding(
                                        padding:
                                        const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Text(
                                          "${i + 1}. $itemName ${itemNumber.isNotEmpty ? 'x$itemNumber' : ''} $itemUnit".trim(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );

                              // Editable quantity box.
                              Widget quantityWidget = Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D789),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _quantityControllers[doc.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFA67C00)),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "0",
                                  ),
                                ),
                              );

                              // Computed value (read-only) box.
                              int qty = int.tryParse(
                                  _quantityControllers[doc.id]?.text ?? "0") ??
                                  0;
                              double  computedValue = qty * packageValue;
                              Widget valueWidget = Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D789),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    computedValue.toStringAsFixed(2),
                                    style: const TextStyle(
                                        color: Color(0xFFA67C00), fontSize: 16),
                                  ),
                                ),
                              );

                              // Each row: Choice | Quantity | Value
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: choiceWidget),
                                  Expanded(flex: 1, child: quantityWidget),
                                  Expanded(flex: 1, child: valueWidget),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Footer overlay remains as before.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF303030),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Total:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "$totalQuantity",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Overall Amount (RM):",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    totalValue.toStringAsFixed(2),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // This navigation remains valid, no changes needed here.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PayPackage(
                                  totalQuantity: totalQuantity,
                                  overallAmount: totalValue,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFBF04),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Next",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1C1C1C),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Text(
        'Help Asnaf by Package',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFDB515),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  double get maxExtent => 150;

  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}