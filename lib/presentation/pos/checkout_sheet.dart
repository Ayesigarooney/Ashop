import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/sale/presentation/bloc/sale_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/shared_widgets.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  String _paymentMethod = 'Cash';
  final _amountCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _showPayment = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _customerCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.read<SettingsRepository>().currency;

    return BlocListener<SaleCubit, SaleState>(
      listener: (context, state) {
        if (state is SaleCompleted) {
          // Close the bottom sheet first, then navigate to receipt via go_router
          Navigator.of(context).pop();
          // Small delay so the sheet finishes closing before navigation
          Future.microtask(() {
            if (context.mounted) {
              context.push('/receipt', extra: state.sale);
            }
          });
          context.read<SaleCubit>().resetAfterSale();
        } else if (state is SaleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<SaleCubit, SaleState>(
        builder: (context, state) {
          final cart = state is CartState ? state : CartState();
          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) {
              return SafeArea(
                top: false,
                bottom: true,
                child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (_showPayment)
                                GestureDetector(
                                  onTap: () => setState(() => _showPayment = false),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 22,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              Text(
                                _showPayment ? 'Payment' : 'Cart (${cart.itemCount} items)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (!_showPayment)
                            TextButton.icon(
                              onPressed: () => showConfirmDialog(
                                context,
                                title: 'Clear Cart',
                                message: 'Remove all items from cart?',
                                confirmLabel: 'Clear',
                                isDanger: true,
                              ).then((v) {
                                if (v == true) {
                                  context.read<SaleCubit>().clearCart();
                                  Navigator.pop(context);
                                }
                              }),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.dangerColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (!_showPayment) ...[
                      // Cart Items List
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: theme.colorScheme.onSurface.withOpacity(0.08),
                          ),
                          itemBuilder: (_, i) {
                            final item = cart.items[i];
                            return _CartItemTile(
                              item: item,
                              currency: currency,
                              onIncrement: () => context.read<SaleCubit>().incrementQuantity(item.product.id),
                              onDecrement: () => context.read<SaleCubit>().decrementQuantity(item.product.id),
                              onRemove: () => context.read<SaleCubit>().removeFromCart(item.product.id),
                            );
                          },
                        ),
                      ),

                      // Discount Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.03),
                          border: Border(
                            top: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 16, color: AppTheme.warningColor),
                            const SizedBox(width: 8),
                            Text(
                              'Discount:',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _discountCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  hintText: '0',
                                  suffixText: currency,
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                                onChanged: (v) {
                                  final d = double.tryParse(v) ?? 0;
                                  context.read<SaleCubit>().setDiscount(d);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Totals
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          children: [
                            _TotalRow(
                              label: 'Subtotal',
                              value: CurrencyFormatter.format(cart.subtotal, currency: currency),
                            ),
                            if (cart.discountAmount > 0)
                              _TotalRow(
                                label: 'Discount',
                                value: '- ${CurrencyFormatter.format(cart.discountAmount, currency: currency)}',
                                valueColor: AppTheme.dangerColor,
                              ),
                            if (cart.taxEnabled)
                              _TotalRow(
                                label: 'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)',
                                value: CurrencyFormatter.format(cart.taxAmount, currency: currency),
                              ),
                            const SizedBox(height: 6),
                            Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                            const SizedBox(height: 8),
                            _TotalRow(
                              label: 'Total',
                              value: CurrencyFormatter.format(cart.total, currency: currency),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),

                      // Checkout Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _showPayment = true),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              'Proceed to Payment  •  ${CurrencyFormatter.format(cart.total, currency: currency)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Payment Screen
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amount Due
                              GradientCard(
                                gradient: AppTheme.primaryGradient,
                                child: Column(
                                  children: [
                                    Text(
                                      'Amount Due',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        CurrencyFormatter.format(cart.total, currency: currency),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Payment Method
                              Text(
                                'Payment Method',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.8,
                                children: [
                                  _PaymentMethodTile(
                                    method: 'Cash',
                                    icon: Icons.payments_rounded,
                                    selected: _paymentMethod == 'Cash',
                                    onTap: () => setState(() => _paymentMethod = 'Cash'),
                                  ),
                                  _PaymentMethodTile(
                                    method: 'Mobile Money',
                                    icon: Icons.phone_android_rounded,
                                    selected: _paymentMethod == 'Mobile Money',
                                    onTap: () => setState(() => _paymentMethod = 'Mobile Money'),
                                  ),
                                  _PaymentMethodTile(
                                    method: 'Card',
                                    icon: Icons.credit_card_rounded,
                                    selected: _paymentMethod == 'Card',
                                    onTap: () => setState(() => _paymentMethod = 'Card'),
                                  ),
                                  _PaymentMethodTile(
                                    method: 'Other',
                                    icon: Icons.more_horiz_rounded,
                                    selected: _paymentMethod == 'Other',
                                    onTap: () => setState(() => _paymentMethod = 'Other'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Amount Paid (only for Cash)
                              if (_paymentMethod == 'Cash') ...[
                                Text(
                                  'Amount Received',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AshopTextField(
                                  label: 'Amount received',
                                  controller: _amountCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),

                                // Change Calculation
                                if (_amountCtrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Builder(builder: (context) {
                                    final paid = double.tryParse(_amountCtrl.text) ?? 0;
                                    final change = paid - cart.total;
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: change >= 0
                                            ? AppTheme.successColor.withOpacity(0.1)
                                            : AppTheme.dangerColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: change >= 0
                                              ? AppTheme.successColor.withOpacity(0.3)
                                              : AppTheme.dangerColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            change >= 0 ? 'Change to give:' : 'Amount short:',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(change.abs(), currency: currency),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: change >= 0 ? AppTheme.successColor : AppTheme.dangerColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                const SizedBox(height: 20),
                              ],

                              // Customer Name (optional)
                              Text(
                                'Customer (optional)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              AshopTextField(
                                label: 'Customer name',
                                controller: _customerCtrl,
                                prefix: const Icon(Icons.person_outline, size: 18),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Complete Sale Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: BlocBuilder<SaleCubit, SaleState>(
                          builder: (context, state) {
                            final isLoading = state is SaleLoading;
                            final paid = double.tryParse(_amountCtrl.text) ??
                                (_paymentMethod != 'Cash' ? cart.total : 0);
                            final canComplete = _paymentMethod != 'Cash' || paid >= cart.total;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoading || !canComplete
                                    ? null
                                    : () {
                                        final paidAmount = _paymentMethod != 'Cash'
                                            ? cart.total
                                            : (double.tryParse(_amountCtrl.text) ?? cart.total);
                                        if (_customerCtrl.text.isNotEmpty) {
                                          context.read<SaleCubit>().setCustomerName(_customerCtrl.text);
                                        }
                                        context.read<SaleCubit>().completeSale(
                                              amountPaid: paidAmount,
                                              paymentMethod: _paymentMethod,
                                            );
                                      },
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_rounded, size: 18),
                                label: Text(isLoading ? 'Processing...' : 'Complete Sale'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canComplete ? AppTheme.successColor : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String method;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.darkCardAlt : AppTheme.lightBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final String currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.format(item.unitPrice, currency: currency)} each',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty Controls
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  height: 44,
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onIncrement,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Line Total + Remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(item.lineTotal, currency: currency),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 14, color: AppTheme.dangerColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isTotal ? 17 : 13,
                fontWeight: FontWeight.w800,
                color: valueColor ?? (isTotal ? AppTheme.primaryColor : theme.colorScheme.onSurface),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
