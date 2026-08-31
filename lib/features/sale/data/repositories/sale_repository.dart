import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_model.dart';
import '../../../../core/config/constants.dart';
import '../../../product/data/repositories/product_repository.dart';

class SaleRepository {
  Box<SaleModel> get _box => Hive.box<SaleModel>(AppConstants.salesBox);
  final _uuid = const Uuid();

  String _generateReceiptNumber() {
    final now = DateTime.now();
    const prefix = 'ASH';
    final date =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    // Monotonic counter persisted in settings — immune to deletions/refunds
    final settingsBox = Hive.box(AppConstants.settingsBox);
    final next =
        settingsBox.get(AppConstants.receiptCounterKey, defaultValue: 1) as int;
    settingsBox.put(AppConstants.receiptCounterKey, next + 1);
    final seq = next.toString().padLeft(4, '0');
    return '$prefix-$date-$seq';
  }

  List<SaleModel> getAllSales() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SaleModel> getSalesByDate(DateTime date) {
    return _box.values.where((s) {
      return s.createdAt.year == date.year &&
          s.createdAt.month == date.month &&
          s.createdAt.day == date.day;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SaleModel> getSalesInRange(DateTime start, DateTime end) {
    // Inclusive of both start and end day, using midnight boundaries
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(
      end.year,
      end.month,
      end.day,
    ).add(const Duration(days: 1));
    return _box.values.where((s) {
      return !s.createdAt.isBefore(startDay) && s.createdAt.isBefore(endDay);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SaleModel> getTodaySales() => getSalesByDate(DateTime.now());

  SaleModel? getSaleById(String id) {
    try {
      return _box.values.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<SaleModel> completeSale({
    required List<SaleItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double total,
    required double amountPaid,
    required double change,
    required String paymentMethod,
    String? customerName,
    String? notes,
  }) async {
    final sale = SaleModel(
      id: _uuid.v4(),
      receiptNumber: _generateReceiptNumber(),
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      total: total,
      amountPaid: amountPaid,
      change: change,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      customerName: customerName,
      notes: notes,
    );
    await _box.put(sale.id, sale);
    return sale;
  }

  Future<void> refundSale(
    String saleId,
    ProductRepository productRepository,
  ) async {
    final sale = getSaleById(saleId);
    if (sale == null || sale.isRefunded) return;
    // Restore stock for every item in the sale (best-effort per item)
    for (final item in sale.items) {
      try {
        await productRepository.updateStock(item.productId, item.quantity);
      } catch (_) {
        // If product was deleted, skip silently
      }
    }
    sale.isRefunded = true;
    sale.refundedAt = DateTime.now();
    await _box.put(sale.id, sale);
  }

  // Analytics
  double getTodayRevenue() {
    return getTodaySales()
        .where((s) => !s.isRefunded)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  double getTodayProfit() {
    return getTodaySales()
        .where((s) => !s.isRefunded)
        .fold(
          0.0,
          (sum, s) =>
              sum + s.items.fold(0.0, (iSum, item) => iSum + item.profit),
        );
  }

  int getTodayTransactionCount() {
    return getTodaySales().where((s) => !s.isRefunded).length;
  }

  Map<String, double> getRevenueByDay(int days) {
    final result = <String, double>{};
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = '${date.month}/${date.day}';
      final daySales = getSalesByDate(date).where((s) => !s.isRefunded);
      result[key] = daySales.fold(0.0, (sum, s) => sum + s.total);
    }
    return result;
  }

  Map<String, int> getTopProducts({int limit = 10}) {
    final productSales = <String, int>{};
    for (final sale in _box.values.where((s) => !s.isRefunded)) {
      for (final item in sale.items) {
        productSales[item.productName] =
            (productSales[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  Map<String, double> getRevenueByPaymentMethod() {
    final result = <String, double>{};
    for (final sale in _box.values.where((s) => !s.isRefunded)) {
      result[sale.paymentMethod] =
          (result[sale.paymentMethod] ?? 0) + sale.total;
    }
    return result;
  }
}
