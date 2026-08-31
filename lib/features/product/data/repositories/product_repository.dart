import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../../../../core/config/constants.dart';

class ProductRepository {
  Box<ProductModel> get _box => Hive.box<ProductModel>(AppConstants.productsBox);
  final _uuid = const Uuid();

  List<ProductModel> getAllProducts() {
    return _box.values.where((p) => p.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<ProductModel> searchProducts(String query) {
    final q = query.toLowerCase();
    return _box.values.where((p) =>
        p.isActive &&
        (p.name.toLowerCase().contains(q) ||
            (p.barcode?.contains(q) ?? false) ||
            p.category.toLowerCase().contains(q))).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProductModel? getProductByBarcode(String barcode) {
    try {
      return _box.values.firstWhere((p) => p.barcode == barcode && p.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<ProductModel> addProduct({
    required String name,
    required double sellingPrice,
    required double costPrice,
    required int stockQuantity,
    required String category,
    String? barcode,
    String? description,
    String? imagePath,
    String? unit,
  }) async {
    final product = ProductModel(
      id: _uuid.v4(),
      name: name,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      stockQuantity: stockQuantity,
      category: category,
      barcode: barcode,
      description: description,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unit: unit,
    );
    await _box.put(product.id, product);
    return product;
  }

  Future<void> updateProduct(ProductModel product) async {
    product.updatedAt = DateTime.now();
    await _box.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    final product = getProductById(id);
    if (product != null) {
      product.isActive = false;
      product.updatedAt = DateTime.now();
      await _box.put(id, product);
    }
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    final product = getProductById(productId);
    if (product != null) {
      final newQty = product.stockQuantity + quantityChange;
      // Never allow stock to go negative
      if (newQty < 0) {
        throw Exception(
          'Insufficient stock for ${product.name}. '
          'Available: ${product.stockQuantity}, Requested: ${-quantityChange}',
        );
      }
      product.stockQuantity = newQty;
      product.updatedAt = DateTime.now();
      await _box.put(product.id, product);
    }
  }

  List<ProductModel> getLowStockProducts({int threshold = 5}) {
    return _box.values
        .where((p) => p.isActive && p.stockQuantity <= threshold && p.stockQuantity > 0)
        .toList();
  }

  List<ProductModel> getOutOfStockProducts() {
    return _box.values.where((p) => p.isActive && p.stockQuantity <= 0).toList();
  }

  List<String> getCategories() {
    final cats = _box.values
        .where((p) => p.isActive)
        .map((p) => p.category)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<ProductModel> getProductsByCategory(String category) {
    return _box.values
        .where((p) => p.isActive && p.category == category)
        .toList();
  }
}
