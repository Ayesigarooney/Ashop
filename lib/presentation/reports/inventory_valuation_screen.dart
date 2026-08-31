import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_helper.dart';
import '../../features/product/data/repositories/product_repository.dart';
import '../../features/settings/data/settings_repository.dart';

class InventoryValuationScreen extends StatelessWidget {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productRepo = context.read<ProductRepository>();
    final settings = context.read<SettingsRepository>();
    final currency = settings.currency;

    final products = productRepo.getAllProducts();
    double totalCost = 0;
    double totalRetail = 0;

    for (final p in products) {
      totalCost += p.costPrice * p.stockQuantity;
      totalRetail += p.sellingPrice * p.stockQuantity;
    }

    final potentialProfit = totalRetail - totalCost;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Valuation',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ValCard(
              title: 'Total Products',
              value: '${products.length}',
              icon: Icons.inventory_2_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            _ValCard(
              title: 'Cost Value',
              value: CurrencyFormatter.format(totalCost, currency: currency),
              icon: Icons.money_rounded,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 10),
            _ValCard(
              title: 'Retail Value',
              value: CurrencyFormatter.format(totalRetail, currency: currency),
              icon: Icons.sell_rounded,
              color: AppTheme.infoColor,
            ),
            const SizedBox(height: 10),
            _ValCard(
              title: 'Potential Profit',
              value: CurrencyFormatter.format(
                potentialProfit,
                currency: currency,
              ),
              icon: Icons.trending_up_rounded,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Products Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...products.map((p) {
              final costVal = p.costPrice * p.stockQuantity;
              final retailVal = p.sellingPrice * p.stockQuantity;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Qty: ${p.stockQuantity}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(costVal, currency: currency),
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            retailVal,
                            currency: currency,
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final csv = await ReportHelper.generateInventoryValuationCsv();
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/inventory_valuation.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Inventory Valuation');
  }
}

class _ValCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _ValCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
