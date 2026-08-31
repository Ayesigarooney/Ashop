import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_helper.dart';
import '../../features/sale/data/repositories/sale_repository.dart';
import '../../features/settings/data/settings_repository.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saleRepo = context.read<SaleRepository>();
    final settings = context.read<SettingsRepository>();
    final currency = settings.currency;

    final allSales = saleRepo.getSalesInRange(_startDate, _endDate).where((s) => !s.isRefunded).toList();
    final totalRevenue = allSales.fold(0.0, (s, sale) => s + sale.total);
    final totalCost = allSales.fold(0.0, (s, sale) => s + sale.items.fold(0.0, (a, i) => a + i.costPrice * i.quantity));
    final grossProfit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profit & Loss', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
            _DateRangeSelector(
              startDate: _startDate,
              endDate: _endDate,
              onChanged: (start, end) => setState(() {
                _startDate = start;
                _endDate = end;
              }),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              title: 'Total Revenue',
              value: CurrencyFormatter.format(totalRevenue, currency: currency),
              icon: Icons.trending_up_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              title: 'Cost of Goods Sold',
              value: CurrencyFormatter.format(totalCost, currency: currency),
              icon: Icons.shopping_cart_rounded,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              title: 'Gross Profit',
              value: CurrencyFormatter.format(grossProfit, currency: currency),
              icon: Icons.account_balance_wallet_rounded,
              color: grossProfit >= 0 ? AppTheme.successColor : AppTheme.dangerColor,
            ),
            const SizedBox(height: 10),
            _SummaryCard(
              title: 'Profit Margin',
              value: '${profitMargin.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              color: AppTheme.infoColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Transactions: ${allSales.length}',
              style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            if (allSales.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Transactions',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...allSales.take(10).map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.receiptNumber, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${s.items.length} items', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(s.total, currency: currency),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final csv = await ReportHelper.generateProfitLossCsv(_startDate, _endDate);
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/profit_loss.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: 'Profit & Loss Report');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onChanged;

  const _DateRangeSelector({required this.startDate, required this.endDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'From',
            date: startDate,
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) onChanged(d, endDate);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: 'To',
            date: endDate,
            onTap: () async {
              // firstDate is constrained to startDate so endDate can never be before startDate
              final d = await showDatePicker(
                context: context,
                initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                firstDate: startDate,
                lastDate: DateTime.now(),
              );
              if (d != null) onChanged(startDate, d);
            },
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

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
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
