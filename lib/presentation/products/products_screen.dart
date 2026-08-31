import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'add_edit_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Products', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Out of Stock'),
          ],
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ProductCubit>().searchProducts('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (v) {
                context.read<ProductCubit>().searchProducts(v);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ProductList(filter: 'all'),
                _ProductList(filter: 'low'),
                _ProductList(filter: 'out'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'products_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ProductCubit>(),
              child: const AddEditProductScreen(),
            ),
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text('Add Product', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final cats = context.read<ProductCubit>().getCategories();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter by Category',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () {
                    context.read<ProductCubit>().filterByCategory(null);
                    Navigator.pop(context);
                  },
                  child: Chip(
                    label: const Text('All'),
                    backgroundColor: AppTheme.primaryColor,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                ...cats.map((c) => GestureDetector(
                      onTap: () {
                        context.read<ProductCubit>().filterByCategory(c);
                        Navigator.pop(context);
                      },
                      child: Chip(label: Text(c)),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final String filter;
  const _ProductList({required this.filter});

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsRepository>().currency;
    final lowStockThreshold = context.read<SettingsRepository>().lowStockThreshold;
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) return const AshopLoading();
        if (state is ProductLoaded) {
          List<ProductModel> products;
          switch (filter) {
            case 'low':
              products = state.products.where((p) => p.isLowStock(threshold: lowStockThreshold) && !p.isOutOfStock).toList();
              break;
            case 'out':
              products = state.products.where((p) => p.isOutOfStock).toList();
              break;
            default:
              products = state.filtered;
          }

          if (products.isEmpty) {
            return EmptyState(
              icon: filter == 'all'
                  ? Icons.inventory_2_rounded
                  : Icons.check_circle_outline_rounded,
              title: filter == 'all'
                  ? 'No products'
                  : filter == 'low'
                      ? 'No low stock items'
                      : 'No out of stock items',
              subtitle: filter == 'all'
                  ? 'Add your first product to get started'
                  : 'Great! Everything is well stocked.',
              actionLabel: filter == 'all' ? 'Add Product' : null,
              onAction: filter == 'all'
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ProductCubit>(),
                            child: const AddEditProductScreen(),
                          ),
                        ),
                      )
                  : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = products[i];
              return _ProductTile(
                product: p,
                currency: currency,
                lowStockThreshold: lowStockThreshold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ProductCubit>(),
                      child: ProductDetailScreen(product: p),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const AshopLoading();
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final String currency;
  final int lowStockThreshold;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.currency,
    required this.lowStockThreshold,
    required this.onTap,
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
            color: product.isOutOfStock
                ? AppTheme.dangerColor.withOpacity(0.3)
                : product.isLowStock(threshold: lowStockThreshold)
                    ? AppTheme.warningColor.withOpacity(0.25)
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 24),
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
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (product.isOutOfStock)
                        StatusBadge(label: 'Out', color: AppTheme.dangerColor)
                      else if (product.isLowStock(threshold: lowStockThreshold))
                        StatusBadge(label: 'Low', color: AppTheme.warningColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(product.sellingPrice, currency: currency),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.inventory_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product.stockQuantity} ${product.unit ?? 'units'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.25),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
