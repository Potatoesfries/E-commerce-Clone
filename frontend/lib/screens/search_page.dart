import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'shop_page.dart';

class SearchPage extends StatefulWidget {
  final Function(String)? onNavigateToShop;

  const SearchPage({super.key, this.onNavigateToShop});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoggedIn = false;

final List<Map<String, String>> _categories = [
  {
    'name': 'Electronics',
    'image': 'https://res.cloudinary.com/dby0dkagu/image/upload/v1759816901/Iphone_bmnxf7.png'
  },
  {
    'name': 'Fashion & Clothing',
    'image': 'https://res.cloudinary.com/dby0dkagu/image/upload/v1759816901/fashion_and_clothing_rhkv70.png'
  },
  {
    'name': 'Home & Living',
    'image': 'https://res.cloudinary.com/dby0dkagu/image/upload/v1759816901/home_and_living_z3x3qj.png'
  },
  {
    'name': 'Books & Education',
    'image': 'https://res.cloudinary.com/dby0dkagu/image/upload/v1759816901/books_and_education_oongma.png'
  },
  {
    'name': 'Sports & Fitness',
    'image': 'http://res.cloudinary.com/dby0dkagu/image/upload/v1759816901/sport_and_fitness_hlrzdm.png'
  },
  {
    'name': 'Beauty & Health',
    'image': 'https://res.cloudinary.com/dby0dkagu/image/upload/v1759816902/health_and_beauty_2_kqln1y.png'
  },
];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
  }

  void _navigateToSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchQuery: query,
          isLoggedIn: _isLoggedIn,
          onNavigateToShop: widget.onNavigateToShop,
        ),
      ),
    );
  }

  void _navigateToCategoryResults(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchQuery: '',
          category: category,
          isLoggedIn: _isLoggedIn,
          onNavigateToShop: widget.onNavigateToShop,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _navigateToSearchResults(''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFFF6B35),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Search for products, shops...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFFFF6B35),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Categories You Might Like',
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryCard(category);
                      },
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

  Widget _buildCategoryCard(Map<String, String> category) {
    return GestureDetector(
      onTap: () => _navigateToCategoryResults(category['name']!),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  category['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(
                      Icons.category,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFFFF6B35),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category['name']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search Results Page
class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final String? category;
  final bool isLoggedIn;
  final Function(String)? onNavigateToShop;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.category,
    required this.isLoggedIn,
    this.onNavigateToShop,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery;
    _selectedCategory = widget.category;
    _searchController.text = widget.searchQuery;
    _loadAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoading = true);
    final result = await ProductService.getAllProducts();
    
    if (result['success']) {
      setState(() {
        _allProducts = result['products'] ?? [];
        _applyFilters();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<dynamic> filtered = _allProducts;

    if (_selectedCategory != null) {
      filtered = filtered.where((product) {
        return product['category'] == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final productName = (product['product_name'] ?? '').toString().toLowerCase();
        final shopName = (product['shop_name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        
        return productName.contains(query) || 
               shopName.contains(query) || 
               description.contains(query);
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
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
        onNavigateToShop: (shopName) {
          Navigator.pop(context);
          Navigator.pop(context);
          widget.onNavigateToShop?.call(shopName);
        },
        getShopData: _getShopData,
        buildProductImage: _buildProductImage,
      ),
    );
  }

  Future<void> _addToCart(String productId, dynamic product) async {
    if (!widget.isLoggedIn) {
      _showLoginPrompt();
      return;
    }

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
        _showSuccessDialog(product);
      } else {
        _showSnackbar(result['message'] ?? 'Failed to add to cart', Colors.red.shade400);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(28),
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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

  Widget _buildProductImage(String? imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(width, height);
    }

    final Uri? uri = Uri.tryParse(imageUrl);
    if (uri == null || (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
      return _buildPlaceholderImage(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) => _buildPlaceholderImage(width, height),
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
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
              child: Column(
                children: [
                  Row(
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
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          autofocus: widget.searchQuery.isEmpty && widget.category == null,
                          decoration: InputDecoration(
                            hintText: 'Search for products, shops...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFFFF6B35),
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded, color: Colors.grey[600], size: 20),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF6B35).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.category_rounded,
                                  color: Color(0xFFFF6B35),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedCategory!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = null;
                                      _applyFilters();
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFFF6B35),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                            'Searching...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredProducts.isEmpty
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
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching for something else',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                              child: Text(
                                '${_filteredProducts.length} result${_filteredProducts.length != 1 ? 's' : ''} found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadAllProducts,
                                color: const Color(0xFFFF6B35),
                                child: GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                                ),
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

// Product Detail Sheet
class _ProductDetailSheet extends StatefulWidget {
  final dynamic product;
  final List<dynamic> recommendedProducts;
  final Function(String, dynamic) onAddToCart;
  final Function(String) onNavigateToShop;
  final Future<Map<String, dynamic>> Function(String) getShopData;
  final Widget Function(String?, {double? width, double? height, BoxFit fit}) buildProductImage;

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
                          _currentProduct['description'] ?? 'No description available',
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

                  InkWell(
                    onTap: () async {
                      final shopName = _currentProduct['shop_name'] ?? '';
                      final shopData = await widget.getShopData(shopName);

                      if (shopData.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopDetailPage(shop: shopData),
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
                              backgroundImage: _currentProduct['shop_picture'] != null
                                  ? NetworkImage(_currentProduct['shop_picture'])
                                  : null,
                              backgroundColor: Colors.grey[100],
                              child: _currentProduct['shop_picture'] == null
                                  ? Icon(Icons.store_rounded, size: 28, color: Colors.grey[400])
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
                                    Icon(Icons.verified_rounded, size: 14, color: Colors.blue[600]),
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
                          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 28),
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
                                  color: const Color(0xFFFF6B35).withOpacity(0.1),
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.70,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: currentRecommended.length,
                            itemBuilder: (context, index) => _buildRecommendedCard(currentRecommended[index]),
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
                        color: (_currentProduct['stock'] ?? 0) > 0 ? Colors.white : Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (_currentProduct['stock'] ?? 0) > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: (_currentProduct['stock'] ?? 0) > 0 ? Colors.white : Colors.grey[600],
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                    '\$${product['price'] ?? 0}',
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