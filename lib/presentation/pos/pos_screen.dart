import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/sale/presentation/bloc/sale_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'checkout_sheet.dart';
import 'barcode_scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Point of Sale', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Barcode',
            onPressed: () => _openScanner(context),
          ),
          BlocBuilder<SaleCubit, SaleState>(
            builder: (context, state) {
              final cart = state is CartState ? state : CartState();
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded),
                    onPressed: cart.isEmpty ? null : () => _showCart(context),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${cart.itemCount > 9 ? '9+' : cart.itemCount}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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

          // Category Filter
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              final categories = ['All', ...context.read<ProductCubit>().getCategories()];
              return SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        context.read<ProductCubit>().filterByCategory(cat == 'All' ? null : cat);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryColor
                              : (isDark ? AppTheme.darkCardAlt : AppTheme.lightBg),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Products Grid
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) return const AshopLoading();
                if (state is ProductLoaded) {
                  final products = state.filtered.where((p) => p.isActive).toList();
                  if (products.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_rounded,
                      title: 'No products found',
                      subtitle: 'Try a different search or category',
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: products[i],
                      onTap: () {
                        if (products[i].isOutOfStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${products[i].name} is out of stock'),
                              backgroundColor: AppTheme.dangerColor,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                          return;
                        }
                        context.read<SaleCubit>().addToCart(products[i]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${products[i].name} added',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 1000),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                }
                return const AshopLoading();
              },
            ),
          ),
        ],
      ),

      // Cart FAB
      floatingActionButton: BlocBuilder<SaleCubit, SaleState>(
        builder: (context, state) {
          final cart = state is CartState ? state : CartState();
          if (cart.isEmpty) return const SizedBox.shrink();
          final currency = context.read<SettingsRepository>().currency;
          return Padding(
            padding: const EdgeInsets.only(bottom: 68),
            child: GestureDetector(
              onTap: () => _showCart(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'View Cart',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 16,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      CurrencyFormatter.format(cart.total, currency: currency),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SaleCubit>(),
        child: RepositoryProvider.value(
          value: context.read<SettingsRepository>(),
          child: const CheckoutSheet(),
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode != null && mounted) {
      final product = context.read<ProductCubit>().getByBarcode(barcode);
      if (product != null) {
        if (product.isOutOfStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} is out of stock'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          context.read<SaleCubit>().addToCart(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found for this barcode'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.read<SettingsRepository>().currency;
    final lowStockThreshold = context.read<SettingsRepository>().lowStockThreshold;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.isOutOfStock
                ? AppTheme.dangerColor.withOpacity(0.3)
                : product.isLowStock(threshold: lowStockThreshold)
                    ? AppTheme.warningColor.withOpacity(0.25)
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image / Icon Area
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCardAlt
                      : AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: product.imagePath != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.file(
                                File(product.imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _defaultIcon(product.category),
                              ),
                            )
                          : _defaultIcon(product.category),
                    ),
                    if (product.isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withOpacity(0.85),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_shopping_cart_rounded, color: Colors.white, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                'OUT OF\nSTOCK',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (product.isLowStock(threshold: lowStockThreshold) && !product.isOutOfStock)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stockQuantity} left',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormatter.format(product.sellingPrice, currency: currency),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: product.isOutOfStock
                                ? AppTheme.dangerColor.withOpacity(0.15)
                                : AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 15,
                            color: product.isOutOfStock ? AppTheme.dangerColor : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultIcon(String category) {
    final icons = {
      'Beverages': Icons.local_drink_rounded,
      'Bakery': Icons.bakery_dining_rounded,
      'Groceries': Icons.shopping_basket_rounded,
      'Household': Icons.home_rounded,
      'Personal Care': Icons.face_rounded,
      'Dairy': Icons.egg_rounded,
      'Airtime': Icons.phone_android_rounded,
    };
    return Icon(
      icons[category] ?? Icons.inventory_2_rounded,
      size: 34,
      color: AppTheme.primaryColor.withOpacity(0.45),
    );
  }
}
