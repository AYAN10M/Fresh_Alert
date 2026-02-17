class InventoryItem {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final DateTime buyDate;
  final DateTime expiryDate;
  final int quantity;
  final String? location;
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
      isConsumed: map['isConsumed'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
