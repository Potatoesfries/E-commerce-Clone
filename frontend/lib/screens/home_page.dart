import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'shop_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToCart;
  final Function(String)? onNavigateToShop;
  final VoidCallback? onNavigateToShopTab;  // Add this line

  const HomePage({
    super.key, 
    this.onNavigateToCart, 
    this.onNavigateToShop,
    this.onNavigateToShopTab,  // Add this line
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _products = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _selectedCategory = 'All';
  int _cartItemCount = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;

  final List<Map<String, String>> _categories = [
    {'name': 'All'},
    {'name': 'Electronics'},
    {'name': 'Fashion & Clothing'},
    {'name': 'Home & Living'},
    {'name': 'Books & Education'},
    {'name': 'Sports & Fitness'},
    {'name': 'Beauty & Health'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _loadProducts();
    _checkLoginStatus();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

Future<Map<String, dynamic>> _getShopData(String shopName) async {
  // Filter all products by this shop
  final shopProducts = _allProducts
      .where((p) => p['shop_name'] == shopName)
      .toList();

  if (shopProducts.isEmpty) {
    return {};
  }

  final firstProduct = shopProducts.first;

  return {
    'shop_name': shopName,
    'owner_id': firstProduct['owner_id'],
    'owner_picture': firstProduct['shop_picture'], 
    'products': shopProducts,
    'product_count': shopProducts.length,
  };
}

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  Future<void> _loadCartCount() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      setState(() => _cartItemCount = 0);
      return;
    }

    try {
      final result = await OrderService.getCartTotal();
      if (result['success'] == true) {
        final cartItems =
            (result['cartItems'] ?? result['cart'] ?? result['items'] ?? [])
                as List;
        setState(() => _cartItemCount = cartItems.length);
      }
    } catch (e) {
      setState(() => _cartItemCount = 0);
    }
  }

  Future<void> _loadProducts({String? category}) async {
    setState(() => _isLoading = true);

    final result = category == null || category == 'All'
        ? await ProductService.getAllProducts()
        : await ProductService.getProductsByCategory(category);

    if (result['success']) {
      setState(() {
        _allProducts = result['products'] ?? [];
        _applySearchFilter();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _products = List.from(_allProducts);
    } else {
      _products = _allProducts.where((product) {
        final productName = (product['product_name'] ?? '')
            .toString()
            .toLowerCase();
        final shopName = (product['shop_name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '')
            .toString()
            .toLowerCase();
        final query = _searchQuery.toLowerCase();
        return productName.contains(query) ||
            shopName.contains(query) ||
            description.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _loadProducts(category: category == 'All' ? null : category);
  }

void _onPromoBannerTap(String promoType) {
  widget.onNavigateToShopTab?.call();
}

  Future<void> _addToCart(String productId, dynamic product) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    // Show elegant loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Adding to cart...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await OrderService.addToCart(
      productId: productId,
      quantity: 1,
    );

    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        _loadCartCount();
        _showSuccessDialog(product);
      } else {
        _showErrorSnackbar(result['message']);
      }
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please login to add items to your cart',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(dynamic product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated success icon
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 56,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Added to Cart!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['product_name'] ?? 'Product',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${product['price'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 20,
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
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFFF6B35),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Keep Shopping',
                            style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            _navigateToCart();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
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
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToCart() {
    widget.onNavigateToCart?.call();
  }

  void _navigateToShop(String shopName) {
    widget.onNavigateToShop?.call(shopName);
  }

  List<dynamic> _getRecommendedProducts(String currentProductId) {
    return _allProducts
        .where((p) => p['product_id'].toString() != currentProductId)
        .take(6)
        .toList();
  }

  void _showProductDetails(dynamic product) {
    final recommendedProducts = _getRecommendedProducts(
      product['product_id'].toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductDetailSheet(
        product: product,
        recommendedProducts: recommendedProducts,
        onAddToCart: _addToCart,
        onNavigateToShop: _navigateToShop,
        getShopData: _getShopData,
        buildProductImage: _buildProductImage,
      ),
    );
  }

  Widget _buildProductImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(width, height);
    }

    final Uri? uri = Uri.tryParse(imageUrl);
    if (uri == null ||
        (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
      return _buildPlaceholderImage(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _buildPlaceholderImage(width, height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[200]!, Colors.grey[100]!],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: const Color(0xFFFF6B35),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(
    String title,
    String subtitle,
    List<Color> gradientColors,
    String badgeText,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () => _onPromoBannerTap(title),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: gradientColors[1]),
                            const SizedBox(width: 6),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: gradientColors[1],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop Now',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: gradientColors[1],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: gradientColors[1],
                            ),
                          ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 4, 16, 6),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Cart Icon Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://res.cloudinary.com/dby0dkagu/image/upload/v1759822956/logo_glbb61.png',
                            height: 50,
                            width: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Container(
                              height: 50,
                              width: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'ShopApp',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Cart Icon with Badge
                        GestureDetector(
                          onTap: _navigateToCart,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Color(0xFFFF6B35),
                                  size: 24,
                                ),
                                if (_cartItemCount > 0)
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _cartItemCount > 99
                                              ? '99+'
                                              : '$_cartItemCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search products, shops...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFFF6B35),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F6F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['name'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      elevation: isSelected ? 4 : 0,
                      shadowColor: const Color(0xFFFF6B35).withOpacity(0.3),
                      child: InkWell(
                        onTap: () => _onCategorySelected(category['name']!),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey[200]!,
                              width: isSelected ? 0 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category['name']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                            'Loading products...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
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
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products found'
                                : 'No products available',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for something else'
                                : 'Check back later for new items',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadProducts(
                        category: _selectedCategory == 'All'
                            ? null
                            : _selectedCategory,
                      ),
                      color: const Color(0xFFFF6B35),
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Special Offers',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.orange,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'HOT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      children: [
                                        _buildPromoBanner(
                                          'Flash Sale',
                                          'Up to 50% off',
                                          [
                                            const Color(0xFFFF6B35),
                                            const Color(0xFFFF8C42),
                                          ],
                                          'LIMITED TIME',
                                          Icons.flash_on_rounded,
                                        ),
                                        _buildPromoBanner(
                                          'New Arrivals',
                                          'Fresh products daily',
                                          [
                                            const Color(0xFF4A90E2),
                                            const Color(0xFF5BA3F5),
                                          ],
                                          'JUST IN',
                                          Icons.new_releases_rounded,
                                        ),
                                        _buildPromoBanner(
                                          'Quick Deals',
                                          'Grab before gone',
                                          [
                                            const Color(0xFF9B59B6),
                                            const Color(0xFFB370CF),
                                          ],
                                          'HURRY UP',
                                          Icons.local_fire_department_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Container(
                              color: const Color(0xFFF8F9FA),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                12,
                              ),
                              child: const Text(
                                'All Products',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ),

                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildProductCard(_products[index]),
                                childCount: _products.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final stock = product['stock'] ?? 0;
    final sold = product['sold'] ?? 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildProductImage(
                    product['product_image'],
                    width: double.infinity,
                    height: 130,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: stock == 0
                          ? Colors.red.shade600
                          : stock < 5
                          ? Colors.red.shade600
                          : stock < 20
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      stock == 0
                          ? 'Out'
                          : stock < 5
                          ? 'Only $stock'
                          : stock < 20
                          ? '$stock left'
                          : 'In Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product['product_name'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['shop_name'] ?? 'Shop',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product['price'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sold > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$sold sold',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
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

class _ProductDetailSheet extends StatefulWidget {
  final dynamic product;
  final List<dynamic> recommendedProducts;
  final Function(String, dynamic) onAddToCart;
  final Function(String) onNavigateToShop;
  final Future<Map<String, dynamic>> Function(String) getShopData;
  final Widget Function(String?, {double? width, double? height, BoxFit fit})
  buildProductImage;

  const _ProductDetailSheet({
    required this.product,
    required this.recommendedProducts,
    required this.onAddToCart,
    required this.onNavigateToShop,
    required this.getShopData,
    required this.buildProductImage,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  dynamic _currentProduct;
  List<dynamic> _productHistory = [];

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  void _viewProduct(dynamic product) {
    setState(() {
      _productHistory.add(_currentProduct);
      _currentProduct = product;
    });
  }

  void _goBack() {
    if (_productHistory.isNotEmpty) {
      setState(() {
        _currentProduct = _productHistory.removeLast();
      });
    }
  }

  List<dynamic> _getCurrentRecommendedProducts() {
    final excludeIds = [
      _currentProduct['product_id'].toString(),
      ..._productHistory.map((p) => p['product_id'].toString()),
    ];

    return widget.recommendedProducts
        .where((p) => !excludeIds.contains(p['product_id'].toString()))
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentRecommended = _getCurrentRecommendedProducts();

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_productHistory.isNotEmpty)
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: widget.buildProductImage(
                      _currentProduct['product_image'],
                      width: double.infinity,
                      height: 380,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '\$',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                            Text(
                              '${_currentProduct['price'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentProduct['product_name'] ?? 'Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: (_currentProduct['stock'] ?? 0) > 10
                                ? Colors.green.shade50
                                : (_currentProduct['stock'] ?? 0) > 0
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_currentProduct['stock'] ?? 0) > 10
                                  ? Colors.green.shade300
                                  : (_currentProduct['stock'] ?? 0) > 0
                                  ? Colors.orange.shade300
                                  : Colors.red.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_currentProduct['stock'] ?? 0) > 10
                                    ? Icons.check_circle_rounded
                                    : (_currentProduct['stock'] ?? 0) > 0
                                    ? Icons.warning_rounded
                                    : Icons.cancel_rounded,
                                size: 16,
                                color: (_currentProduct['stock'] ?? 0) > 10
                                    ? Colors.green.shade700
                                    : (_currentProduct['stock'] ?? 0) > 0
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (_currentProduct['stock'] ?? 0) > 10
                                    ? '${_currentProduct['stock']} available'
                                    : (_currentProduct['stock'] ?? 0) > 0
                                    ? 'Only ${_currentProduct['stock']} left'
                                    : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: (_currentProduct['stock'] ?? 0) > 10
                                      ? Colors.green.shade700
                                      : (_currentProduct['stock'] ?? 0) > 0
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentProduct['description'] ??
                              'No description available',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // In _ProductDetailSheetState build method, update the shop section:
                  InkWell(
                    onTap: () async {
                      final shopName = _currentProduct['shop_name'] ?? '';
                      final shopData = await widget.getShopData(shopName);

                      if (shopData.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopDetailPage(shop: shopData),
                          ),
                        );
                      }
                    },
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF6B35),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  _currentProduct['shop_picture'] !=
                                      null
                                  ? NetworkImage(
                                      _currentProduct['shop_picture'],
                                    )
                                  : null,
                              backgroundColor: Colors.grey[100],
                              child:
                                  _currentProduct['shop_picture'] ==
                                      null
                                  ? Icon(
                                      Icons.store_rounded,
                                      size: 28,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentProduct['shop_name'] ?? 'Shop',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Visit Store',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (currentRecommended.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFFF6B35),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'You might also like',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: currentRecommended.length,
                            itemBuilder: (context, index) =>
                                _buildRecommendedCard(
                                  currentRecommended[index],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_currentProduct['stock'] ?? 0) > 0
                      ? () {
                          widget.onAddToCart(
                            _currentProduct['product_id'].toString(),
                            _currentProduct,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_rounded,
                        color: (_currentProduct['stock'] ?? 0) > 0
                            ? Colors.white
                            : Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (_currentProduct['stock'] ?? 0) > 0
                            ? 'Add to Cart'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: (_currentProduct['stock'] ?? 0) > 0
                              ? Colors.white
                              : Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(dynamic product) {
    return GestureDetector(
      onTap: () => _viewProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: widget.buildProductImage(
                product['product_image'],
                width: double.infinity,
                height: 140,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'] ?? 'Product',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\ ${product['price'] ?? 0}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopDetailPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopDetailPage({super.key, required this.shop});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(widget.shop['products'] as List);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(widget.shop['products'] as List);
      } else {
        _filteredProducts = (widget.shop['products'] as List).where((product) {
          final productName = (product['product_name'] ?? '')
              .toString()
              .toLowerCase();
          final description = (product['description'] ?? '')
              .toString()
              .toLowerCase();
          return productName.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _addToCart(dynamic product) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Adding to cart...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await OrderService.addToCart(
      productId: product['product_id'].toString(),
      quantity: 1,
    );

    if (mounted) {
      Navigator.pop(context);

      if (result['success']) {
        _showSuccessDialog(product);
      } else {
        _showErrorSnackbar(result['message'] ?? 'Failed to add to cart');
      }
    }
  }

  void _showSuccessDialog(dynamic product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 56,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Added to Cart!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['product_name'] ?? 'Product',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${product['price'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showProductDetails(dynamic product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      child: _buildProductImage(
                        product['product_image'],
                        width: double.infinity,
                        height: 380,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '\$',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                              Text(
                                '${product['price'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            product['product_name'] ?? 'Product',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (product['stock'] ?? 0) > 10
                                  ? Colors.green.shade50
                                  : (product['stock'] ?? 0) > 0
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (product['stock'] ?? 0) > 10
                                    ? Colors.green.shade300
                                    : (product['stock'] ?? 0) > 0
                                    ? Colors.orange.shade300
                                    : Colors.red.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (product['stock'] ?? 0) > 10
                                      ? Icons.check_circle_rounded
                                      : (product['stock'] ?? 0) > 0
                                      ? Icons.warning_rounded
                                      : Icons.cancel_rounded,
                                  size: 16,
                                  color: (product['stock'] ?? 0) > 10
                                      ? Colors.green.shade700
                                      : (product['stock'] ?? 0) > 0
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (product['stock'] ?? 0) > 10
                                      ? '${product['stock']} available'
                                      : (product['stock'] ?? 0) > 0
                                      ? 'Only ${product['stock']} left'
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: (product['stock'] ?? 0) > 10
                                        ? Colors.green.shade700
                                        : (product['stock'] ?? 0) > 0
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (product['description'] != null &&
                        product['description'].toString().isNotEmpty)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product['description'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
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
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (product['stock'] ?? 0) > 0
                        ? () {
                            Navigator.pop(context);
                            _addToCart(product);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_rounded,
                          color: (product['stock'] ?? 0) > 0
                              ? Colors.white
                              : Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          (product['stock'] ?? 0) > 0
                              ? 'Add to Cart'
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: (product['stock'] ?? 0) > 0
                                ? Colors.white
                                : Colors.grey[600],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) =>
          _buildPlaceholderImage(width, height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[200]!, Colors.grey[100]!],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: const Color(0xFFFF6B35),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF2C3E50),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.shop['shop_name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search in this shop...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFFF6B35),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F6F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B35).withOpacity(0.1),
                          const Color(0xFFFF8C42).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6B35),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundImage:
                                widget.shop['owner_picture'] != null
                                ? NetworkImage(widget.shop['owner_picture'])
                                : null,
                            backgroundColor: Colors.white,
                            child: widget.shop['owner_picture'] == null
                                ? const Icon(
                                    Icons.store,
                                    color: Color(0xFFFF6B35),
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shop['shop_name'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.inventory_2_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.shop['product_count']} products',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                ],
              ),
            ),
            Expanded(
              child: _filteredProducts.isEmpty
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
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.inventory_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No products found'
                                : 'No products available',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for something else'
                                : 'This shop hasn\'t added any products yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(_filteredProducts[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final stock = product['stock'] ?? 0;
    final sold = product['sold'] ?? 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildProductImage(
                    product['product_image'],
                    width: double.infinity,
                    height: 130,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: stock == 0
                          ? Colors.red.shade600
                          : stock < 5
                          ? Colors.red.shade600
                          : stock < 20
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      stock == 0
                          ? 'Out'
                          : stock < 5
                          ? 'Only $stock'
                          : stock < 20
                          ? '$stock left'
                          : 'In Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product['product_name'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product['price'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sold > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$sold sold',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
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
