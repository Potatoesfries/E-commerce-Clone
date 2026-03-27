import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/shop_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';

class ShopPage extends StatefulWidget {
  final String? shopName;
  
  const ShopPage({super.key, this.shopName});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasShop = false;
  List<dynamic> _myProducts = [];
  List<dynamic> _allShops = [];
  Map<String, dynamic>? _userData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

Future<void> _initialize() async {
  setState(() => _isLoading = true);
  
  final loggedIn = await AuthService.isLoggedIn();
  setState(() => _isLoggedIn = loggedIn);

  if (loggedIn) {
    await _loadUserData();
    if (_hasShop) {
      await _loadMyProducts(); // This loads products first
    }
  }
  
  await _loadAllShops();
  setState(() => _isLoading = false);
}

Future<void> _loadUserData() async {
  final userId = await AuthService.getUserId();
  if (userId != null) {
    final response = await AuthService.authenticatedRequest(
      method: 'GET',
      endpoint: '/api/users/$userId',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      setState(() {
        _userData = data;
        _hasShop = data['has_shop'] == 1;
      });
    }
  }
}

  Future<void> _loadMyProducts() async {
    final result = await ProductService.getMyProducts();
    if (result['success']) {
      setState(() => _myProducts = result['products'] ?? []);
    }
  }

  Future<void> _loadAllShops() async {
    final result = await ProductService.getAllProducts();
    if (result['success']) {
      final products = result['products'] as List;
      
      final Map<String, List<dynamic>> shopMap = {};
      for (var product in products) {
        final shopName = product['shop_name'] ?? 'Unknown Shop';
        if (!shopMap.containsKey(shopName)) {
          shopMap[shopName] = [];
        }
        shopMap[shopName]!.add(product);
      }

      final shops = shopMap.entries.map((entry) => {
        'shop_name': entry.key,
        'products': entry.value,
        'product_count': entry.value.length,
        'owner_picture': entry.value.first['shop_picture'],
        'owner_id': entry.value.first['owner_id'],
      }).toList();

      setState(() => _allShops = shops);
    }
  }

