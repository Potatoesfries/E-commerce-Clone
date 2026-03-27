import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> _cartItems = [];
  double _cartTotal = 0.0;
  bool _isLoading = true;
  Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await OrderService.getCartTotal();
      
      if (result['success'] == true) {
        setState(() {
          _cartItems = (result['cartItems'] ?? result['cart'] ?? result['items'] ?? []) as List;
          
          final total = result['cartTotal'] ?? result['total'] ?? result['total_price'] ?? 0;
          _cartTotal = double.parse(total.toString());
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackbar(result['message'] ?? 'Failed to load cart', Colors.red.shade400);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackbar('Error loading cart: $e', Colors.red.shade400);
      }
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green.shade400
                  ? Icons.check_circle_rounded
                  : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _updateQuantity(String cartId, int newQuantity) async {
    final result = await OrderService.updateCartItem(
      cartId: cartId,
      quantity: newQuantity,
    );

    if (result['success']) {
      _loadCart();
    } else {
      if (mounted) {
        _showSnackbar(result['message'] ?? 'Failed to update quantity', Colors.red.shade400);
      }
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) {
      _showSnackbar('Please select items to delete', Colors.orange.shade400);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, size: 48, color: Colors.red.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Remove Items',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Remove ${_selectedItems.length} item(s) from your cart?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      int failCount = 0;

      for (String cartId in _selectedItems) {
        final result = await OrderService.deleteCartItem(cartId);
        
        if (result['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      }

      setState(() => _selectedItems.clear());
      await _loadCart();

      if (mounted) {
        String message;
        Color backgroundColor;
        
        if (failCount == 0) {
          message = '$successCount item(s) removed from cart';
          backgroundColor = Colors.green.shade400;
        } else if (successCount == 0) {
          message = 'Failed to remove items';
          backgroundColor = Colors.red.shade400;
        } else {
          message = '$successCount removed, $failCount failed';
          backgroundColor = Colors.orange.shade400;
        }
        
        _showSnackbar(message, backgroundColor);
      }
    }
  }

  Future<void> _checkout() async {
    if (_selectedItems.isEmpty) {
      _showSnackbar('Please select items to checkout', Colors.orange.shade400);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_bag_rounded, size: 48, color: Colors.green.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirm Purchase',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Purchase ${_selectedItems.length} item(s)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${_calculateSelectedTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final result = await OrderService.buyProducts(
        cartIds: _selectedItems.toList(),
      );

      if (result['success']) {
        setState(() => _selectedItems.clear());
        _loadCart();
        if (mounted) {
          _showSnackbar(
            result['message'] ?? 'Purchase successful!',
            Colors.green.shade400,
          );
        }
      } else {
        if (mounted) {
          _showSnackbar(
            result['message'] ?? 'Purchase failed',
            Colors.red.shade400,
          );
        }
      }
    }
  }

  double _calculateSelectedTotal() {
    double total = 0;
    for (var item in _cartItems) {
      if (_selectedItems.contains(item['cart_id'].toString())) {
        final itemTotal = item['total_price_per_item'] ?? item['total_price'] ?? item['subtotal'] ?? 0;
        total += double.parse(itemTotal.toString());
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shopping Cart',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  if (_cartItems.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedItems.length == _cartItems.length) {
                            _selectedItems.clear();
                          } else {
                            _selectedItems = _cartItems
                                .map((item) => item['cart_id'].toString())
                                .toSet();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedItems.length == _cartItems.length
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedItems.length == _cartItems.length
                                  ? 'Deselect All'
                                  : 'Select All',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6B35),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Loading cart...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Your cart is empty',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add items to get started',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final cartId = item['cart_id'].toString();
                            final isSelected = _selectedItems.contains(cartId);

                            final price = double.parse((item['price'] ?? 0).toString());
                            final quantity = int.parse((item['quantity'] ?? 1).toString());
                            final totalPrice = double.parse(
                              (item['total_price_per_item'] ?? 
                               item['total_price'] ?? 
                               (price * quantity)).toString()
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF6B35)
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF6B35).withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedItems.remove(cartId);
                                          } else {
                                            _selectedItems.add(cartId);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFF6B35)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF6B35)
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item['product_image'] ?? '',
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.grey[200]!, Colors.grey[100]!],
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['product_name'] ?? 'Product',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Color(0xFF2C3E50),
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '\$${price.toStringAsFixed(2)} each',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF5F6F7),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (quantity > 1) {
                                                          _updateQuantity(cartId, quantity - 1);
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        child: Icon(
                                                          Icons.remove_rounded,
                                                          size: 16,
                                                          color: quantity > 1
                                                              ? const Color(0xFF2C3E50)
                                                              : Colors.grey[400],
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                      child: Text(
                                                        '$quantity',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2C3E50),
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _updateQuantity(cartId, quantity + 1);
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        child: const Icon(
                                                          Icons.add_rounded,
                                                          size: 16,
                                                          color: Color(0xFF2C3E50),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '\$${totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFFFF6B35),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (_cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedItems.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected (${_selectedItems.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '\$${_calculateSelectedTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _deleteSelectedItems,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red.shade600,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Checkout',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Select items to checkout or delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}