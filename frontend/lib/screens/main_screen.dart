import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'shop_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _selectedShopName;

  void _switchToCart() {
    setState(() => _currentIndex = 3);
  }

  void _switchToShop(String shopName) {
    setState(() {
      _selectedShopName = shopName;
      _currentIndex = 2; // Shop tab index
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onNavigateToCart: _switchToCart,
        onNavigateToShop: _switchToShop,
        onNavigateToShopTab: () => setState(() => _currentIndex = 2),
      ),
      const SearchPage(),
      ShopPage(
        key: ValueKey(_selectedShopName), // Force rebuild when shop changes
        shopName: _selectedShopName,
      ),
      const CartPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
                // Clear selected shop when navigating away from shop tab
                if (index != 2) _selectedShopName = null;
              });
            },
            height: 70,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFFF6B35).withOpacity(0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Color(0xFFFF6B35)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: Color(0xFFFF6B35)),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store, color: Color(0xFFFF6B35)),
                label: 'Shop',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFFFF6B35)),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: Color(0xFFFF6B35)),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}