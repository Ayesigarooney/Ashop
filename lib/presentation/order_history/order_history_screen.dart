import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/product/data/repositories/product_repository.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/sale/data/repositories/sale_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _searchCtrl = TextEditingController();
  DateTime? _filterDate;
  String _filterQuery = '';
  late final VoidCallback _onSalesChanged;

  @override
  void initState() {
    super.initState();
    _onSalesChanged = () => setState(() {});
    Hive.box<SaleModel>(
      AppConstants.salesBox,
    ).listenable().addListener(_onSalesChanged);
  }

  @override
  void dispose() {
    Hive.box<SaleModel>(
      AppConstants.salesBox,
    ).listenable().removeListener(_onSalesChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saleRepo = context.read<SaleRepository>();
    final currency = context.read<SettingsRepository>().currency;

    var sales = _filterDate != null
        ? saleRepo.getSalesByDate(_filterDate!)
        : saleRepo.getAllSales();

    if (_filterQuery.isNotEmpty) {
      sales = sales
          .where(
            (s) =>
                s.receiptNumber.toLowerCase().contains(
                  _filterQuery.toLowerCase(),
                ) ||
                (s.customerName?.toLowerCase().contains(
                      _filterQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    final totalRevenue = sales
        .where((s) => !s.isRefunded)
        .fold(0.0, (a, s) => a + s.total);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order History',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              color: _filterDate != null ? AppTheme.primaryColor : null,
            ),
            tooltip: 'Filter by date',
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _filterDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              setState(() => _filterDate = date);
            },
          ),
          if (_filterDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: () => setState(() => _filterDate = null),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by receipt # or customer...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _filterQuery = v),
                ),
                if (_filterDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Showing: ${DateFormatter.formatDate(_filterDate!)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _filterDate = null),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Summary Bar
          if (sales.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${sales.length} orders',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(
                        totalRevenue,
                        currency: currency,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: sales.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No orders found',
                    subtitle: 'Your completed sales will appear here',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    itemCount: sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _OrderTile(
                      sale: sales[i],
                      currency: currency,
                      onTap: () => context.push('/receipt', extra: sales[i]),
                      onRefund: sales[i].isRefunded
                          ? null
                          : () async {
                              final confirm = await showConfirmDialog(
                                context,
                                title: 'Refund Sale',
                                message:
                                    'Mark this sale as refunded? Stock will be restored.',
                                confirmLabel: 'Refund',
                                isDanger: true,
                              );
                              if (confirm == true) {
                                final productRepo = context
                                    .read<ProductRepository>();
                                await saleRepo.refundSale(
                                  sales[i].id,
                                  productRepo,
                                );
                                if (context.mounted) setState(() {});
                              }
                            },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final SaleModel sale;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onRefund;

  const _OrderTile({
    required this.sale,
    required this.currency,
    required this.onTap,
    this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sale.isRefunded
                ? AppTheme.dangerColor.withValues(alpha: 0.25)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sale.isRefunded
                        ? AppTheme.dangerColor.withValues(alpha: 0.1)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    sale.isRefunded
                        ? Icons.undo_rounded
                        : Icons.receipt_rounded,
                    color: sale.isRefunded
                        ? AppTheme.dangerColor
                        : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sale.receiptNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (sale.isRefunded) ...[
                            const SizedBox(width: 6),
                            StatusBadge(
                              label: 'Refunded',
                              color: AppTheme.dangerColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sale.items.length} items • ${sale.paymentMethod}'
                        '${sale.customerName != null ? ' • ${sale.customerName}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(sale.total, currency: currency),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sale.isRefunded
                            ? AppTheme.dangerColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.timeAgo(sale.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (onRefund != null) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onRefund,
                    icon: const Icon(Icons.undo_rounded, size: 13),
                    label: const Text('Refund', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
