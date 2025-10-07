class Sale {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime saleDate;
  final DateTime createdAt;
  final int? clientId;
  final String? clientName;

  Sale({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
    required this.createdAt,
    this.clientId,
    this.clientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'saleDate': saleDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'].toDouble(),
      totalPrice: map['totalPrice'].toDouble(),
      saleDate: DateTime.fromMillisecondsSinceEpoch(map['saleDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Sale copyWith({
    int? id,
    int? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? saleDate,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      saleDate: saleDate ?? this.saleDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
