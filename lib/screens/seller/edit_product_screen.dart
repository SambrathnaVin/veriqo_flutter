import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _comparePriceCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  String? _selectedCategoryId;
  bool _isSaving = false;
  bool _isLoaded = false;
  Product? _product;

  final List<File> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _priceCtrl, _comparePriceCtrl,
      _skuCtrl, _barcodeCtrl, _stockCtrl, _originCtrl,
      _manufacturerCtrl, _tagsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateFields(Product p) {
    if (_isLoaded) return;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description ?? '';
    _priceCtrl.text = p.price.toStringAsFixed(2);
    _comparePriceCtrl.text = p.comparePrice?.toStringAsFixed(2) ?? '';
    _skuCtrl.text = p.sku ?? '';
    _barcodeCtrl.text = p.barcode ?? '';
    _stockCtrl.text = p.stockQuantity.toString();
    _originCtrl.text = p.originCountry ?? '';
    _manufacturerCtrl.text = p.manufacturer ?? '';
    _tagsCtrl.text = p.tags.join(', ');
    _selectedCategoryId = p.categoryId;
    _product = p;
    _isLoaded = true;
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = SupabaseService.currentUser;
    if (user == null || _product == null) return;

    setState(() => _isSaving = true);
    try {
      // Upload any new images
      for (int i = 0; i < _newImages.length; i++) {
        final url = await SupabaseService.uploadProductImage(
          user.id, _newImages[i], widget.productId, _product!.images.length + i,
        );
        await SupabaseService.addProductImage(
          widget.productId, url, _product!.images.isEmpty && i == 0,
        );
      }

      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await SupabaseService.updateProduct(widget.productId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.parse(_priceCtrl.text.trim()),
        if (_comparePriceCtrl.text.isNotEmpty)
          'compare_price': double.parse(_comparePriceCtrl.text.trim()),
        if (_skuCtrl.text.isNotEmpty) 'sku': _skuCtrl.text.trim(),
        if (_barcodeCtrl.text.isNotEmpty) 'barcode': _barcodeCtrl.text.trim(),
        'stock_quantity': int.parse(_stockCtrl.text.trim()),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_originCtrl.text.isNotEmpty) 'origin_country': _originCtrl.text.trim(),
        if (_manufacturerCtrl.text.isNotEmpty) 'manufacturer': _manufacturerCtrl.text.trim(),
        'tags': tags,
        // Re-submit for review if it was rejected
        if (_product!.status == ProductStatus.rejected) 'status': 'pending_review',
      });

      // Invalidate provider so products list refreshes
      ref.invalidate(sellerProductsProvider);
      ref.invalidate(productDetailProvider(widget.productId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return productAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
      data: (product) {
        if (product == null) {
          return const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(child: Text('Product not found', style: TextStyle(color: AppColors.textSecondary))),
          );
        }
        _populateFields(product);

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Edit Product',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner if rejected
                  if (product.status == ProductStatus.rejected) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Product was rejected', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                                if (product.rejectionReason != null)
                                  Text(product.rejectionReason!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Existing images
                  if (product.images.isNotEmpty) ...[
                    _SectionLabel('Current Images'),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final img = product.images[i];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Image.network(img.url, width: 90, height: 90, fit: BoxFit.cover),
                              ),
                              if (img.isPrimary)
                                Positioned(
                                  bottom: 4, left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Main', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Add new images
                  _SectionLabel('Add More Images'),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: _newImages.isEmpty ? 80 : null,
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.surfaceBorder, style: BorderStyle.solid),
                      ),
                      child: _newImages.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded, color: AppColors.textMuted, size: 28),
                                SizedBox(height: 6),
                                Text('Tap to add images', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              ],
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._newImages.map((f) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover),
                                )),
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.surfaceBorder),
                                    ),
                                    child: const Icon(Icons.add_rounded, color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Basic Info
                  _SectionLabel('Basic Information'),
                  const SizedBox(height: AppSpacing.md),
                  _Field(controller: _nameCtrl, label: 'Product Name', validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: AppSpacing.md),
                  _Field(controller: _descCtrl, label: 'Description', maxLines: 4),
                  const SizedBox(height: AppSpacing.xl),

                  // Category
                  _SectionLabel('Category'),
                  const SizedBox(height: AppSpacing.md),
                  categoriesAsync.when(
                    data: (cats) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceCard,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          hint: const Text('Select category', style: TextStyle(color: AppColors.textMuted)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None', style: TextStyle(color: AppColors.textMuted))),
                            ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Pricing
                  _SectionLabel('Pricing'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _Field(controller: _priceCtrl, label: 'Price', keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Invalid' : null))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _Field(controller: _comparePriceCtrl, label: 'Compare Price', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Inventory
                  _SectionLabel('Inventory'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _Field(controller: _skuCtrl, label: 'SKU')),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _Field(controller: _barcodeCtrl, label: 'Barcode')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Field(
                    controller: _stockCtrl,
                    label: 'Stock Quantity',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : (int.tryParse(v) == null ? 'Invalid' : null),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Origin & Tags
                  _SectionLabel('Additional Details'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _Field(controller: _originCtrl, label: 'Origin Country')),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _Field(controller: _manufacturerCtrl, label: 'Manufacturer')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Field(controller: _tagsCtrl, label: 'Tags (comma separated)'),
                  const SizedBox(height: AppSpacing.xl),

                  // Resubmit note
                  if (product.status == ProductStatus.rejected)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh_rounded, color: AppColors.info, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saving will re-submit this product for admin review.',
                              style: TextStyle(color: AppColors.info, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        disabledBackgroundColor: AppColors.accent.withOpacity(0.4),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );
}
