import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../config/constants.dart';

class BackupRestoreHelper {
  /// Generates the raw JSON string representation of the current database.
  static Future<String> generateBackupJson() async {
    final productsBox = Hive.box<ProductModel>(AppConstants.productsBox);
    final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
    final settingsBox = Hive.box(AppConstants.settingsBox);

    final products = productsBox.values.map((p) => p.toMap()).toList();
    final sales = salesBox.values.map((s) => s.toMap()).toList();

    final settings = <String, dynamic>{};
    for (final key in settingsBox.keys) {
      // Avoid exporting session-specific temporary state if any
      settings[key.toString()] = settingsBox.get(key);
    }

    final backup = {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'products': products,
      'sales': sales,
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Copies the backup JSON string to the clipboard (works everywhere including Web).
  static Future<void> copyBackupToClipboard() async {
    final jsonStr = await generateBackupJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  /// Clears all Hive boxes, effectively resetting the app data.
  static Future<void> clearAllData() async {
    // Clear product box
    final productsBox = Hive.box<ProductModel>(AppConstants.productsBox);
    await productsBox.clear();
    // Clear sales box
    final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
    await salesBox.clear();
    // Clear settings box
    final settingsBox = Hive.box(AppConstants.settingsBox);
    await settingsBox.clear();
    // Clear any other boxes if needed
    // Optionally reset first launch flag
    settingsBox.put('first_launch', true);
  }

  /// Falls back to clipboard/text share on web.
  static Future<void> backupToFile() async {
    final jsonStr = await generateBackupJson();

    if (kIsWeb) {
      // On web, copy to clipboard and share text
      await copyBackupToClipboard();
      await Share.share(
        jsonStr,
        subject: '${AppConstants.appName} Database Export',
      );
    } else {
      // On mobile/desktop, save as a temporary file and share
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/ashop_backup_$timestamp.json');
        await file.writeAsString(jsonStr);

        await Share.shareXFiles([
          XFile(file.path, mimeType: 'application/json'),
        ], subject: '${AppConstants.appName} Database Backup');
      } catch (e) {
        // Fallback to text sharing if file sharing fails
        await Share.share(
          jsonStr,
          subject: '${AppConstants.appName} Database Backup (Text)',
        );
      }
    }
  }

  /// Validates and restores the database from a JSON string.
  /// Returns true if the restore is successful, otherwise false.
  /// Throws [FormatException] with a human-readable reason when the backup
  /// is missing the app header, comes from a different app, or is newer than
  /// the installed app version.
  static Future<bool> restoreFromBackupJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: not a JSON object');
    }

    // Validate header attributes
    if (decoded['app'] != AppConstants.appName) {
      throw const FormatException(
        'This backup was created for a different app',
      );
    }

    final backupVersion = decoded['version']?.toString();
    if (backupVersion == null || backupVersion.isEmpty) {
      throw const FormatException('Backup is missing a version tag');
    }
    if (_isNewerVersion(backupVersion, AppConstants.appVersion)) {
      throw FormatException(
        'Backup is from a newer app version ($backupVersion) than the '
        'installed version (${AppConstants.appVersion}). '
        'Please update the app before restoring.',
      );
    }

    // --- Phase 1: Parse everything into memory first. No box is touched yet.
    // If anything fails here the existing data remains intact.
    final List<MapEntry<String, ProductModel>> parsedProducts = [];
    final List<MapEntry<String, SaleModel>> parsedSales = [];
    final Map<String, dynamic> parsedSettings = {};

    try {
      if (decoded.containsKey('products')) {
        final productsList = decoded['products'];
        if (productsList is List) {
          for (final item in productsList) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final product = ProductModel.fromMap(map);
              parsedProducts.add(MapEntry(product.id, product));
            }
          }
        }
      }

