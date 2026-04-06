class InventoryItem {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final DateTime buyDate;
  final DateTime expiryDate;
  final int quantity;
  final String? location;
  final String? imageUrl;
  final bool isConsumed;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.buyDate,
    required this.expiryDate,
    required this.quantity,
    required this.createdAt,
    this.barcode,
    this.category,
    this.location,
    this.imageUrl,
    this.isConsumed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'buyDate': buyDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'location': location,
      'imageUrl': imageUrl,
      'isConsumed': isConsumed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      category: map['category'],
      buyDate: DateTime.parse(map['buyDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      quantity: map['quantity'],
      location: map['location'],
      imageUrl: map['imageUrl'],
      isConsumed: map['isConsumed'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? category,
    DateTime? buyDate,
    DateTime? expiryDate,
    int? quantity,
    String? location,
    String? imageUrl,
    bool? isConsumed,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      buyDate: buyDate ?? this.buyDate,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isConsumed: isConsumed ?? this.isConsumed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
