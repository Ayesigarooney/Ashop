import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_helper.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/sale/data/repositories/sale_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../order_history/order_history_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 7;
  late final VoidCallback _onSalesChanged;

  @override
  void initState() {
    super.initState();
    _onSalesChanged = () => setState(() {});
    Hive.box<SaleModel>(AppConstants.salesBox).listenable().addListener(_onSalesChanged);
  }

  @override
  void dispose() {
    Hive.box<SaleModel>(AppConstants.salesBox).listenable().removeListener(_onSalesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saleRepo = context.read<SaleRepository>();
    final settings = context.read<SettingsRepository>();
    final currency = settings.currency;

    final revenueData = saleRepo.getRevenueByDay(_selectedPeriod);
    final topProducts = saleRepo.getTopProducts(limit: 5);
    final paymentMethods = saleRepo.getRevenueByPaymentMethod();
    final allSales = saleRepo.getSalesInRange(
      DateTime.now().subtract(Duration(days: _selectedPeriod)),
      DateTime.now(),
    );
    final totalRevenue = allSales.where((s) => !s.isRefunded).fold(0.0, (s, sale) => s + sale.total);
    final totalProfit = allSales.where((s) => !s.isRefunded).fold(
        0.0, (s, sale) => s + sale.items.fold(0.0, (a, i) => a + i.profit));
    final totalTransactions = allSales.where((s) => !s.isRefunded).length;
    final avgOrder = totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('History'),
            onPressed: () => context.push('/order-history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [7, 14, 30, 90].map((d) {
                  final selected = _selectedPeriod == d;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8, bottom: 16, top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        d == 7 ? '7 days' : d == 14 ? '14 days' : d == 30 ? '30 days' : '90 days',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                StatCard(
                  title: 'Revenue',
                  value: CurrencyFormatter.formatCompact(totalRevenue, currency: currency),
                  icon: Icons.payments_rounded,
                  color: AppTheme.primaryColor,
                ),
                StatCard(
                  title: 'Profit',
                  value: CurrencyFormatter.formatCompact(totalProfit, currency: currency),
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.successColor,
                ),
                StatCard(
                  title: 'Transactions',
                  value: '$totalTransactions',
                  icon: Icons.receipt_long_rounded,
                  color: AppTheme.infoColor,
                ),
                StatCard(
                  title: 'Avg. Order',
                  value: CurrencyFormatter.formatCompact(avgOrder, currency: currency),
                  icon: Icons.shopping_cart_rounded,
                  color: AppTheme.accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Revenue Chart
            SectionHeader(title: 'Revenue Trend'),
            const SizedBox(height: 12),
            Container(
              height: 190,
              padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: revenueData.isEmpty || revenueData.values.every((v) => v == 0)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              size: 36, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 8),
                          Text(
                            'No data for this period',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getChartInterval(revenueData),
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.colorScheme.onSurface.withOpacity(0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, _) => Text(
                                CurrencyFormatter.formatCompact(v, currency: ''),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (_selectedPeriod / 5).ceilToDouble(),
                              getTitlesWidget: (v, _) {
                                final keys = revenueData.keys.toList();
                                final idx = v.toInt();
                                if (idx >= 0 && idx < keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      keys[idx],
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: revenueData.entries.toList().asMap().entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                                .toList(),
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.18),
                                  AppTheme.primaryColor.withOpacity(0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Export & Reports Section
            SectionHeader(title: 'Export & Reports'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _ReportActionTile(
                    icon: Icons.assessment_rounded,
                    title: 'Profit & Loss Report',
                    subtitle: 'View detailed profit/loss with date range',
                    onTap: () => context.push('/reports/profit-loss'),
                  ),
                  const Divider(height: 1),
                  _ReportActionTile(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory Valuation',
                    subtitle: 'View stock value and potential profit',
                    onTap: () => context.push('/reports/inventory-valuation'),
                  ),
                  const Divider(height: 1),
                  _ReportActionTile(
                    icon: Icons.download_rounded,
                    title: 'Export Inventory CSV',
                    subtitle: 'Download inventory valuation report',
                    onTap: () => _exportInventoryCsv(context),
                  ),
                  const Divider(height: 1),
                  _ReportActionTile(
                    icon: Icons.download_rounded,
                    title: 'Export P&L CSV',
                    subtitle: 'Download profit & loss report',
                    onTap: () => _exportProfitLossCsv(context),
                  ),
                  const Divider(height: 1),
                  _ReportActionTile(
                    icon: Icons.download_rounded,
                    title: 'Export Stock Movement CSV',
                    subtitle: 'Download stock movement report',
                    onTap: () => _exportStockMovementCsv(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Products
            if (topProducts.isNotEmpty) ...[
              SectionHeader(title: 'Top Selling Products'),
              const SizedBox(height: 12),
              ...topProducts.entries.toList().asMap().entries.map((e) {
                final rank = e.key + 1;
                final name = e.value.key;
                final qty = e.value.value;
                final maxQty = topProducts.values.first;
                return _TopProductTile(
                  rank: rank,
                  name: name,
                  qty: qty,
                  progress: maxQty > 0 ? qty / maxQty : 0,
                );
              }),
              const SizedBox(height: 24),
            ],

            // Payment Methods
            if (paymentMethods.isNotEmpty) ...[
              SectionHeader(title: 'Revenue by Payment Method'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  children: paymentMethods.entries.map((e) {
                    final percent = totalRevenue > 0 ? e.value / totalRevenue : 0.0;
                    final colors = [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                      AppTheme.infoColor,
                      AppTheme.warningColor,
                    ];
                    final colorIdx = paymentMethods.keys.toList().indexOf(e.key) % colors.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(percent * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors[colorIdx],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: colors[colorIdx].withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation(colors[colorIdx]),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                CurrencyFormatter.formatCompact(e.value, currency: currency),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getChartInterval(Map<String, double> data) {
    if (data.isEmpty) return 1000;
    final max = data.values.fold(0.0, (a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    return (max / 4).ceilToDouble();
  }

  Future<void> _exportInventoryCsv(BuildContext context) async {
    try {
      final csv = await ReportHelper.generateAllInventoryCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inventory_valuation.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Inventory Valuation Report');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export inventory CSV')),
      );
    }
  }

  Future<void> _exportProfitLossCsv(BuildContext context) async {
    try {
      final csv = await ReportHelper.generateAllProfitLossCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/profit_loss.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Profit & Loss Report');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export profit & loss CSV')),
      );
    }
  }

  Future<void> _exportStockMovementCsv(BuildContext context) async {
    try {
      final csv = await ReportHelper.generateAllStockMovementCsv();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/stock_movement.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Stock Movement Report');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export stock movement CSV')),
      );
    }
  }
}

class _ReportActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final String name;
  final int qty;
  final double progress;

  const _TopProductTile({
    required this.rank,
    required this.name,
    required this.qty,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.warningColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? AppTheme.warningColor : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$qty sold',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
