import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/constants.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/sale/data/models/sale_model.dart';

class ReportHelper {
  static Future<String> generateInventoryValuationCsv() async {
    final productsBox = Hive.box<ProductModel>(AppConstants.productsBox);
    final rows = <List<dynamic>>[];
    rows.add(['product_id', 'name', 'qty', 'cost_price', 'value']);
    double totalValue = 0;
    for (final p in productsBox.values) {
      final value = p.stockQuantity * p.costPrice;
      totalValue += value;
      rows.add([p.id, p.name, p.stockQuantity, p.costPrice.toStringAsFixed(2), value.toStringAsFixed(2)]);
    }
    rows.add([]);
    rows.add(['', '', '', 'TOTAL', totalValue.toStringAsFixed(2)]);
    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> generateStockMovementCsv(DateTime start, DateTime end) async {
    final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
    final Map<String, Map<String, dynamic>> agg = {};

    for (final sale in salesBox.values) {
      if (sale.createdAt.isBefore(start) || sale.createdAt.isAfter(end)) continue;
      for (final item in sale.items) {
        final key = item.productId;
        final existing = agg[key];
        if (existing == null) {
          agg[key] = {
            'productName': item.productName,
            'sold': item.quantity,
            'revenue': item.totalPrice,
            'cost': item.costPrice * item.quantity,
          };
        } else {
          existing['sold'] = existing['sold'] + item.quantity;
          existing['revenue'] = existing['revenue'] + item.totalPrice;
          existing['cost'] = existing['cost'] + (item.costPrice * item.quantity);
        }
      }
    }

    final rows = <List<dynamic>>[];
    rows.add(['product_id', 'name', 'sold_qty', 'revenue', 'cost', 'profit']);
    agg.forEach((id, data) {
      final profit = (data['revenue'] as double) - (data['cost'] as double);
      rows.add([
        id,
        data['productName'],
        data['sold'],
        (data['revenue'] as double).toStringAsFixed(2),
        (data['cost'] as double).toStringAsFixed(2),
        profit.toStringAsFixed(2),
      ]);
    });

    return const ListToCsvConverter().convert(rows);
  }

  static Future<String> generateProfitLossCsv(DateTime start, DateTime end) async {
    final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
    double revenue = 0;
    double cost = 0;

    for (final sale in salesBox.values) {
      if (sale.createdAt.isBefore(start) || sale.createdAt.isAfter(end)) continue;
      revenue += sale.total;
      for (final item in sale.items) {
        cost += item.costPrice * item.quantity;
      }
    }

    final grossProfit = revenue - cost;

    final rows = <List<dynamic>>[];
    rows.add(['metric', 'value']);
    rows.add(['revenue', revenue.toStringAsFixed(2)]);
    rows.add(['cost_of_goods_sold', cost.toStringAsFixed(2)]);
    rows.add(['gross_profit', grossProfit.toStringAsFixed(2)]);

    return const ListToCsvConverter().convert(rows);
  }

  /// Convenience wrappers without date params (full history)
  static Future<String> generateAllInventoryCsv() => generateInventoryValuationCsv();

  static Future<String> generateAllProfitLossCsv() async {
    final start = DateTime.fromMillisecondsSinceEpoch(0);
    final end = DateTime.now().add(const Duration(days: 1));
    return generateProfitLossCsv(start, end);
  }

  static Future<String> generateAllStockMovementCsv() async {
    final start = DateTime.fromMillisecondsSinceEpoch(0);
    final end = DateTime.now().add(const Duration(days: 1));
    return generateStockMovementCsv(start, end);
  }

  static Future<void> exportCsv(String csvContent, String filename) async {
    if (kIsWeb) {
      await Share.share(csvContent, subject: filename);
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(csvContent);
    try {
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')], subject: filename);
    } catch (_) {
      await Share.share(csvContent, subject: filename);
    }
  }
}
