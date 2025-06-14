import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/payPackage.dart';
import 'package:projects/localization/app_localizations.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({Key? key}) : super(key: key);

  @override
  _PackagePageState createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Map<String, TextEditingController> _quantityControllers = {};
  int totalQuantity = 0;
  double totalValue = 0.0;

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
        totalValue = sumValue;
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
      body: StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance.collection("package_hamper").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
                    AppLocalizations.of(context)
                        .translate('package_no_packages'),
                    style: const TextStyle(color: Colors.white)));
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          docs.sort((a, b) {
            double valueA = (a['voucherValue'] as num?)?.toDouble() ?? 0.0;
            double valueB = (b['voucherValue'] as num?)?.toDouble() ?? 0.0;
            return valueA.compareTo(valueB);
          });

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
              CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 12, left: 16, right: 16, bottom: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('package_choice'),
                                  style: const TextStyle(
                                    color: Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('package_quantity'),
                                  style: const TextStyle(
                                    color: Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('package_value'),
                                  style: const TextStyle(
                                    color: Color(0xFFF1D789),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: docs.asMap().entries.map((entry) {
                              int index = entry.key;
                              QueryDocumentSnapshot doc = entry.value;
                              final data = doc.data() as Map<String, dynamic>;

                              final hamperName =
                                  data['name'] ?? 'Unnamed Hamper';
                              final bannerUrl = data['bannerUrl'] ?? "";
                              final packageValue =
                                  (data['voucherValue'] as num?)?.toDouble() ??
                                      0.0;
                              final items = data['items'] as List? ?? [];

                              Widget choiceWidget = Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
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
                                          child: Icon(Icons.image,
                                              color: Colors.grey)),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(items.length, (i) {
                                      final item = items[i];
                                      String itemName = item['name'] ?? "";
                                      String itemNumber =
                                      item.containsKey('number')
                                          ? item['number'].toString()
                                          : "";
                                      String itemUnit = item['unit'] ?? "";
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0),
                                        child: Text(
                                          "${i + 1}. $itemName ${itemNumber.isNotEmpty ? 'x$itemNumber' : ''} $itemUnit"
                                              .trim(),
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

                              Widget quantityWidget = Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1D789),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _quantityControllers[doc.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  textAlign: TextAlign.center,
                                  style:
                                  const TextStyle(color: Color(0xFFA67C00)),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "0",
                                  ),
                                ),
                              );

                              int qty = int.tryParse(_quantityControllers[
                              doc.id]
                                  ?.text ??
                                  "0") ??
                                  0;
                              double computedValue = qty * packageValue;
                              Widget valueWidget = Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
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
                                  AppLocalizations.of(context)
                                      .translate('package_total'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "$totalQuantity",
                                  style: const TextStyle(
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
                                    AppLocalizations.of(context)
                                        .translate('package_overall_amount'),
                                    style:
                                    const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    totalValue.toStringAsFixed(2),
                                    style:
                                    const TextStyle(color: Colors.white),
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
                          child: Text(
                            AppLocalizations.of(context).translate('next'),
                            style: const TextStyle(
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1C1C1C),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        AppLocalizations.of(context).translate('package_page_title'),
        style: const TextStyle(
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
