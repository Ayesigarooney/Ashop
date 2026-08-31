import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsRepository>().currency;
    final lowStockThreshold = context
        .read<SettingsRepository>()
        .lowStockThreshold;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return const AshopLoading();
          if (state is! ProductLoaded) return const AshopLoading();

          final products = state.products;
          final totalValue = products.fold(
            0.0,
            (sum, p) => sum + p.costPrice * p.stockQuantity,
          );
          final totalRetailValue = products.fold(
            0.0,
            (sum, p) => sum + p.sellingPrice * p.stockQuantity,
          );
          final lowCount = products
              .where(
                (p) =>
                    p.isLowStock(threshold: lowStockThreshold) &&
                    !p.isOutOfStock,
              )
              .length;
          final outCount = products.where((p) => p.isOutOfStock).length;

          return Column(
            children: [
              // Summary Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock Value (Cost)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.format(
                                    totalValue,
                                    currency: currency,
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Retail Value',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.format(
                                    totalRetailValue,
                                    currency: currency,
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (lowCount > 0 || outCount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (outCount > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.remove_shopping_cart_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$outCount out of stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            if (lowCount > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$lowCount low stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Product List with Stock
              Expanded(
                child: products.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_rounded,
                        title: 'No products',
                        subtitle: 'Add products to track inventory',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = products[i];
                          final stockValue = p.costPrice * p.stockQuantity;
                          return _InventoryTile(
                            product: p,
                            stockValue: stockValue,
                            currency: currency,
                            lowStockThreshold: lowStockThreshold,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final ProductModel product;
  final double stockValue;
  final String currency;
  final int lowStockThreshold;

  const _InventoryTile({
    required this.product,
    required this.stockValue,
    required this.currency,
    required this.lowStockThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockColor = product.isOutOfStock
        ? AppTheme.dangerColor
        : product.isLowStock(threshold: lowStockThreshold)
        ? AppTheme.warningColor
        : AppTheme.successColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isOutOfStock
              ? AppTheme.dangerColor.withValues(alpha: 0.25)
              : product.isLowStock(threshold: lowStockThreshold)
              ? AppTheme.warningColor.withValues(alpha: 0.2)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: stockColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                '${product.stockQuantity} ${product.unit ?? 'units'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: stockColor,
                ),
              ),
              Text(
                CurrencyFormatter.format(stockValue, currency: currency),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
