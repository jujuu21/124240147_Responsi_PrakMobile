import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service.dart';
import '../detail/detail_screen.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenWishlistTab;

  const HomeScreen({super.key, this.onOpenWishlistTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoadingProducts = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = ['All', ...categories];
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProducts({String? category}) async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      List<ProductModel> results;
      final targetCategory = category ?? _selectedCategory;

      if (targetCategory == 'All') {
        results = await ApiService.getProducts(limit: 30);
      } else {
        results = await ApiService.getProductsByCategory(targetCategory);
      }

      if (!mounted) return;
      setState(() {
        _products = results;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _loadProducts();
      return;
    }

    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.searchProducts(query);
      if (!mounted) return;
      setState(() {
        _products = results;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });
    _loadProducts(category: category);
  }

  void _goToWishlist() {
    if (widget.onOpenWishlistTab != null) {
      widget.onOpenWishlistTab!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Wishlist Saya')),
            body: const WishlistScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthProvider>().username ?? 'Pengguna';
    final wishlistCount = context.watch<WishlistProvider>().count;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ShoppingHub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Halo, $username ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Halaman Wishlist',
                icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                onPressed: _goToWishlist,
              ),
              if (wishlistCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      wishlistCount > 99 ? '99+' : '$wishlistCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari ShoppingHub?',
                  ),
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
                        await context.read<AuthProvider>().logout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadCategories();
          await _loadProducts();
        },
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _searchProducts,
                onChanged: (val) {
                  if (val.isEmpty) _loadProducts();
                },
              ),
            ),

            _buildCategoryFilterList(),

            Expanded(child: _buildProductContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterList() {
    if (_isLoadingCategories && _categories.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(
              category == 'All'
                  ? 'Semua'
                  : category
                        .replaceAll('-', ' ')
                        .split(' ')
                        .map(
                          (w) => w.isNotEmpty
                              ? '${w[0].toUpperCase()}${w.substring(1)}'
                              : '',
                        )
                        .join(' '),
            ),
            selected: isSelected,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
            onSelected: (_) => _onCategorySelected(category),
          );
        },
      ),
    );
  }

  Widget _buildProductContent() {
    if (_isLoadingProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Mengambil data produk...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadProducts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada produk yang ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailScreen(productId: product.id, initialProduct: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Hero(
                      tag: 'product-img-${product.id}',
                      child: Image.network(
                        product.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                                size: 36,
                              ),
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Discount tag if any
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Quick Wishlist button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, _) {
                        final isWish = wishlistProvider.isWishlist(product.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: isWish
                                ? 'Hapus dari Wishlist'
                                : 'Tambah ke Wishlist',
                            icon: Icon(
                              isWish ? Icons.favorite : Icons.favorite_border,
                              color: isWish ? Colors.red : Colors.grey.shade600,
                            ),
                            onPressed: () async {
                              final added = await wishlistProvider
                                  .toggleWishlist(product);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? '${product.title} ditambahkan ke Wishlist!'
                                        : '${product.title} dihapus dari Wishlist!',
                                  ),
                                  backgroundColor: added
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Product Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori
                        Text(
                          product.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Nama Produk
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),

                    // Harga & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Harga
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
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
