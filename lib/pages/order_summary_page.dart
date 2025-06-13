import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/pages/successRedeem.dart';
import 'dart:math';

class OrderSummaryPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> initialCart;
  final double voucherValue;
  final Map<String, dynamic> voucherReceived;

  const OrderSummaryPage({
    Key? key,
    required this.initialCart,
    required this.voucherValue,
    required this.voucherReceived,
  }) : super(key: key);

  @override
  _OrderSummaryPageState createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  late Map<String, Map<String, dynamic>> _cart;
  double _totalCartValue = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the cart to modify it locally
    _cart = Map.from(widget.initialCart);
    _recalculateTotals();
  }

  void _recalculateTotals() {
    double tempValue = 0.0;
    _cart.forEach((key, value) {
      final itemData = value['data'] as Map<String, dynamic>;
      final quantity = value['quantity'] as int;
      tempValue += (itemData['price'] as double) * quantity;
    });
    setState(() {
      _totalCartValue = tempValue;
    });
  }

  int _getTotalItems() {
    if (_cart.isEmpty) return 0;
    return _cart.values
        .map((item) => item['quantity'] as int)
        .reduce((a, b) => a + b);
  }

  void _incrementQuantity(String itemId) {
    final itemData = _cart[itemId]!['data'] as Map<String, dynamic>;
    final itemPrice = itemData['price'] as double;

    if ((_totalCartValue + itemPrice) <= widget.voucherValue) {
      setState(() {
        _cart[itemId]!['quantity']++;
        _recalculateTotals();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Cannot exceed voucher value.")),
      );
    }
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      if (_cart[itemId]!['quantity'] > 1) {
        _cart[itemId]!['quantity']--;
      } else {
        // If quantity is 1, remove it from the cart
        _cart.remove(itemId);
      }
      _recalculateTotals();
    });
  }

  String generatePickupCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> _placeOrder() async {
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

      final List<Map<String, dynamic>> itemsForFirebase = [];
      _cart.forEach((key, value) {
        final item = value['data'] as Map<String, dynamic>;
        final quantity = value['quantity'] as int;

        String imageUrlToSave = item['itemImageUrl']?.isNotEmpty == true
            ? item['itemImageUrl']
            : item['packageBannerUrl'] ?? '';

        // Add item to the list 'quantity' times
        for (int i = 0; i < quantity; i++) {
          itemsForFirebase.add({
            'name': item['name'],
            'price': item['price'],
            'category': item['category'],
            'imageUrl': imageUrlToSave,
          });
        }
      });


      await FirebaseFirestore.instance.collection('redeemedKasih').add({
        'userId': user.uid,
        'userName': userName,
        'voucherValue': widget.voucherValue,
        'valueRedeemed': _totalCartValue,
        'pickupCode': pickupCode,
        'itemsRedeemed': itemsForFirebase,
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SuccessRedeem()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checkout failed: ${e.toString()}")),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the (possibly modified) cart to the previous screen
        Navigator.pop(context, _cart);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF303030),
        appBar: AppBar(
          title: const Text(
            "Order Summary",
            style: TextStyle(
              color: Color(0xFFFDB515),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFDB515)),
            onPressed: () {
              Navigator.pop(context, _cart);
            },
          ),
        ),
        body: _cart.isEmpty
            ? const Center(
          child: Text(
            "Your cart is empty.",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMasjidInfoCard(),
                    const SizedBox(height: 16),
                    _buildItemsList(),
                  ],
                ),
              ),
            ),
            _buildBottomSummaryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMasjidInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_on, color: Color(0xFFFDB515), size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masjid MADAD (+60146019090)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Masjid MADAD, Kampung Telok, 08000 Sungai Petani, Kedah",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final cartItems = _cart.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF303030)),
        itemBuilder: (context, index) {
          final itemId = cartItems[index].key;
          final item = cartItems[index].value;
          final itemData = item['data'] as Map<String, dynamic>;
          final quantity = item['quantity'] as int;

          String displayImageUrl = itemData['itemImageUrl']?.isNotEmpty == true
              ? itemData['itemImageUrl']
              : itemData['packageBannerUrl'] ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: displayImageUrl.isNotEmpty
                      ? Image.network(
                    displayImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.shopping_basket, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemData['name'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemData['category'] as String? ?? 'Uncategorized',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onTap: () => _decrementQuantity(itemId),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onTap: () => _incrementQuantity(itemId),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: const Color(0xFFFDB515),
                borderRadius: BorderRadius.circular(4)
            ),
            child: Icon(icon, color: Colors.black, size: 20)
        )
    );
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(
          bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        border: Border(top: BorderSide(color: Color(0xFF303030))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total (${_getTotalItems()} items)",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          ElevatedButton(
            onPressed: _isLoading || _getTotalItems() == 0 ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFBF04),
              disabledBackgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
            )
                : const Text(
              "Place Order",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}