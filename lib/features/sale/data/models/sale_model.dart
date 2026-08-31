import 'package:hive/hive.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 1)
class SaleModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String receiptNumber;

  @HiveField(2)
  late List<SaleItemModel> items;

  @HiveField(3)
  late double subtotal;

  @HiveField(4)
  late double discountAmount;

  @HiveField(5)
  late double taxAmount;

  @HiveField(6)
  late double total;

  @HiveField(7)
  late double amountPaid;

  @HiveField(8)
  late double change;

  @HiveField(9)
  late String paymentMethod;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  String? customerName;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  bool isRefunded = false;

  @HiveField(14)
  DateTime? refundedAt;

  SaleModel({
    required this.id,
    required this.receiptNumber,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.createdAt,
    this.customerName,
    this.notes,
    this.isRefunded = false,
    this.refundedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'receipt_number': receiptNumber,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'tax_amount': taxAmount,
    'total': total,
    'amount_paid': amountPaid,
    'change': change,
    'payment_method': paymentMethod,
    'created_at': createdAt.toIso8601String(),
    'customer_name': customerName,
    'notes': notes,
    'is_refunded': isRefunded,
    'refunded_at': refundedAt?.toIso8601String(),
  };

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'],
      receiptNumber: map['receipt_number'],
      items: (map['items'] as List)
          .map((item) => SaleItemModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      paymentMethod: map['payment_method'],
      createdAt: DateTime.parse(map['created_at']),
      customerName: map['customer_name'],
      notes: map['notes'],
      isRefunded: map['is_refunded'] ?? false,
      refundedAt: map['refunded_at'] != null
          ? DateTime.parse(map['refunded_at'])
          : null,
    );
  }
}

@HiveType(typeId: 2)
class SaleItemModel extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String productName;

  @HiveField(2)
  late double unitPrice;

  @HiveField(3)
  late int quantity;

  @HiveField(4)
  late double totalPrice;

  @HiveField(5)
  double discountPercent = 0;

  @HiveField(6)
  String? note;

  @HiveField(7)
  late double costPrice;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.discountPercent = 0,
    this.note,
    required this.costPrice,
  });

  double get profit => (unitPrice - costPrice) * quantity;

  Map<String, dynamic> toMap() => {
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'total_price': totalPrice,
    'discount_percent': discountPercent,
    'note': note,
    'cost_price': costPrice,
  };

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      productId: map['product_id'],
      productName: map['product_name'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      totalPrice: (map['total_price'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0,
      note: map['note'],
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
