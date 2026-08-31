import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../../../core/config/constants.dart';

// States
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final List<ProductModel> filtered;
  final String searchQuery;
  final String? selectedCategory;

  static const Object _sentinel = Object();

  ProductLoaded({
    required this.products,
    List<ProductModel>? filtered,
    this.searchQuery = '',
    this.selectedCategory,
  }) : filtered = filtered ?? products;

  ProductLoaded copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filtered,
    String? searchQuery,
    Object? selectedCategory = _sentinel,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: identical(selectedCategory, _sentinel)
          ? this.selectedCategory
          : selectedCategory as String?,
    );
  }

  @override
  List<Object?> get props => [
    products,
    filtered,
    searchQuery,
    selectedCategory,
  ];
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;
  late final VoidCallback _boxListener;

  ProductCubit(this._repository) : super(ProductInitial()) {
    _boxListener = _onBoxChanged;
    Hive.box<ProductModel>(
      AppConstants.productsBox,
    ).listenable().addListener(_boxListener);
  }

  void _onBoxChanged() {
    if (state is ProductLoaded) {
      try {
        final products = _repository.getAllProducts();
        final current = state as ProductLoaded;
        if (current.searchQuery.isNotEmpty) {
          final filtered = _repository.searchProducts(current.searchQuery);
          emit(current.copyWith(products: products, filtered: filtered));
        } else if (current.selectedCategory != null) {
          final filtered = _repository.getProductsByCategory(
            current.selectedCategory!,
          );
          emit(current.copyWith(products: products, filtered: filtered));
        } else {
          emit(current.copyWith(products: products));
        }
      } catch (_) {
        // Reload instead of failing silently so the UI never shows stale data
        loadProducts();
      }
    } else {
      loadProducts();
    }
  }

  @override
  Future<void> close() {
    Hive.box<ProductModel>(
      AppConstants.productsBox,
    ).listenable().removeListener(_boxListener);
    return super.close();
  }

  void loadProducts() {
    emit(ProductLoading());
    try {
      final products = _repository.getAllProducts();
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void searchProducts(String query) {
    if (state is ProductLoaded) {
      final current = state as ProductLoaded;
      if (query.isEmpty) {
        emit(current.copyWith(filtered: current.products, searchQuery: ''));
      } else {
        final filtered = _repository.searchProducts(query);
        emit(current.copyWith(filtered: filtered, searchQuery: query));
      }
    }
  }

  void filterByCategory(String? category) {
    if (state is ProductLoaded) {
      final current = state as ProductLoaded;
      List<ProductModel> filtered;
      if (category == null) {
        filtered = current.products;
      } else {
        filtered = _repository.getProductsByCategory(category);
      }
      emit(current.copyWith(filtered: filtered, selectedCategory: category));
    }
  }

  Future<void> addProduct({
    required String name,
    required double sellingPrice,
    required double costPrice,
    required int stockQuantity,
    required String category,
    String? barcode,
    String? description,
    String? imagePath,
    String? unit,
  }) async {
    try {
      await _repository.addProduct(
        name: name,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
        stockQuantity: stockQuantity,
        category: category,
        barcode: barcode,
        description: description,
        imagePath: imagePath,
        unit: unit,
      );
      loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.updateProduct(product);
      loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  List<ProductModel> getLowStockProducts({int threshold = 5}) {
    return _repository.getLowStockProducts(threshold: threshold);
  }

  List<ProductModel> getOutOfStockProducts() {
    return _repository.getOutOfStockProducts();
  }

  List<String> getCategories() => _repository.getCategories();

  ProductModel? getByBarcode(String barcode) =>
      _repository.getProductByBarcode(barcode);
}
