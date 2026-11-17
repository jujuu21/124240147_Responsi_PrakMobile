class ProductModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String? brand;
  final String thumbnail;
  final List<String> images;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    this.brand,
    required this.thumbnail,
    this.images = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<String> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages.map((e) => e.toString()).toList();
    }

    return ProductModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String?,
      thumbnail: json['thumbnail'] as String? ??
          (imagesList.isNotEmpty ? imagesList.first : ''),
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'thumbnail': thumbnail,
      'images': images,
    };
  }

  // SQLite map serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'thumbnail': thumbnail,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (map['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      brand: map['brand'] as String?,
      thumbnail: map['thumbnail'] as String? ?? '',
      images: map['thumbnail'] != null && (map['thumbnail'] as String).isNotEmpty
          ? [map['thumbnail'] as String]
          : [],
    );
  }
}
