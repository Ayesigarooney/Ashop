import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_theme.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../pos/barcode_scanner_screen.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  String _category = 'General';
  String? _imagePath;
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  final List<String> _categories = [
    'General',
    'Beverages',
    'Bakery',
    'Groceries',
    'Household',
    'Personal Care',
    'Dairy',
    'Airtime',
    'Electronics',
    'Clothing',
    'Stationery',
    'Medicine',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _sellingPriceCtrl.text = p.sellingPrice.toString();
      _costPriceCtrl.text = p.costPrice.toString();
      _stockCtrl.text = p.stockQuantity.toString();
      _barcodeCtrl.text = p.barcode ?? '';
      _descCtrl.text = p.description ?? '';
      _unitCtrl.text = p.unit ?? '';
      _category = p.category;
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_rounded,
                color: AppTheme.dangerColor,
              ),
              tooltip: 'Delete',
              onPressed: () async {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Delete Product',
                  message:
                      'Are you sure you want to delete "${widget.product!.name}"?',
                  confirmLabel: 'Delete',
                  isDanger: true,
                );
                if (confirm == true && mounted) {
                  await context.read<ProductCubit>().deleteProduct(
                    widget.product!.id,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppTheme.primaryColor,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _SectionLabel('Basic Information'),
              const SizedBox(height: 12),

              AshopTextField(
                label: 'Product Name *',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AshopTextField(
                      label: 'Selling Price *',
                      controller: _sellingPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AshopTextField(
                      label: 'Cost Price',
                      controller: _costPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AshopTextField(
                      label: 'Stock Quantity *',
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AshopTextField(
                      label: 'Unit (kg, pcs...)',
                      controller: _unitCtrl,
                    ),
                  ),
                ],
              ),

              // Profit Preview
              if (_sellingPriceCtrl.text.isNotEmpty &&
                  _costPriceCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final sell = double.tryParse(_sellingPriceCtrl.text) ?? 0;
                    final cost = double.tryParse(_costPriceCtrl.text) ?? 0;
                    final profit = sell - cost;
                    final margin = cost > 0 ? (profit / cost * 100) : 0;
                    final isPositive = profit >= 0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (isPositive
                                    ? AppTheme.successColor
                                    : AppTheme.dangerColor)
                                .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (isPositive
                                      ? AppTheme.successColor
                                      : AppTheme.dangerColor)
                                  .withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ProfitStat(
                            label: 'Profit/Unit',
                            value: profit.toStringAsFixed(0),
                            color: isPositive
                                ? AppTheme.successColor
                                : AppTheme.dangerColor,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color:
                                (isPositive
                                        ? AppTheme.successColor
                                        : AppTheme.dangerColor)
                                    .withOpacity(0.2),
                          ),
                          _ProfitStat(
                            label: 'Margin',
                            value: '${margin.toStringAsFixed(1)}%',
                            color: AppTheme.accentColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),
              _SectionLabel('Category'),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                isExpanded: true,
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'General'),
              ),

              const SizedBox(height: 24),
              _SectionLabel('Additional Info'),
              const SizedBox(height: 12),

              AshopTextField(
                label: 'Barcode / SKU',
                controller: _barcodeCtrl,
                suffix: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  onPressed: _scanBarcode,
                ),
              ),
              const SizedBox(height: 12),

              AshopTextField(
                label: 'Description (optional)',
                controller: _descCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_circle_rounded,
                          size: 18,
                        ),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Product'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (source != null) {
      final file = await picker.pickImage(source: source, maxWidth: 600);
      if (file != null) setState(() => _imagePath = file.path);
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode != null && mounted) {
      _barcodeCtrl.text = barcode;
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = widget.product!.copyWith(
          name: _nameCtrl.text.trim(),
          sellingPrice: double.parse(_sellingPriceCtrl.text),
          costPrice: double.tryParse(_costPriceCtrl.text) ?? 0,
          stockQuantity: int.parse(_stockCtrl.text),
          category: _category,
          barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
          imagePath: _imagePath,
          unit: _unitCtrl.text.isEmpty ? null : _unitCtrl.text,
        );
        await context.read<ProductCubit>().updateProduct(updated);
      } else {
        await context.read<ProductCubit>().addProduct(
          name: _nameCtrl.text.trim(),
          sellingPrice: double.parse(_sellingPriceCtrl.text),
          costPrice: double.tryParse(_costPriceCtrl.text) ?? 0,
          stockQuantity: int.parse(_stockCtrl.text),
          category: _category,
          barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
          imagePath: _imagePath,
          unit: _unitCtrl.text.isEmpty ? null : _unitCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class _ProfitStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfitStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }
}
