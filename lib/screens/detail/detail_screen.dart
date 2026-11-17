import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final int productId;
  final ProductModel? initialProduct;

  const DetailScreen({super.key, required this.productId, this.initialProduct});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<ProductModel> _detailFuture;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();

    _detailFuture = ApiService.getProductDetail(widget.productId);
  }

  void _toggleWishlist(ProductModel product) async {
    final wishlistProvider = context.read<WishlistProvider>();
    final added = await wishlistProvider.toggleWishlist(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.title} berhasil ditambahkan ke Wishlist!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.remove_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('${product.title} dihapus dari Wishlist!')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductModel>(
      future: _detailFuture,
      initialData: widget.initialProduct,
      builder: (context, snapshot) {
        final product = snapshot.data;
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            product == null;
        final hasError = snapshot.hasError && product == null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              product != null ? product.title : 'Detail Produk',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (product != null)
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, _) {
                    final isInWishlist = wishlistProvider.isWishlist(
                      product.id,
                    );
                    return IconButton(
                      tooltip: isInWishlist
                          ? 'Hapus dari Wishlist'
                          : 'Tambah ke Wishlist',
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.red : Colors.grey.shade700,
                        size: 26,
                      ),
                      onPressed: () => _toggleWishlist(product),
                    );
                  },
                ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat detail produk...'),
                    ],
                  ),
                )
              : hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 54,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _detailFuture = ApiService.getProductDetail(
                                widget.productId,
                              );
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildDetailContent(product!),
          bottomNavigationBar: product != null
              ? _buildBottomActionBar(product)
              : null,
        );
      },
    );
  }

  Widget _buildDetailContent(ProductModel product) {
    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];
    final currentImage = _selectedImageIndex < images.length
        ? images[_selectedImageIndex]
        : '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Gambar Produk (Main preview)
          Container(
            height: 280,
            color: Colors.white,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'product-img-${product.id}',
                  child: Image.network(
                    currentImage,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                // Discount tag overlay
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'HEMAT ${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (images.length > 1)
            Container(
              height: 64,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedImageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImageIndex = index),
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Main product information card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori & Brand badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (product.brand != null &&
                            product.brand!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 13,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.brand!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Nama Produk
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Harga & Diskon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            '\$${(product.price / (1 - (product.discountPercentage / 100))).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(-${product.discountPercentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Rating & 5. Stok info
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.rating.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Informasi Stok
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: product.stock > 0
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                product.stock > 0
                                    ? Icons.inventory_2_outlined
                                    : Icons.remove_shopping_cart_outlined,
                                size: 16,
                                color: product.stock > 0
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.stock > 0
                                    ? 'Stok: ${product.stock} unit'
                                    : 'Stok Habis',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: product.stock > 0
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
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
            ),
          ),

          const SizedBox(height: 12),

          // 6. Deskripsi Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Sticky Bottom Action Bar with Wishlist Toggle Button
  Widget _buildBottomActionBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, _) {
            final isInWishlist = wishlistProvider.isWishlist(product.id);
            return Row(
              children: [
                // Wishlist Toggle Icon Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isInWishlist ? Colors.red : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: isInWishlist
                        ? 'Hapus dari Wishlist'
                        : 'Tambah ke Wishlist',
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : Colors.grey.shade700,
                      size: 24,
                    ),
                    onPressed: () => _toggleWishlist(product),
                  ),
                ),
                const SizedBox(width: 12),

                // Button CTA
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInWishlist
                          ? Colors.red.shade600
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _toggleWishlist(product),
                    icon: Icon(
                      isInWishlist
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isInWishlist
                          ? 'Hapus dari Wishlist'
                          : 'Tambah ke Wishlist',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
