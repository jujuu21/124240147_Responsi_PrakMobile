import 'package:flutter_test/flutter_test.dart';
import 'package:responsi/models/product_model.dart';
import 'package:responsi/models/user_model.dart';
import 'package:responsi/services/database_helper.dart';

void main() {
  group('ShoppingHub ProductModel Tests', () {
    test('ProductModel parses JSON from DummyJSON API correctly', () {
      final json = {
        'id': 1,
        'title': 'Essence Mascara Lash Princess',
        'description': 'A popular mascara known for volumizing lashes.',
        'category': 'beauty',
        'price': 9.99,
        'discountPercentage': 10.48,
        'rating': 2.56,
        'stock': 99,
        'brand': 'Essence',
        'thumbnail': 'https://cdn.dummyjson.com/product-images/beauty/1/thumbnail.webp',
        'images': [
          'https://cdn.dummyjson.com/product-images/beauty/1/1.webp',
        ],
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.category, 'beauty');
      expect(product.price, 9.99);
      expect(product.discountPercentage, 10.48);
      expect(product.rating, 2.56);
      expect(product.stock, 99);
      expect(product.brand, 'Essence');
      expect(product.thumbnail, 'https://cdn.dummyjson.com/product-images/beauty/1/thumbnail.webp');
      expect(product.images.length, 1);
    });

    test('ProductModel SQLite toMap and fromMap roundtrip correctly', () {
      final original = ProductModel(
        id: 10,
        title: 'Smartphone X',
        description: 'Flagship phone with great camera',
        category: 'smartphones',
        price: 799.99,
        discountPercentage: 15.0,
        rating: 4.8,
        stock: 45,
        brand: 'TechBrand',
        thumbnail: 'https://example.com/phone.png',
      );

      final map = original.toMap();
      final fromDb = ProductModel.fromMap(map);

      expect(fromDb.id, original.id);
      expect(fromDb.title, original.title);
      expect(fromDb.category, original.category);
      expect(fromDb.price, original.price);
      expect(fromDb.discountPercentage, original.discountPercentage);
      expect(fromDb.rating, original.rating);
      expect(fromDb.stock, original.stock);
      expect(fromDb.brand, original.brand);
      expect(fromDb.thumbnail, original.thumbnail);
    });
  });

  group('UserModel Tests', () {
    test('UserModel map roundtrip', () {
      final user = UserModel(id: 1, username: 'user', password: 'password123');
      final map = user.toMap();
      final reconstructed = UserModel.fromMap(map);

      expect(reconstructed.id, 1);
      expect(reconstructed.username, 'user');
      expect(reconstructed.password, 'password123');
    });

    test('DatabaseHelper registerUser test', () async {
      final uniqueUser = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
      final err = await DatabaseHelper.instance.registerUser(uniqueUser, 'pass');
      expect(err, isNull);
    });
  });
}
