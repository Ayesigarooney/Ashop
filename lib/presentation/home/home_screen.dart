import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/sale/data/repositories/sale_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SaleRepository _saleRepo;
  late SettingsRepository _settingsRepo;
  late final VoidCallback _onSalesChanged;
  late final VoidCallback _onProductsChanged;

  @override
  void initState() {
    super.initState();
    _onSalesChanged = () => setState(() {});
    _onProductsChanged = () => setState(() {});
    Hive.box<SaleModel>(AppConstants.salesBox).listenable().addListener(_onSalesChanged);
    Hive.box<ProductModel>(AppConstants.productsBox).listenable().addListener(_onProductsChanged);
  }

  @override
  void dispose() {
    Hive.box<SaleModel>(AppConstants.salesBox).listenable().removeListener(_onSalesChanged);
    Hive.box<ProductModel>(AppConstants.productsBox).listenable().removeListener(_onProductsChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _saleRepo = context.read<SaleRepository>();
    _settingsRepo = context.read<SettingsRepository>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = _settingsRepo.currency;
    final shopName = _settingsRepo.shopName;

    final todayRevenue = _saleRepo.getTodayRevenue();
    final todayProfit = _saleRepo.getTodayProfit();
    final todayCount = _saleRepo.getTodayTransactionCount();
    final weekData = _saleRepo.getRevenueByDay(7);
    final weekRevenue = weekData.values.fold(0.0, (a, b) => a + b);

    final lowStock = context.read<ProductCubit>().getLowStockProducts(
        threshold: _settingsRepo.lowStockThreshold);
    final outOfStock = context.read<ProductCubit>().getOutOfStockProducts();
    final todaySales = _saleRepo.getTodaySales();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(isDark ? 0.12 : 0.08),
                      AppTheme.accentColor.withOpacity(isDark ? 0.04 : 0.03),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Good ${_getGreeting()} 👋',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                shopName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormatter.formatDate(DateTime.now()),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                         Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _settingsRepo.shopLogo != null && File(_settingsRepo.shopLogo!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_settingsRepo.shopLogo!),
                                    fit: BoxFit.cover,
                                    width: 46,
                                    height: 46,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    shopName.isNotEmpty ? shopName[0].toUpperCase() : 'A',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Today's Revenue Banner
                GradientCard(
                  gradient: AppTheme.primaryGradient,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Revenue",
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(todayRevenue, currency: currency),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: AppTheme.accentColor, size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Profit: ${CurrencyFormatter.format(todayProfit, currency: currency)}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$todayCount sales',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    StatCard(
                      title: 'This Week',
                      value: CurrencyFormatter.formatCompact(weekRevenue, currency: currency),
                      subtitle: 'Revenue',
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.infoColor,
                    ),
                    StatCard(
                      title: 'Products',
                      value: _getTotalProducts(context).toString(),
                      subtitle: 'In catalog',
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.accentColor,
                    ),
                    StatCard(
                      title: 'Low Stock',
                      value: lowStock.length.toString(),
                      subtitle: lowStock.isEmpty ? 'All good!' : 'Need restock',
                      icon: Icons.warning_amber_rounded,
                      color: lowStock.isEmpty ? AppTheme.successColor : AppTheme.warningColor,
                      onTap: lowStock.isNotEmpty ? () => AppShell.of(context)?.navigateTo(2) : null,
                    ),
                    StatCard(
                      title: 'Out of Stock',
                      value: outOfStock.length.toString(),
                      subtitle: outOfStock.isEmpty ? 'All good!' : 'Unavailable',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: outOfStock.isEmpty ? AppTheme.successColor : AppTheme.dangerColor,
                      onTap: outOfStock.isNotEmpty ? () => AppShell.of(context)?.navigateTo(2) : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions
                SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.point_of_sale_rounded,
                        label: 'New Sale',
                        color: AppTheme.primaryColor,
                        onTap: () => AppShell.of(context)?.navigateTo(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_box_rounded,
                        label: 'Add Product',
                        color: AppTheme.accentColor,
                        onTap: () => AppShell.of(context)?.navigateTo(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'History',
                        color: AppTheme.infoColor,
                        onTap: () => _openOrderHistory(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        color: AppTheme.warningColor,
                        onTap: () => AppShell.of(context)?.navigateTo(3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Low Stock Alerts
                if (lowStock.isNotEmpty || outOfStock.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Stock Alerts',
                    action: 'View All',
                    onAction: () => AppShell.of(context)?.navigateTo(2),
                  ),
                  const SizedBox(height: 12),
                  ...[...outOfStock.take(2), ...lowStock.take(2)].map((product) =>
                      _StockAlertTile(
                        name: product.name,
                        qty: product.stockQuantity,
                        isOut: product.isOutOfStock,
                      )),
                  const SizedBox(height: 8),
                ],

                // Recent Sales
                SectionHeader(
                  title: 'Recent Sales',
                  action: 'View All',
                  onAction: () => AppShell.of(context)?.navigateTo(3),
                ),
                const SizedBox(height: 12),
                if (todaySales.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No sales today',
                    subtitle: 'Start selling to see your sales here',
                  )
                else
                  ...todaySales.take(5).map((sale) => _RecentSaleTile(
                        receiptNo: sale.receiptNumber,
                        total: CurrencyFormatter.format(sale.total, currency: currency),
                        time: DateFormatter.formatTime(sale.createdAt),
                        itemCount: sale.items.length,
                        paymentMethod: sale.paymentMethod,
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _openOrderHistory(BuildContext context) {
    context.push('/order-history');
  }

  int _getTotalProducts(BuildContext context) {
    final state = context.read<ProductCubit>().state;
    if (state is ProductLoaded) return state.products.length;
    return 0;
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StockAlertTile extends StatelessWidget {
  final String name;
  final int qty;
  final bool isOut;

  const _StockAlertTile({required this.name, required this.qty, required this.isOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOut ? AppTheme.dangerColor : AppTheme.warningColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isOut ? Icons.remove_shopping_cart_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            label: isOut ? 'Out of stock' : '$qty left',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final String receiptNo;
  final String total;
  final String time;
  final int itemCount;
  final String paymentMethod;

  const _RecentSaleTile({
    required this.receiptNo,
    required this.total,
    required this.time,
    required this.itemCount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiptNo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount items • $paymentMethod',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
