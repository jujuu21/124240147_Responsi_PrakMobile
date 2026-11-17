import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_helper.dart';

class WishlistProvider extends ChangeNotifier {
  List<ProductModel> _wishlist = [];
  bool _isLoading = true;

  List<ProductModel> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  int get count => _wishlist.length;

  WishlistProvider() {
    loadWishlist();
  }

  // Load wishlist from Local SQLite Database
  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    _wishlist = await DatabaseHelper.instance.getWishlist();
    _isLoading = false;
    notifyListeners();
  }

  // Check if product is in wishlist
  bool isWishlist(int productId) {
    return _wishlist.any((item) => item.id == productId);
  }

  // Toggles wishlist item.
  // Returns TRUE if item was ADDED to wishlist.
  // Returns FALSE if item was REMOVED from wishlist.
  Future<bool> toggleWishlist(ProductModel product) async {
    final exists = isWishlist(product.id);
    if (exists) {
      await DatabaseHelper.instance.removeFromWishlist(product.id);
      _wishlist.removeWhere((item) => item.id == product.id);
      notifyListeners();
      return false; // Removed
    } else {
      await DatabaseHelper.instance.addToWishlist(product);
      _wishlist.insert(0, product);
      notifyListeners();
      return true; // Added
    }
  }

  // Remove by ID from Local Database
  Future<void> removeFromWishlist(int productId) async {
    await DatabaseHelper.instance.removeFromWishlist(productId);
    _wishlist.removeWhere((item) => item.id == productId);
    notifyListeners();
  }
}
