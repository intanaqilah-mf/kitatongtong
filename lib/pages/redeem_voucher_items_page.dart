import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/order_summary_page.dart';
import 'dart:math';

class RedeemVoucherWithItemsPage extends StatefulWidget {
  final double voucherValue;
  final Map<String, dynamic> voucherReceived;

  const RedeemVoucherWithItemsPage({
    Key? key,
    required this.voucherValue,
    required this.voucherReceived,
  }) : super(key: key);

  @override
  _RedeemVoucherWithItemsPageState createState() =>
      _RedeemVoucherWithItemsPageState();
}

class _RedeemVoucherWithItemsPageState extends State<RedeemVoucherWithItemsPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allKasihItems = [];
  List<Map<String, dynamic>> _displayableItems = []; // List of items to actually display
  Map<String, Map<String, dynamic>> _cart = {}; // { 'itemId': { 'data': {...}, 'quantity': X } }
  double _totalCartValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchKasihItems();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _recalculateTotals() {
    double tempValue = 0.0;
    _cart.forEach((key, value) {
      final itemData = value['data'] as Map<String, dynamic>;
      final quantity = value['quantity'] as int;
      tempValue += (itemData['price'] as double) * quantity;
    });
    // Call setState in the methods that call this function
    _totalCartValue = tempValue;
  }

  void _updateDisplayableItems() {
    final remainingBalance = widget.voucherValue - _totalCartValue;

    _displayableItems = _allKasihItems.where((item) {
      // An item is displayable if:
      // 1. It is already in the cart (so the user can see/modify its quantity).
      final bool isInCart = _cart.containsKey(item['id']);
      // 2. Or, its price is less than or equal to the remaining balance.
      final bool canAfford = (item['price'] as double) <= remainingBalance;

      return isInCart || canAfford;
    }).toList();
  }


  int _getTotalItemsInCart() {
    if (_cart.isEmpty) return 0;
    return _cart.values
        .map((item) => item['quantity'] as int)
        .reduce((a, b) => a + b);
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
              String itemName = itemData['name'] as String;
              String uniqueId = doc.id + '_' + itemName.replaceAll(RegExp(r'\\s+'), '_');

              allItems.add({
                'id': uniqueId,
                'name': itemName,
                'price': (itemData['price'] as num).toDouble(),
                'category': itemData['category'] as String? ?? 'Uncategorized',
                'itemImageUrl': itemData['itemImageUrl'] ?? '',
                'packageBannerUrl': packageData['bannerUrl'] ?? '',
              });
            }
          }
        }
      }

      _allKasihItems = allItems;
      _allKasihItems.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading items: ${e.toString()}")),
      );
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
          _updateDisplayableItems(); // Initially populate displayable items
        });
      }
    }
  }

  void _incrementQuantity(Map<String, dynamic> item) {
    final itemPrice = item['price'] as double;
    if ((_totalCartValue + itemPrice) <= widget.voucherValue) {
      setState(() {
        final itemId = item['id'] as String;
        if (_cart.containsKey(itemId)) {
          _cart[itemId]!['quantity']++;
        } else {
          _cart[itemId] = {'data': item, 'quantity': 1};
        }
        _recalculateTotals();
        _updateDisplayableItems(); // Refresh the list of visible items
      });
    }
  }

  void _decrementQuantity(Map<String, dynamic> item) {
    setState(() {
      final itemId = item['id'] as String;
      if (_cart.containsKey(itemId)) {
        if (_cart[itemId]!['quantity'] > 1) {
          _cart[itemId]!['quantity']--;
        } else {
          _cart.remove(itemId);
        }
        _recalculateTotals();
        _updateDisplayableItems(); // Refresh the list of visible items
      }
    });
  }

  void _navigateToCheckout() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryPage(
          initialCart: _cart,
          voucherValue: widget.voucherValue,
          voucherReceived: widget.voucherReceived,
        ),
      ),
    );

    if (result is Map<String, Map<String, dynamic>>) {
      setState(() {
        _cart = result;
        _recalculateTotals();
        _updateDisplayableItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF303030),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDB515)))
                    : _allKasihItems.isEmpty
                    ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No items available at the moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ))
                    : _buildItemsListView(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCheckoutBar(),
            BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ],
        )
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 15),
      child: const Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Redeem Your Voucher",
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
    );
  }

  Widget _buildItemsListView() {
    if (!_isLoading && _displayableItems.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No more items match your voucher allowance, or all eligible items are in your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      itemCount: _displayableItems.length,
      itemBuilder: (context, index) {
        final item = _displayableItems[index];
        final itemId = item['id'] as String;
        final int quantity = _cart[itemId]?['quantity'] ?? 0;

        String displayImageUrl = item['itemImageUrl']?.isNotEmpty == true
            ? item['itemImageUrl']
            : item['packageBannerUrl']?.isNotEmpty == true
            ? item['packageBannerUrl']
            : '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
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
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    displayImageUrl,
                    height: 100,
                    width: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100, width:150,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.broken_image, color: Colors.grey.shade700, size: 40),
                      );
                    },
                  ),
                )
              else
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA67C00),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      item['category'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF303030),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildQuantityControl(item: item, quantity: quantity),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantityControl({required Map<String, dynamic> item, required int quantity}) {
    if (quantity == 0) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.add, size:18, color: Colors.black87),
        label: const Text("Add", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () => _incrementQuantity(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDB515).withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 30),
        ),
      );
    }
    else {
      final canIncrement = (_totalCartValue + (item['price'] as double)) <= widget.voucherValue;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFFDB515).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20)
        ),
        child: Row(
          children: [
            GestureDetector(
                onTap: () => _decrementQuantity(item),
                child: const Icon(Icons.remove, size: 20, color: Colors.black87)
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                  quantity.toString(),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
            GestureDetector(
                onTap: canIncrement ? () => _incrementQuantity(item) : null,
                child: Icon(Icons.add, size: 20, color: canIncrement ? Colors.black87 : Colors.black26)
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCheckoutBar() {
    final totalItems = _getTotalItemsInCart();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Color(0xFFFDB515), size: 32),
              if (totalItems > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$totalItems',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          ElevatedButton(
            onPressed: totalItems > 0 ? _navigateToCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFBF04),
              disabledBackgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    );
  }
}