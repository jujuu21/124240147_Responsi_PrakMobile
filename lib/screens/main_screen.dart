import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'wishlist/wishlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari ShoppingHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistCount = context.watch<WishlistProvider>().count;

    final List<Widget> screens = [
      HomeScreen(
        onOpenWishlistTab: () {
          setState(() => _currentIndex = 1);
        },
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text(
            'Wishlist Saya',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'Keluar Akun',
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
        body: WishlistScreen(
          onBrowseProducts: () {
            setState(() => _currentIndex = 0);
          },
        ),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: wishlistCount > 0,
              label: Text('$wishlistCount'),
              child: const Icon(Icons.favorite_border),
            ),
            selectedIcon: Badge(
              isLabelVisible: wishlistCount > 0,
              label: Text('$wishlistCount'),
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
            label: 'Wishlist',
          ),
        ],
      ),
    );
  }
}
