import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/data/repositories/product_repository.dart';
import '../../../settings/data/settings_repository.dart';

// Cart Item
class CartItem extends Equatable {
  final ProductModel product;
  final int quantity;
  final double discountPercent;
  final String? note;

  const CartItem({
    required this.product,
    required this.quantity,
    this.discountPercent = 0,
    this.note,
  });

  double get unitPrice => product.sellingPrice;
  double get lineTotal {
    final base = unitPrice * quantity;
    return base - (base * discountPercent / 100);
  }

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
    double? discountPercent,
    String? note,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity, discountPercent, note];
}

// States
abstract class SaleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SaleInitial extends SaleState {}
class SaleLoading extends SaleState {}
class CartState extends SaleState {
  final List<CartItem> items;
  final double discountAmount;
  final bool taxEnabled;
  final double taxRate;
  final String? customerName;
  final String? notes;

  CartState({
    this.items = const [],
    this.discountAmount = 0,
    this.taxEnabled = false,
    this.taxRate = 0.18,
    this.customerName,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get taxAmount => taxEnabled ? subtotal * taxRate : 0;
  double get total => subtotal - discountAmount + taxAmount;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? discountAmount,
    bool? taxEnabled,
    double? taxRate,
    String? customerName,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxRate: taxRate ?? this.taxRate,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props =>
      [items, discountAmount, taxEnabled, taxRate, customerName, notes];
}

class SaleCompleted extends SaleState {
  final SaleModel sale;
  SaleCompleted(this.sale);
  @override
  List<Object?> get props => [sale];
}

class SaleError extends SaleState {
  final String message;
  SaleError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class SaleCubit extends Cubit<SaleState> {
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;
  final SettingsRepository _settingsRepository;

  // Remembers the last cart so an ephemeral SaleError state never wipes it
  CartState? _lastCart;

  SaleCubit(this._saleRepository, this._productRepository, this._settingsRepository)
      : super(CartState());

  /// Create a fresh cart pre-loaded with the current tax settings.
  CartState _freshCart() => CartState(
        taxEnabled: _settingsRepository.taxEnabled,
        taxRate: _settingsRepository.taxRate,
      );

  CartState get _cart {
    final s = state;
    if (s is CartState) {
      _lastCart = s;
      return s;
    }
    return _lastCart ?? _freshCart();
  }

  void addToCart(ProductModel product) {
    final cart = _cart;
    final existing = cart.items.indexWhere((i) => i.product.id == product.id);
    List<CartItem> newItems;

    if (existing >= 0) {
      final currentQty = cart.items[existing].quantity;
      // Check if adding one more would exceed available stock
      if (currentQty >= product.stockQuantity) {
        emit(SaleError('Only ${product.stockQuantity} ${product.name} available in stock'));
        return;
      }
      newItems = List.from(cart.items);
      newItems[existing] = newItems[existing]
          .copyWith(quantity: currentQty + 1);
    } else {
      // Check if product has any stock
      if (product.stockQuantity <= 0) {
        emit(SaleError('${product.name} is out of stock'));
        return;
      }
      newItems = [...cart.items, CartItem(product: product, quantity: 1)];
    }

    emit(cart.copyWith(items: newItems));
  }

  void removeFromCart(String productId) {
    final cart = _cart;
    emit(cart.copyWith(
        items: cart.items.where((i) => i.product.id != productId).toList()));
  }

  /// Returns true if the quantity was clamped to the available stock level.
  bool updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return false;
    }
    final cart = _cart;
    bool wasClamped = false;
    final newItems = cart.items.map((i) {
      if (i.product.id == productId) {
        final maxQty = i.product.stockQuantity;
        if (quantity > maxQty) {
          wasClamped = true;
          return i.copyWith(quantity: maxQty);
        }
        return i.copyWith(quantity: quantity);
      }
      return i;
    }).toList();
    emit(cart.copyWith(items: newItems));
    return wasClamped;
  }

  void incrementQuantity(String productId) {
    final cart = _cart;
    final item = cart.items.firstWhere((i) => i.product.id == productId);
    // Check stock limit before incrementing
    if (item.quantity >= item.product.stockQuantity) {
      emit(SaleError('Only ${item.product.stockQuantity} ${item.product.name} available'));
      return;
    }
    updateQuantity(productId, item.quantity + 1);
  }

  void decrementQuantity(String productId) {
    final cart = _cart;
    final item = cart.items.firstWhere((i) => i.product.id == productId);
    updateQuantity(productId, item.quantity - 1);
  }

  void setItemDiscount(String productId, double percent) {
    final cart = _cart;
    final newItems = cart.items.map((i) {
      if (i.product.id == productId) return i.copyWith(discountPercent: percent);
      return i;
    }).toList();
    emit(cart.copyWith(items: newItems));
  }

  void setItemNote(String productId, String? note) {
    final cart = _cart;
    final newItems = cart.items.map((i) {
      if (i.product.id == productId) return i.copyWith(note: note);
      return i;
    }).toList();
    emit(cart.copyWith(items: newItems));
  }

  void setDiscount(double amount) {
    final cart = _cart;
    // Clamp discount so the total can never go negative
    final subtotal = cart.subtotal;
    final clamped = amount < 0
        ? 0.0
        : (amount > subtotal ? subtotal : amount);
    emit(cart.copyWith(discountAmount: clamped));
  }

  void setTax(bool enabled, double rate) {
    emit(_cart.copyWith(taxEnabled: enabled, taxRate: rate));
  }

  void setCustomerName(String? name) {
    emit(_cart.copyWith(customerName: name));
  }

  void clearCart() {
    emit(_freshCart());
  }

  Future<void> completeSale({
    required double amountPaid,
    required String paymentMethod,
  }) async {
    final cart = _cart;
    if (cart.isEmpty) {
      emit(SaleError('Cart is empty'));
      return;
    }

    // Re-validate stock before completing sale
    for (final item in cart.items) {
      final liveProduct = _productRepository.getProductById(item.product.id);
      if (liveProduct == null) {
        emit(SaleError('${item.product.name} no longer exists'));
        return;
      }
      if (item.quantity > liveProduct.stockQuantity) {
        emit(SaleError(
          'Only ${liveProduct.stockQuantity} ${liveProduct.name} available, '
          'but ${item.quantity} in cart. Please adjust quantity.',
        ));
        return;
      }
    }

    emit(SaleLoading());

    // Track stock already deducted so we can roll back on any failure
    final deducted = <String, int>{};
    try {
      final saleItems = cart.items.map((item) => SaleItemModel(
            productId: item.product.id,
            productName: item.product.name,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            totalPrice: item.lineTotal,
            discountPercent: item.discountPercent,
            note: item.note,
            costPrice: item.product.costPrice,
          )).toList();

      // Deduct stock
      for (final item in cart.items) {
        await _productRepository.updateStock(
            item.product.id, -item.quantity);
        deducted[item.product.id] =
            (deducted[item.product.id] ?? 0) + item.quantity;
      }

      final sale = await _saleRepository.completeSale(
        items: saleItems,
        subtotal: cart.subtotal,
        discountAmount: cart.discountAmount,
        taxAmount: cart.taxAmount,
        total: cart.total,
        amountPaid: amountPaid,
        change: amountPaid - cart.total,
        paymentMethod: paymentMethod,
        customerName: cart.customerName,
        notes: cart.notes,
      );

      emit(SaleCompleted(sale));
    } catch (e) {
      // Roll back any stock already deducted to avoid inconsistent inventory
      for (final entry in deducted.entries) {
        try {
          await _productRepository.updateStock(entry.key, entry.value);
        } catch (_) {
          // Best-effort rollback; never let it mask the original error
        }
      }
      emit(SaleError(e.toString()));
    }
  }

  void resetAfterSale() {
    _lastCart = null;
    emit(_freshCart());
  }
}
