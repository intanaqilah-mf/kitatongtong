import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:projects/pages/order_summary_page.dart';
import 'dart:math';
import 'package:projects/localization/app_localizations.dart';

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
  bool _isInit = true;

  List<Map<String, dynamic>> _allKasihItems = [];
  List<Map<String, dynamic>> _displayableItems = [];
  Map<String, Map<String, dynamic>> _cart = {};
  double _totalCartValue = 0.0;

  @override
  void initState() {
    super.initState();
    // Data fetching is moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _fetchKasihItems();
    }
    _isInit = false;
    super.didChangeDependencies();
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
    setState(() {
      _totalCartValue = tempValue;
      _updateDisplayableItems();
    });
  }

  void _updateDisplayableItems() {
    final nonBungkusCategoriesInCart = _cart.values
        .where((cartItem) =>
    cartItem['data']['item_group'] != 'BARANGAN BERBUNGKUS')
        .map((cartItem) => cartItem['data']['category'] as String)
        .toSet();

    final bungkusCategoriesInCart = _cart.values
        .where((cartItem) =>
    cartItem['data']['item_group'] == 'BARANGAN BERBUNGKUS')
        .map((cartItem) => cartItem['data']['category'] as String)
        .toSet();

    setState(() {
      _displayableItems = _allKasihItems.where((item) {
        final itemId = item['id'];

        if (_cart.containsKey(itemId)) {
          return true;
        }

        final double itemPrice = (item['price'] as num).toDouble();
        if ((_totalCartValue + itemPrice) > widget.voucherValue) {
          return false;
        }

        if (item['type'] == 'hamper') {
          return true;
        }

        final itemGroup = item['item_group'];
        final itemCategory = item['category'];

        if (itemGroup == 'BARANGAN BERBUNGKUS') {
          return bungkusCategoriesInCart.contains(itemCategory) ||
              bungkusCategoriesInCart.length < 6;
        } else {
          return !nonBungkusCategoriesInCart.contains(itemCategory);
        }
      }).toList();
    });
  }

  int _getTotalItemsInCart() {
    if (_cart.isEmpty) return 0;
    return _cart.values
        .map((item) => item['quantity'] as int)
        .reduce((a, b) => a + b);
  }

  Future<void> _fetchKasihItems() async {
    final localizations = AppLocalizations.of(context);
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
              String uniqueId =
                  doc.id + '_' + itemName.replaceAll(RegExp(r'\\s+'), '_');

              allItems.add({
                'id': uniqueId,
                'name': itemName,
                'price': (itemData['price'] as num).toDouble(),
                'category': itemData['category'] as String? ?? localizations.translate('redeem_uncategorized'),
                'item_group':
                itemData['item_group'] as String? ?? localizations.translate('redeem_uncategorized'),
                'itemImageUrl': itemData['itemImageUrl'] ?? '',
                'packageBannerUrl': packageData['bannerUrl'] ?? '',
                'type': 'kasih',
                'hamper_items': [],
              });
            }
          }
        }
      }
      QuerySnapshot hamperSnapshot =
      await FirebaseFirestore.instance.collection('package_hamper').get();

      for (var doc in hamperSnapshot.docs) {
        final hamperData = doc.data() as Map<String, dynamic>;
        allItems.add({
          'id': doc.id,
          'name': hamperData['name'] ?? localizations.translate('redeem_unnamed_hamper'),
          'price': (hamperData['voucherValue'] as num?)?.toDouble() ?? 0.0,
          'itemImageUrl': hamperData['bannerUrl'] ?? '',
          'packageBannerUrl': '',
          'type': 'hamper',
          'hamper_items': hamperData['items'] as List? ?? [],
          'category': localizations.translate('redeem_hamper_category'),
          'item_group': localizations.translate('redeem_hamper_category'),
        });
      }

      allItems.sort((a, b) {
        if (a['type'] == 'hamper' && b['type'] != 'hamper') {
          return -1;
        }
        if (a['type'] != 'hamper' && b['type'] == 'hamper') {
          return 1;
        }
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      _allKasihItems = allItems;
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translateWithArgs('redeem_items_loading_error', {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateDisplayableItems();
        });
      }
    }
  }

  void _incrementQuantity(Map<String, dynamic> item) {
    final localizations = AppLocalizations.of(context);
    final double itemPrice = (item['price'] as num).toDouble();

    if ((_totalCartValue + itemPrice) > widget.voucherValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            localizations.translateWithArgs(
              'order_summary_exceed_voucher_error',
              { 'limit': widget.voucherValue.toStringAsFixed(2) },
            ),
          ),
        ),
      );
      return;                      // 🚫 bail out – nothing is added
    }
    final itemId = item['id'] as String;
    final itemGroup = item['item_group'] as String;
    final itemCategory = item['category'] as String;
    final itemType = item['type'] as String;
    final bool isInCart = _cart.containsKey(itemId);
    final int currentQuantity = _cart[itemId]?['quantity'] ?? 0;

    if (itemType == 'hamper') {
      setState(() {
        if (_cart.containsKey(itemId)) {
          _cart[itemId]!['quantity']++;
        } else {
          _cart[itemId] = {'data': item, 'quantity': 1};
        }
        _recalculateTotals();
      });
      return;
    }

    if (itemGroup == 'BARANGAN BERBUNGKUS') {
      if (currentQuantity >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(localizations.translate('redeem_max_quantity_warning')),
            backgroundColor: Colors.orange));
        return;
      }
      final bungkusCategoriesInCart = _cart.values
          .where((cartItem) =>
      cartItem['data']['item_group'] == 'BARANGAN BERBUNGKUS')
          .map((cartItem) => cartItem['data']['category'] as String)
          .toSet();
      if (!bungkusCategoriesInCart.contains(itemCategory) &&
          bungkusCategoriesInCart.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(localizations.translate('redeem_max_category_warning')),
            backgroundColor: Colors.orange));
        return;
      }
    } else {
      final nonBungkusCategoriesInCart = _cart.values
          .where((cartItem) =>
      cartItem['data']['item_group'] != 'BARANGAN BERBUNGKUS')
          .map((cartItem) => cartItem['data']['category'] as String)
          .toSet();
      if (!isInCart && nonBungkusCategoriesInCart.contains(itemCategory)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(localizations.translateWithArgs('redeem_one_item_per_category_warning', {'category': itemCategory})),
            backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() {
      if (isInCart) {
        _cart[itemId]!['quantity']++;
      } else {
        _cart[itemId] = { 'data': item, 'quantity': 1 };
      }
      _recalculateTotals();   // this keeps _displayableItems in sync
    });
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
        backgroundColor: const Color(0xFF303030),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFDB515)))
                    : _allKasihItems.isEmpty
                    ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        localizations.translate('redeem_no_items_available'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
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
        ));
  }

  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 15),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            localizations.translate('redeem_voucher_title'),
            style: const TextStyle(
              color: Color(0xFFFDB515),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }

  Widget _buildItemsListView() {
    final localizations = AppLocalizations.of(context);
    if (!_isLoading && _displayableItems.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              localizations.translate('redeem_no_more_items_available'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      itemCount: _displayableItems.length,
      itemBuilder: (context, index) {
        final item = _displayableItems[index];

        if (item['type'] == 'hamper') {
          return _buildHamperCard(item);
        } else {
          return _buildKasihItemCard(item);
        }
      },
    );
  }

  Widget _buildKasihItemCard(Map<String, dynamic> item) {
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
                    height: 100,
                    width: 150,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.broken_image,
                        color: Colors.grey.shade700, size: 40),
                  );
                },
              ),
            )
          else
            Container(
              height: 100,
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Icon(Icons.shopping_basket,
                      color: const Color(0xFFA67C00).withOpacity(0.7), size: 40)),
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
  }

  Widget _buildHamperCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final int quantity = _cart[itemId]?['quantity'] ?? 0;
    final List hamperItems = item['hamper_items'] ?? [];
    final String displayImageUrl = item['itemImageUrl'] ?? '';

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
          Text(
            item['name'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA67C00),
            ),
          ),
          const SizedBox(height: 12),
          if (displayImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                displayImageUrl,
                height: 100,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: 150,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.broken_image,
                        color: Colors.grey.shade700, size: 40),
                  );
                },
              ),
            )
          else
            Container(
              height: 100,
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Icon(Icons.shopping_basket,
                      color: const Color(0xFFA67C00).withOpacity(0.7), size: 40)),
            ),
          const SizedBox(height: 12),
          ...List.generate(hamperItems.length, (i) {
            final subItem = hamperItems[i];
            String itemName = subItem['name'] ?? "";
            String itemNumber = subItem.containsKey('number')
                ? subItem['number'].toString()
                : "";
            String itemUnit = subItem['unit'] ?? "";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                "${i + 1}. $itemName ${itemNumber.isNotEmpty ? 'x$itemNumber' : ''} $itemUnit"
                    .trim(),
                style: const TextStyle(color: Colors.black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RM${(item['price'] as double).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.transparent,
                ),
              ),
              _buildQuantityControl(item: item, quantity: quantity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(
      {required Map<String, dynamic> item, required int quantity}) {
    final localizations = AppLocalizations.of(context);
    if (quantity == 0) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 18, color: Colors.black87),
        label: Text(localizations.translate('redeem_add_button'),
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        onPressed: () => _incrementQuantity(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDB515).withOpacity(0.9),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 30),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFFDB515).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            GestureDetector(
                onTap: () => _decrementQuantity(item),
                child: const Icon(Icons.remove, size: 20, color: Colors.black87)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(quantity.toString(),
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            GestureDetector(
                onTap: () => _incrementQuantity(item),
                child: const Icon(Icons.add, size: 20, color: Colors.black87)),
          ],
        ),
      );
    }
  }

  Widget _buildCheckoutBar() {
    final localizations = AppLocalizations.of(context);
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
              const Icon(Icons.shopping_cart_outlined,
                  color: Color(0xFFFDB515), size: 32),
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
                    constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
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
            child: Text(
              localizations.translate('redeem_checkout_button'),
              style: const TextStyle(
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
