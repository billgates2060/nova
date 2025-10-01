class Product {
  final int? id;
  final String name;
  final String? sku;
  final double? cost;
  final double price;
  final int stockQuantity;
  final int? lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.sku,
    this.cost,
    required this.price,
    required this.stockQuantity,
    this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'cost': cost,
      'price': price,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      cost: (map['cost'] as num?)?.toDouble(),
      price: map['price'].toDouble(),
      stockQuantity: map['stockQuantity'],
      lowStockThreshold: map['lowStockThreshold'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    double? cost,
    double? price,
    int? stockQuantity,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      cost: cost ?? this.cost,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
