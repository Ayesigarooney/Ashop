import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double sellingPrice;

  @HiveField(3)
  late double costPrice;

  @HiveField(4)
  late int stockQuantity;

  @HiveField(5)
  late String category;

  @HiveField(6)
  String? barcode;

  @HiveField(7)
  String? description;

  @HiveField(8)
  String? imagePath;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late DateTime updatedAt;

  @HiveField(11)
  bool isActive = true;

  @HiveField(12)
  String? unit;

  ProductModel({
    required this.id,
    required this.name,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.category,
    this.barcode,
    this.description,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.unit,
  });

  double get profit => sellingPrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;

  /// Low stock is evaluated against the shop's configurable threshold.
  /// Callers should pass the value from SettingsRepository.lowStockThreshold.
  bool isLowStock({int threshold = 5}) =>
      stockQuantity <= threshold && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;

  ProductModel copyWith({
    String? id,
    String? name,
    double? sellingPrice,
    double? costPrice,
    int? stockQuantity,
    String? category,
    String? barcode,
    String? description,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'category': category,
      'barcode': barcode,
      'description': description,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'unit': unit,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      sellingPrice: (map['selling_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'] as int,
      category: map['category'] ?? 'General',
      barcode: map['barcode'],
      description: map['description'],
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] ?? true,
      unit: map['unit'],
    );
  }
}
