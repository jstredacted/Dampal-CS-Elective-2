class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.categoryId,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final int? categoryId;

  // Turns one row from the Supabase "products" table into a Product object.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? 'N/A',
      // Supabase sends numeric columns as int or double, so convert with num.
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      imageUrl: map['image_url'] as String? ?? '',
      categoryId: map['category_id'] as int?,
    );
  }

  // The columns we send when adding or updating. The id is left out because
  // Supabase creates it for new rows and we never change it.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'category_id': categoryId,
    };
  }

  // Creates a new Product with some values changed and the rest kept.
  Product copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    int? categoryId,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
