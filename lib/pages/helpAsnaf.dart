import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/amount.dart';
import 'package:projects/pages/package.dart';
import 'package:projects/pages/food_item_bank.dart';
import 'package:projects/localization/app_localizations.dart';

class HelpAsnaf extends StatefulWidget {
  @override
  _HelpAsnafState createState() =>
      _HelpAsnafState();
}
class _HelpAsnafState extends State<HelpAsnaf> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).translate('help_asnaf_by'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDB515),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AmountPage()));
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              AppLocalizations.of(context).translate('help_asnaf_amount'),
                              style: const TextStyle(
                                color: Color(0xFFA67C00),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Image.asset(
                            'assets/money.png',
                            height: 100,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).translate('help_asnaf_amount_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PackagePage()));
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              AppLocalizations.of(context).translate('help_asnaf_package'),
                              style: const TextStyle(
                                color: Color(0xFFA67C00),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Image.asset(
                            'assets/package.png',
                            height: 100,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).translate('help_asnaf_package_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FoodItemBank()));
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              AppLocalizations.of(context).translate('help_asnaf_item_bank'),
                              style: const TextStyle(
                                color: Color(0xFFA67C00),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Image.asset(
                            'assets/itemBank.png',
                            height: 100,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).translate('help_asnaf_item_bank_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}