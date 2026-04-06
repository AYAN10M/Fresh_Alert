import 'dart:convert';
import 'package:http/http.dart' as http;

/// Data class for product info fetched from Open Food Facts.
class ProductInfo {
  final String name;
  final String? brand;
  final String? category;
  final String? quantity;
  final String? imageUrl;

  const ProductInfo({
    required this.name,
    this.brand,
    this.category,
    this.quantity,
    this.imageUrl,
  });
}

class OpenFoodFactsService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// Map Open Food Facts category tags → app categories.
  /// Returns the best-matching category from the app's list, or null.
  static String? _mapCategory(List<dynamic>? tags) {
    if (tags == null || tags.isEmpty) return null;

    // Join all tags into a single lowercase string for easy matching
    final joined = tags.map((t) => t.toString().toLowerCase()).join(',');

    if (joined.contains('dairy') ||
        joined.contains('milk') ||
        joined.contains('cheese') ||
        joined.contains('yogurt') ||
        joined.contains('butter') ||
        joined.contains('cream')) {
      return 'Dairy';
    }
    if (joined.contains('vegetable') || joined.contains('legume')) {
      return 'Vegetables';
    }
    if (joined.contains('fruit') && !joined.contains('fruit-juice')) {
      return 'Fruits';
    }
    if (joined.contains('meat') ||
        joined.contains('poultry') ||
        joined.contains('fish') ||
        joined.contains('seafood')) {
      return 'Meat';
    }
    if (joined.contains('beverage') ||
        joined.contains('drink') ||
        joined.contains('juice') ||
        joined.contains('water') ||
        joined.contains('soda')) {
      return 'Beverages';
    }
    if (joined.contains('snack') ||
        joined.contains('chip') ||
        joined.contains('crisp') ||
        joined.contains('cookie') ||
        joined.contains('biscuit') ||
        joined.contains('candy') ||
        joined.contains('chocolate') ||
        joined.contains('sweet')) {
      return 'Snacks';
    }

    return null;
  }

  /// Fetches product info for a given barcode.
  /// Returns null if the product is not found or network fails.
  static Future<ProductInfo?> fetchProduct(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(uri, headers: {
        'User-Agent': 'FreshAlert/1.0 (Flutter; contact@freshalert.app)',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['status'] != 1) return null;

      final product = json['product'];
      if (product == null) return null;

      // Extract product name — try multiple fields
      final name = product['product_name_en'] ??
          product['product_name'] ??
          product['generic_name_en'] ??
          product['generic_name'];

      if (name == null || (name as String).trim().isEmpty) return null;

      // Extract brand
      final brand = product['brands'] as String?;

      // Build display name: "Brand - Product" or just "Product"
      String displayName = name.trim();
      if (brand != null && brand.trim().isNotEmpty) {
        final brandClean = brand.split(',').first.trim(); // first brand only
        // Avoid duplicating brand if it's already in the product name
        if (!displayName.toLowerCase().contains(brandClean.toLowerCase())) {
          displayName = '$brandClean $displayName';
        }
      }

      // Map category
      final categoryTags =
          product['categories_tags'] as List<dynamic>? ??
          (product['categories'] != null
              ? [product['categories']]
              : null);
      final category = _mapCategory(categoryTags);

      // Quantity string
      final quantity = product['quantity'] as String?;

      // Image
      final imageUrl = product['image_front_small_url'] as String?;

      return ProductInfo(
        name: displayName,
        brand: brand,
        category: category,
        quantity: quantity,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