  Future<void> _createShop() async {
    final shopNameController = TextEditingController();
    XFile? shopImage;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create Your Shop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              setDialogState(() => shopImage = image);
                            },
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: shopImage == null ? Colors.grey[200]! : const Color(0xFFFF6B35),
                                  width: 2,
                                ),
                              ),
                              child: shopImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        File(shopImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 48,
                                            color: Color(0xFFFF6B35),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Add Shop Image',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to upload',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Shop Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: shopNameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your shop name',
                            prefixIcon: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6B35)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (shopNameController.text.trim().isNotEmpty) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Create Shop', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && shopNameController.text.trim().isNotEmpty) {
      final createResult = await ShopService.createShop(
        shopName: shopNameController.text.trim(),
        shopImage: shopImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createResult['message'] ?? 
              (createResult['success'] ? 'Shop created successfully!' : 'Failed to create shop')),
            backgroundColor: createResult['success'] ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (createResult['success']) {
        await _initialize();
      }
    }
  }

  Future<void> _navigateToMyShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyShopDetailPage(
          userData: _userData!,
          myProducts: _myProducts,
          onRefresh: _initialize,
        ),
      ),
    );
    await _initialize();
  }

  Future<void> _navigateToShopDetail(Map<String, dynamic> shop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailPage(
          shop: shop,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ShopPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.shopName != null && widget.shopName != oldWidget.shopName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToSpecificShop(widget.shopName!);
      });
    }
  }

  Future<void> _navigateToSpecificShop(String shopName) async {
    final shop = _allShops.firstWhere(
      (s) => s['shop_name'] == shopName,
      orElse: () => <String, dynamic>{},
    );

    if (shop.isNotEmpty) {
      await _navigateToShopDetail(shop);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
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
                'Loading shops...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Shops', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _initialize,
        color: const Color(0xFFFF6B35),
        child: CustomScrollView(
          slivers: [
            if (_isLoggedIn && _hasShop)
              SliverToBoxAdapter(
                child: _buildMyShopSection(),
              ),
            if (_isLoggedIn && !_hasShop)
              SliverToBoxAdapter(
                child: _buildCreateShopSection(),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFFFF6B35),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _hasShop ? 'Discover More Shops' : 'All Shops',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_allShops.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No shops available yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to create a shop!',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = _allShops[index];
                      if (_hasShop && shop['shop_name'] == _userData?['shop_name']) {
                        return const SizedBox.shrink();
                      }
                      return _buildShopCard(shop);
                    },
                    childCount: _allShops.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

Widget _buildMyShopSection() {
  // Get shop picture with proper fallback
  String? shopPicture = _userData?['shop_picture'];
  
  // Debug print
  print('🖼️ Building my shop section with picture: $shopPicture');
  
  return Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToMyShop,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: (shopPicture != null && shopPicture.isNotEmpty)
                      ? NetworkImage(shopPicture)
                      : null,
                  onBackgroundImageError: (shopPicture != null && shopPicture.isNotEmpty)
                      ? (exception, stackTrace) {
                          print('❌ Error loading shop picture: $exception');
                        }
                      : null,
                  child: (shopPicture == null || shopPicture.isEmpty)
                      ? const Icon(Icons.store_rounded, color: Color(0xFFFF6B35), size: 32)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Your Shop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData?['shop_name'] ?? 'My Shop',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_myProducts.length} Products',
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCreateShopSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_outlined,
              size: 64,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start Selling Today',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your shop and reach thousands of customers',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createShop,
              icon: const Icon(Icons.add_business_rounded, color: Colors.white),
              label: const Text(
                'Create My Shop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final products = shop['products'] as List;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToShopDetail(shop),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF6B35), width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: shop['owner_picture'] != null
                            ? NetworkImage(shop['owner_picture'])
                            : null,
                        child: shop['owner_picture'] == null
                            ? const Icon(Icons.store_rounded, color: Color(0xFFFF6B35), size: 28)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop['shop_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${shop['product_count']} products',
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 200,
                padding: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length > 4 ? 4 : products.length,
                  itemBuilder: (context, productIndex) {
                    final product = products[productIndex];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                product['product_image'] ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['product_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${product['price'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyShopDetailPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<dynamic> myProducts;
  final VoidCallback onRefresh;

  const MyShopDetailPage({
    super.key,
    required this.userData,
    required this.myProducts,
    required this.onRefresh,
  });

  @override
  State<MyShopDetailPage> createState() => _MyShopDetailPageState();
}

class _MyShopDetailPageState extends State<MyShopDetailPage> {
  late List<dynamic> _products;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  final List<String> _categories = [
    'Electronics',
    'Fashion & Clothing',
    'Home & Living',
    'Books & Education',
    'Sports & Fitness',
    'Beauty & Health',
  ];

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.myProducts);
    _filteredProducts = List.from(_products);
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
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((product) {
          final productName = (product['product_name'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '').toString().toLowerCase();
          return productName.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    final result = await ProductService.getMyProducts();
    if (result['success']) {
      setState(() {
        _products = result['products'] ?? [];
        _onSearchChanged(_searchQuery);
      });
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Electronics':
        return '📱';
      case 'Fashion & Clothing':
        return '👕';
      case 'Home & Living':
        return '🏠';
      case 'Books & Education':
        return '📚';
      case 'Sports & Fitness':
        return '⚽️';
      case 'Beauty & Health':
        return '💄';
      default:
        return '🛍️';
    }
  }

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController();
    XFile? productImage;
    String? selectedCategory;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add New Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              setDialogState(() => productImage = image);
                            },
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: productImage == null
                                      ? Colors.grey[300]!
                                      : const Color(0xFFFF6B35),
                                  width: 2,
                                ),
                              ),
                              child: productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        File(productImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 40,
                                            color: Color(0xFFFF6B35),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tap to add product image',
                                          style: TextStyle(
                                            color: Color(0xFF2C3E50),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Required *',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Product Name *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: _buildInputDecoration(
                            hint: 'Enter product name',
                            icon: Icons.shopping_bag_rounded,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Category *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: _buildInputDecoration(
                            hint: 'Select category',
                            icon: Icons.category_rounded,
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text('${_getCategoryEmoji(cat)} $cat'),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategory = value),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Price *'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: priceController,
                                    decoration: _buildInputDecoration(
                                      hint: '0.00',
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Stock'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: stockController,
                                    decoration: _buildInputDecoration(hint: 'Optional'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Description'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descController,
                          decoration: _buildInputDecoration(
                            hint: 'Enter product description (optional)',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                          onPressed: () {
                            if (nameController.text.trim().isNotEmpty &&
                                priceController.text.trim().isNotEmpty &&
                                productImage != null &&
                                selectedCategory != null) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_rounded, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Please fill all required fields')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Product',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && productImage != null && selectedCategory != null) {
      final createResult = await ProductService.createProduct(
        productName: nameController.text.trim(),
        price: double.parse(priceController.text.trim()),
        category: selectedCategory!,
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        stock: stockController.text.trim().isEmpty ? null : int.parse(stockController.text.trim()),
        productImage: productImage!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  createResult['success'] ? Icons.check_circle_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    createResult['message'] ??
                        (createResult['success'] ? 'Product added!' : 'Failed to add product'),
                  ),
                ),
              ],
            ),
            backgroundColor: createResult['success'] ? Colors.green.shade400 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (createResult['success']) {
        await _loadProducts();
      }
    }
  }

  Future<void> _editProduct(dynamic product) async {
    final nameController = TextEditingController(text: product['product_name']);
    final priceController = TextEditingController(text: product['price'].toString());
    final descController = TextEditingController(text: product['description'] ?? '');
    final stockController = TextEditingController(text: product['stock'].toString());
    XFile? productImage;
    String? selectedCategory = product['category'] ?? _categories.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF5BA3F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Edit Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              setDialogState(() => productImage = image);
                            },
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF4A90E2), width: 2),
                              ),
                              child: productImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(File(productImage!.path), fit: BoxFit.cover),
                                    )
                                  : product['product_image'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(
                                            product['product_image'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stack) => const Center(
                                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add_photo_alternate_rounded,
                                                size: 40,
                                                color: Color(0xFF4A90E2),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Tap to change image',
                                              style: TextStyle(
                                                color: Color(0xFF2C3E50),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Product Name *'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: _buildInputDecoration(
                            hint: 'Enter product name',
                            icon: Icons.shopping_bag_rounded,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Category *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: _buildInputDecoration(
                            hint: 'Select category',
                            icon: Icons.category_rounded,
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text('${_getCategoryEmoji(cat)} $cat'),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategory = value),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Price *'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: priceController,
                                    decoration: _buildInputDecoration(
                                      hint: '0.00',
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Stock'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: stockController,
                                    decoration: _buildInputDecoration(hint: 'Optional'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Description'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descController,
                          decoration: _buildInputDecoration(
                            hint: 'Enter product description (optional)',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                            backgroundColor: const Color(0xFF4A90E2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Update',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final updateResult = await ProductService.updateProduct(
        productId: product['product_id'].toString(),
        productName: nameController.text.trim(),
        price: double.parse(priceController.text.trim()),
        category: selectedCategory ?? _categories.first,
        description: descController.text.trim(),
        stock: int.parse(stockController.text.trim()),
        productImage: productImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  updateResult['success'] ? Icons.check_circle_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    updateResult['message'] ??
                        (updateResult['success'] ? 'Product updated!' : 'Failed to update'),
                  ),
                ),
              ],
            ),
            backgroundColor: updateResult['success'] ? Colors.green.shade400 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (updateResult['success']) {
        await _loadProducts();
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
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
                'Delete Product',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this product? This action cannot be undone.',
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
                        'Delete',
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
      final result = await ProductService.deleteProduct(productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ??
                        (result['success'] ? 'Product deleted!' : 'Failed to delete product'),
                  ),
                ),
              ],
            ),
            backgroundColor: result['success'] ? Colors.green.shade400 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (result['success']) {
        await _loadProducts();
      }
    }
  }

  Future<void> _updateShop() async {
    final shopNameController = TextEditingController(text: widget.userData['shop_name'] ?? '');
    XFile? shopImage;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Shop',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      setDialogState(() => shopImage = image);
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                      ),
                      child: shopImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(shopImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : widget.userData['shop_picture'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    widget.userData['shop_picture'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.store_rounded,
                                            size: 40,
                                            color: Color(0xFFFF6B35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tap to change shop image',
                                      style: TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Shop Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: shopNameController,
                    decoration: _buildInputDecoration(
                      hint: 'Enter shop name',
                      icon: Icons.store_rounded,
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
                            'Update',
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
        ),
      ),
    );

    if (result == true) {
      final updateResult = await ShopService.updateShop(
        shopName: shopNameController.text.trim().isEmpty ? null : shopNameController.text.trim(),
        shopImage: shopImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  updateResult['success'] ? Icons.check_circle_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    updateResult['message'] ??
                        (updateResult['success'] ? 'Shop updated!' : 'Failed to update shop'),
                  ),
                ),
              ],
            ),
            backgroundColor: updateResult['success'] ? Colors.green.shade400 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (updateResult['success']) {
        widget.onRefresh();
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteShop() async {
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
                child: Icon(Icons.warning_rounded, size: 48, color: Colors.red.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Shop',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete your shop? All products will be permanently removed. This action cannot be undone.',
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
                        'Delete',
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
      final result = await ShopService.deleteShop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ??
                        (result['success'] ? 'Shop deleted!' : 'Failed to delete shop'),
                  ),
                ),
              ],
            ),
            backgroundColor: result['success'] ? Colors.green.shade400 : Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      if (result['success']) {
        widget.onRefresh();
        Navigator.pop(context);
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? icon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFFFF6B35)) : null,
      prefixText: prefixText,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildProductImage(String? imageUrl, {double? width, double? height}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(width, height);
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
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
                            widget.userData['shop_name'] ?? 'My Shop',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF2C3E50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'update',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Update Shop',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.delete_rounded,
                                        size: 18,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete Shop',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'update') _updateShop();
                              if (value == 'delete') _deleteShop();
                            },
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
                        hintText: 'Search your products...',
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
                            border: Border.all(color: const Color(0xFFFF6B35), width: 3),
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
                            backgroundImage: widget.userData['shop_picture'] != null
                                ? NetworkImage(widget.userData['shop_picture'])
                                : null,
                            backgroundColor: Colors.white,
                            child: widget.userData['shop_picture'] == null
                                ? const Icon(Icons.store, color: Color(0xFFFF6B35), size: 40)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userData['shop_name'] ?? 'My Shop',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_products.length} products',
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
                            _searchQuery.isNotEmpty ? 'No products found' : 'No products yet',
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
                                : 'Add your first product to start selling',
                            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final stock = product['stock'] ?? 0;
    final sold = product['sold'] ?? 0;

    return Container(
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                : 'Stock: $stock',
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _editProduct(product),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _deleteProduct(product['product_id'].toString()),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: BorderSide(color: Colors.red.shade400, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

// detail page of the shop
class ShopDetailPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ShopDetailPage({
    super.key,
    required this.shop,
  });

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
          final productName = (product['product_name'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '').toString().toLowerCase();
          return productName.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

Future<void> _addToCart(dynamic product) async {
  // Check if user is logged in first
  final isLoggedIn = await AuthService.isLoggedIn();
  
  if (!isLoggedIn) {
    _showLoginPrompt();
    return;
  }

  // Don't close the product detail sheet - just show loading dialog on top
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
    Navigator.pop(context); // Only close the loading dialog

    if (result['success']) {
      _showSuccessDialog(product);
    } else {
      _showErrorSnackbar(result['message'] ?? 'Failed to add to cart');
    }
  }
}

// Add this new method to _ShopDetailPageState:

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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    if (product['description'] != null && product['description'].toString().isNotEmpty)
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
                          color: (product['stock'] ?? 0) > 0 ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          (product['stock'] ?? 0) > 0 ? 'Add to Cart' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: (product['stock'] ?? 0) > 0 ? Colors.white : Colors.grey[600],
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

  Widget _buildProductImage(String? imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
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
                            border: Border.all(color: const Color(0xFFFF6B35), width: 3),
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
                            backgroundImage: widget.shop['owner_picture'] != null
                                ? NetworkImage(widget.shop['owner_picture'])
                                : null,
                            backgroundColor: Colors.white,
                            child: widget.shop['owner_picture'] == null
                                ? const Icon(Icons.store, color: Color(0xFFFF6B35), size: 40)
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B35),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 14),
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
                              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty ? 'No products found' : 'No products available',
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
                            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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