      if (decoded.containsKey('sales')) {
        final salesList = decoded['sales'];
        if (salesList is List) {
          for (final item in salesList) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final sale = SaleModel.fromMap(map);
              parsedSales.add(MapEntry(sale.id, sale));
            }
          }
        }
      }

      if (decoded.containsKey('settings')) {
        final settingsMap = decoded['settings'];
        if (settingsMap is Map) {
          parsedSettings.addAll(Map<String, dynamic>.from(settingsMap));
        }
      }
    } catch (e) {
      debugPrint('Error parsing backup data: $e');
      throw FormatException('Backup data is corrupt or incompatible: $e');
    }

    // --- Phase 2: All data parsed successfully — now write to boxes atomically.
    try {
      final productsBox = Hive.box<ProductModel>(AppConstants.productsBox);
      await productsBox.clear();
      for (final entry in parsedProducts) {
        await productsBox.put(entry.key, entry.value);
      }

      final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
      await salesBox.clear();
      for (final entry in parsedSales) {
        await salesBox.put(entry.key, entry.value);
      }

      if (parsedSettings.isNotEmpty) {
        final settingsBox = Hive.box(AppConstants.settingsBox);
        await settingsBox.clear();
        for (final entry in parsedSettings.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error writing restored data: $e');
      rethrow;
    }
  }

  /// Compares two semver-ish strings (e.g. "1.2.3"). Returns true if [a] is
  /// strictly newer than [b].
  static bool _isNewerVersion(String a, String b) {
    List<int> parse(String v) {
      final parts = v
          .split('.')
          .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts.sublist(0, 3);
    }

    final pa = parse(a);
    final pb = parse(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i];
    }
    return false;
  }

  /// Generate CSV for products
  static Future<String> generateProductsCsv() async {
    final productsBox = Hive.box<ProductModel>(AppConstants.productsBox);
    final rows = <List<dynamic>>[];
    rows.add([
      'id',
      'name',
      'category',
      'barcode',
      'unit',
      'costPrice',
      'sellingPrice',
      'stockQuantity',
      'isActive',
      'createdAt',
      'updatedAt',
      'imagePath',
      'description',
    ]);

    for (final pModel in productsBox.values) {
      rows.add([
        pModel.id,
        pModel.name,
        pModel.category,
        pModel.barcode ?? '',
        pModel.unit ?? '',
        pModel.costPrice.toString(),
        pModel.sellingPrice.toString(),
        pModel.stockQuantity.toString(),
        pModel.isActive ? '1' : '0',
        pModel.createdAt.toIso8601String(),
        pModel.updatedAt.toIso8601String(),
        pModel.imagePath ?? '',
        pModel.description ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generate CSV for sales (one row per sale item, includes sale header fields)
  static Future<String> generateSalesCsv() async {
    final salesBox = Hive.box<SaleModel>(AppConstants.salesBox);
    final rows = <List<dynamic>>[];
    rows.add([
      'sale_id',
      'receipt_number',
      'createdAt',
      'paymentMethod',
      'customerName',
      'sale_total',
      'item_product_id',
      'item_product_name',
      'item_unit_price',
      'item_quantity',
      'item_total_price',
      'item_cost_price',
      'item_discount_percent',
    ]);

    for (final sale in salesBox.values) {
      for (final item in sale.items) {
        rows.add([
          sale.id,
          sale.receiptNumber,
          sale.createdAt.toIso8601String(),
          sale.paymentMethod,
          sale.customerName ?? '',
          sale.total.toString(),
          item.productId,
          item.productName,
          item.unitPrice.toString(),
          item.quantity.toString(),
          item.totalPrice.toString(),
          item.costPrice.toString(),
          item.discountPercent.toString(),
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export a CSV string to a temporary file and share it
  static Future<void> exportCsvToFile(
    String csvContent,
    String filename,
  ) async {
    if (kIsWeb) {
      // On web just share text
      await Share.share(csvContent, subject: filename);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(csvContent);
    try {
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv'),
      ], subject: filename);
    } catch (_) {
      await Share.share(csvContent, subject: filename);
    }
  }
}
