import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class UploadProductScreen extends ConsumerStatefulWidget {
  const UploadProductScreen({super.key});
  @override
  ConsumerState<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends ConsumerState<UploadProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _comparePrice = TextEditingController();
  final _stock = TextEditingController();
  final _sku = TextEditingController();
  final _origin = TextEditingController();
  final _manufacturer = TextEditingController();

  String? _selectedCategoryId;
  final List<File> _images = [];
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _price.dispose();
    _comparePrice.dispose(); _stock.dispose(); _sku.dispose();
    _origin.dispose(); _manufacturer.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.map((p) => File(p.path)));
      if (_images.length > 5) _images.removeRange(5, _images.length);
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_images.isEmpty) {
      showSnack(context, 'Add at least one product image', error: true);
      return;
    }

    final seller = await ref.read(currentSellerProfileProvider.future);
    if (seller == null) {
      showSnack(context, 'Seller profile not found', error: true);
      return;
    }
    if (seller.verificationStatus != VerificationStatus.approved) {
      showSnack(context, 'Your seller account must be verified first', error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // Create product
      final product = await SupabaseService.createProduct({
        'seller_id': seller.id,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        'name': _name.text.trim(),
        'description': _desc.text.trim().isNotEmpty ? _desc.text.trim() : null,
        'price': double.parse(_price.text),
        'compare_price': _comparePrice.text.isNotEmpty ? double.tryParse(_comparePrice.text) : null,
        'stock_quantity': int.tryParse(_stock.text) ?? 0,
        'sku': _sku.text.trim().isNotEmpty ? _sku.text.trim() : null,
        'origin_country': _origin.text.trim().isNotEmpty ? _origin.text.trim() : null,
        'manufacturer': _manufacturer.text.trim().isNotEmpty ? _manufacturer.text.trim() : null,
        'status': 'pending_review',
      });

      // Upload images
      for (int i = 0; i < _images.length; i++) {
        final url = await SupabaseService.uploadProductImage(
            seller.userId, _images[i], product.id, i);
        await SupabaseService.addProductImage(product.id, url, i == 0);
      }

      if (mounted) {
        showSnack(context, 'Product submitted for review!');
        context.go('/seller/products');
        ref.refresh(sellerProductsProvider(seller.id));
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Upload Product'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/seller/products'),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Review notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Products are reviewed by our team before going live on the marketplace.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Images
            const Text('Product Images', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((e) => Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: e.key == 0 ? AppColors.accent : AppColors.surfaceBorder,
                            width: e.key == 0 ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(_images[e.key], fit: BoxFit.cover),
                        ),
                      ),
                      if (e.key == 0)
                        Positioned(
                          bottom: 4, left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent, borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Main', style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary,
                            )),
                          ),
                        ),
                      Positioned(
                        top: 4, right: 14,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(e.key)),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )),
                  if (_images.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.surfaceBorder, style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              _images.isEmpty ? 'Add photos' : 'Add more',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic info
            const Text('Product Information', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            VTextField(
              controller: _name, label: 'Product name',
              prefixIcon: Icons.inventory_2_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            VTextField(
              controller: _desc, label: 'Description',
              prefixIcon: Icons.notes_rounded, maxLines: 4,
            ),
            const SizedBox(height: 12),

            // Category
            categoriesAsync.when(
              data: (cats) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textMuted, size: 20),
                  filled: true, fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                dropdownColor: AppColors.surfaceCard,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No category')),
                  ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Pricing
            const Text('Pricing & Stock', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: VTextField(
                  controller: _price, label: 'Price (USD)',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VTextField(
                  controller: _comparePrice, label: 'Compare price',
                  prefixIcon: Icons.money_off_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: VTextField(
                  controller: _stock, label: 'Stock quantity',
                  prefixIcon: Icons.warehouse_outlined,
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
                child: VTextField(
                  controller: _sku, label: 'SKU (optional)',
                  prefixIcon: Icons.qr_code_rounded,
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Origin
            const Text('Origin & Manufacturing', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textMuted, letterSpacing: 0.8,
            )),
            const SizedBox(height: 10),
            VTextField(controller: _origin, label: 'Country of origin (optional)',
                prefixIcon: Icons.public_outlined),
            const SizedBox(height: 12),
            VTextField(controller: _manufacturer, label: 'Manufacturer (optional)',
                prefixIcon: Icons.factory_outlined),
            const SizedBox(height: 32),

            VButton(
              label: 'Submit for Review',
              onPressed: _submit,
              isLoading: _loading,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
