import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.read<SettingsRepository>().currency;
    final lowStockThreshold = context.read<SettingsRepository>().lowStockThreshold;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ProductCubit>(),
                  child: AddEditProductScreen(product: product),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppTheme.dangerColor),
            tooltip: 'Delete',
            onPressed: () => _deleteProduct(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.category,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (product.unit != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.unit!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price Cards
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Selling Price',
                    value: CurrencyFormatter.format(product.sellingPrice, currency: currency),
                    icon: Icons.sell_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'Cost Price',
                    value: CurrencyFormatter.format(product.costPrice, currency: currency),
                    icon: Icons.shopping_bag_rounded,
                    color: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'Profit/Unit',
                    value: CurrencyFormatter.format(product.profit, currency: currency),
                    icon: Icons.trending_up_rounded,
                    color: product.profit >= 0 ? AppTheme.successColor : AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'Margin',
                    value: '${product.profitMargin.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stock Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: product.isOutOfStock
                      ? AppTheme.dangerColor.withOpacity(0.3)
                      : product.isLowStock(threshold: lowStockThreshold)
                          ? AppTheme.warningColor.withOpacity(0.3)
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.stockQuantity} ${product.unit ?? 'units'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (product.isOutOfStock)
                    StatusBadge(label: 'Out of Stock', color: AppTheme.dangerColor)
                  else if (product.isLowStock(threshold: lowStockThreshold))
                    StatusBadge(label: 'Low Stock', color: AppTheme.warningColor)
                  else
                    StatusBadge(label: 'In Stock', color: AppTheme.successColor),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Stock Adjust
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _adjustStock(context, -1),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Remove Stock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _adjustStock(context, 1),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Stock'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  ),
                ),
              ],
            ),

            if (product.barcode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        product.barcode!,
                        style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Added: ${DateFormatter.formatDateTime(product.createdAt)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Updated: ${DateFormatter.timeAgo(product.updatedAt)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context) {
    showConfirmDialog(
      context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete "${product.name}"?',
      confirmLabel: 'Yes',
      cancelLabel: 'No',
      isDanger: true,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<ProductCubit>().deleteProduct(product.id);
        Navigator.pop(context);
      }
    });
  }

  void _adjustStock(BuildContext context, int direction) {
    showDialog(
      context: context,
      builder: (_) => _AdjustStockDialog(
        product: product,
        direction: direction,
        productCubit: context.read<ProductCubit>(),
      ),
    );
  }
}

class _AdjustStockDialog extends StatefulWidget {
  final ProductModel product;
  final int direction;
  final ProductCubit productCubit;

  const _AdjustStockDialog({
    required this.product,
    required this.direction,
    required this.productCubit,
  });

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.direction > 0 ? 'Add Stock' : 'Remove Stock',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Quantity',
          suffixText: widget.product.unit ?? 'units',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final qty = int.tryParse(_ctrl.text) ?? 0;
            if (qty > 0) {
              final newStock = widget.product.stockQuantity + (qty * widget.direction);
              if (newStock < 0) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot remove $qty — only ${widget.product.stockQuantity} in stock',
                      ),
                      backgroundColor: AppTheme.dangerColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
                return;
              }
              await widget.productCubit.updateProduct(
                widget.product.copyWith(stockQuantity: newStock),
              );
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
