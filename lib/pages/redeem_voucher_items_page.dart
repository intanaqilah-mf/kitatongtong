import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successRedeem.dart'; // Assuming this page exists
import 'package:projects/widgets/bottomNavBar.dart'; // Assuming this exists
import 'dart:math';

class RedeemVoucherWithItemsPage extends StatefulWidget {
  final double voucherValue; // e.g., 40.00
  final Map<String, dynamic> voucherReceived; // To know which voucher to mark as used

  const RedeemVoucherWithItemsPage({
    Key? key,
    required this.voucherValue,
    required this.voucherReceived,
  }) : super(key: key);

  @override
  _RedeemVoucherWithItemsPageState createState() =>
      _RedeemVoucherWithItemsPageState();
}

class _RedeemVoucherWithItemsPageState
    extends State<RedeemVoucherWithItemsPage> {
  int _selectedIndex = 0; // For BottomNavBar

  List<Map<String, dynamic>> _allKasihItems = [];
  List<Map<String, dynamic>> _displayItems = [];
  List<Map<String, dynamic>> _cart = [];
  double _remainingBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _remainingBalance = widget.voucherValue;
    _fetchKasihItems();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic for bottom nav bar if needed
  }

  Future<void> _fetchKasihItems() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot packageSnapshot =
      await FirebaseFirestore.instance.collection('package_kasih').get();

      List<Map<String, dynamic>> allItems = [];
      for (var doc in packageSnapshot.docs) {
        final packageData = doc.data() as Map<String, dynamic>;
        if (packageData.containsKey('items') && packageData['items'] is List) {
          List<dynamic> packageItems = packageData['items'];
          for (var itemData in packageItems) {
            if (itemData is Map<String, dynamic> &&
                itemData.containsKey('name') &&
                itemData.containsKey('price')) {

              // Use a combination of package ID and item name for a more unique ID
              // This helps if the same item name exists in different packages (though prices should be checked)
              String itemName = itemData['name'] as String;
              String uniqueId = doc.id + '_' + itemName.replaceAll(RegExp(r'\s+'), '_');

              allItems.add({
                'id': uniqueId, // More robust unique ID for cart management
                'name': itemName,
                'price': (itemData['price'] as num).toDouble(),
                'category': itemData['category'] as String? ?? 'Uncategorized',
                // Placeholder for item image - you might want to map categories to icons or use a default image
                'itemImageUrl': itemData['itemImageUrl'] ?? '', // If individual items have images
                'packageBannerUrl': packageData['bannerUrl'] ?? '', // Fallback to package banner
              });
            }
          }
        }
      }
      _allKasihItems = allItems;
      _updateDisplayItems();
    } catch (e) {
      print("Error fetching kasih items: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading items: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateDisplayItems() {
    setState(() {
      _displayItems = _allKasihItems.where((item) {
        bool isInCart = _cart.any((cartItem) => cartItem['id'] == item['id']);
        return !isInCart && item['price'] <= _remainingBalance;
      }).toList();
      _displayItems.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    if (item['price'] <= _remainingBalance) {
      setState(() {
        _cart.add(item);
        _remainingBalance -= item['price'];
        _updateDisplayItems();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item price exceeds remaining balance.")),
      );
    }
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      _cart.removeWhere((cartItem) => cartItem['id'] == item['id']);
      _remainingBalance += item['price'];
      _updateDisplayItems();
    });
  }

  String generatePickupCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> _checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = Timestamp.now();
      final pickupCode = generatePickupCode(8);
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDocSnap = await userDocRef.get();
      final userData = userDocSnap.data();
      final userName = userData?['name'] ?? 'Unknown User';

      double totalCartValue = _cart.fold(0.0, (sum, item) => sum + (item['price'] as double));

      await FirebaseFirestore.instance.collection('redeemedKasih').add({
        'userId': user.uid,
        'userName': userName,
        'voucherValue': widget.voucherValue,
        'valueRedeemed': totalCartValue,
        'pickupCode': pickupCode,
        'itemsRedeemed': _cart.map((item) => {
          'name': item['name'],
          'price': item['price'],
          'category': item['category'],
        }).toList(),
        'pickedUp': 'no',
        'processedOrder': 'no',
        'redeemedAt': now,
        'redeemType': 'itemSelection'
      });

      if (widget.voucherReceived.containsKey('voucherId')) {
        final targetVoucherId = widget.voucherReceived['voucherId'];
        List<dynamic> vouchers = List<dynamic>.from(userData?['voucherReceived'] ?? []);
        vouchers.removeWhere((v) => v is Map && v['voucherId'] == targetVoucherId);
        await userDocRef.update({'voucherReceived': vouchers});
      } else if (widget.voucherReceived.containsKey('docId')) {
        final docId = widget.voucherReceived['docId'];
        await FirebaseFirestore.instance.collection('applications').doc(docId).delete();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessRedeem()),
      );
    } catch (e) {
      print("Error during checkout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout failed: ${e.toString()}")),
      );
    } finally {
      if(mounted) { // Check if the widget is still in the tree
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalCartValue = _cart.fold(0.0, (sum, item) => sum + (item['price'] as double));

    return Scaffold(
      backgroundColor: const Color(0xFF303030), // Matching packageKasih.dart
      body: SafeArea( // Ensures content is not obscured by notches etc.
        child: Column(
          children: [
            // Custom header matching packageKasih.dart style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 15), // Adjusted top padding
              child: Column(
                children: [
                  SizedBox(height: 40.0),
                  Text(
                    "Redeem Your Voucher", // Changed Title
                    style: TextStyle(
                      color: Color(0xFFFDB515),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.0),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDB515)))
                  : _displayItems.isEmpty
                  ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _allKasihItems.isEmpty
                          ? 'No items available in Package Kasih program.'
                          : 'No more items available for your remaining balance, or all eligible items are in your cart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _displayItems.length,
                itemBuilder: (context, index) {
                  final item = _displayItems[index];
                  String displayImageUrl = item['itemImageUrl']?.isNotEmpty == true
                      ? item['itemImageUrl']
                      : item['packageBannerUrl']?.isNotEmpty == true
                      ? item['packageBannerUrl'] // Fallback to package banner
                      : ''; // No image

                  return Container( // Golden Card Container
                    margin: const EdgeInsets.symmetric(vertical: 8), // packageKasih.dart uses vertical: 10
                    padding: const EdgeInsets.all(10),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (displayImageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8), // Smaller radius for inner image
                            child: Image.network(
                              displayImageUrl,
                              height: 100, // Adjusted height to match screenshot style
                              width: 150, // Adjusted width
                              fit: BoxFit.contain, // Or BoxFit.cover depending on image aspect ratios
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100, width:150,
                                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.broken_image, color: Colors.grey.shade700, size: 40),
                                );
                              },
                            ),
                          )
                        else // Placeholder if no image at all
                          Container(
                            height: 100, width: 150,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Icon(Icons.shopping_basket, color: Color(0xFFA67C00).withOpacity(0.7), size: 40)),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          item['name'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16, // From packageKasih.dart "Package $label"
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA67C00), // From packageKasih.dart
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['category'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF303030), // From packageKasih.dart items list
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Divider to match style (optional, can be subtle)
                        Container(height: 1, color: Color(0xFFA67C00).withOpacity(0.3), margin: EdgeInsets.symmetric(horizontal: 20)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add, size:18, color: Colors.black87),
                            label: Text("Add", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            onPressed: () => _addToCart(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFDB515).withOpacity(0.9), // Slightly transparent to blend
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_cart.isNotEmpty) _buildCartView(totalCartValue),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildCartView(double totalCartValue) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Color(0xFF1C1C1C), // Darker color for cart section
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -4),
            )
          ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Cart (${_cart.length} ${_cart.length == 1 ? "item" : "items"})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFDB515)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (_cart.isNotEmpty)
            SizedBox(
              height: min(_cart.length * 70.0, 140.0), // Max height for 2 items with padding
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    color: Color(0xFF3F3F3F).withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      title: Text(item['name'] as String, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      // Price hidden for Asnaf in cart items as well, only total is shown
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => _removeFromCart(item),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFBF04), // Main action button color
              padding: const EdgeInsets.symmetric(vertical: 14), // Make button prominent
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Consistent border radius
              ),
            ),
            onPressed: _isLoading ? null : _checkout,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3,))
                : const Text(
              'Confirm & Redeem Items',
              style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}