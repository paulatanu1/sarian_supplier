import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/product_avatar.dart';
import '../../../models/product_model.dart';
import '../../../providers/products_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _form        = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _compCtrl    = TextEditingController();  // composition
  final _coCtrl      = TextEditingController();  // company
  final _descCtrl    = TextEditingController();
  final _mrpCtrl     = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _stockCtrl   = TextEditingController();
  String _category   = '';
  bool   _isActive   = true;
  File?  _imageFile;
  String? _existingImageUrl;
  bool   _loading    = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadProduct();
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('products').doc(widget.productId).get();
    if (!doc.exists || !mounted) return;
    final p = ProductModel.fromFirestore(doc);
    _nameCtrl.text   = p.name;
    _compCtrl.text   = p.composition;
    _coCtrl.text     = p.company;
    _descCtrl.text   = p.description;
    _mrpCtrl.text    = p.mrp.toString();
    _priceCtrl.text  = p.tradePrice.toString();
    _stockCtrl.text  = p.stockQty.toString();
    setState(() {
      _category         = p.category;
      _isActive         = p.isActive;
      _existingImageUrl = p.imageUrl;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _compCtrl.dispose(); _coCtrl.dispose();
    _descCtrl.dispose(); _mrpCtrl.dispose(); _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (img != null) setState(() => _imageFile = File(img.path));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(productsNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.editProduct(widget.productId!, {
          'name':        _nameCtrl.text.trim(),
          'composition': _compCtrl.text.trim(),
          'company':     _coCtrl.text.trim(),
          'category':    _category,
          'description': _descCtrl.text.trim(),
          'mrp':         double.tryParse(_mrpCtrl.text) ?? 0,
          'tradePrice':  double.tryParse(_priceCtrl.text) ?? 0,
          'stockQty':    int.tryParse(_stockCtrl.text) ?? 0,
          'isActive':    _isActive,
        }, image: _imageFile);
        if (mounted) context.showSnack('Product updated');
      } else {
        final p = ProductModel(
          id:          '',
          name:        _nameCtrl.text.trim(),
          composition: _compCtrl.text.trim(),
          company:     _coCtrl.text.trim(),
          category:    _category,
          description: _descCtrl.text.trim(),
          mrp:         double.tryParse(_mrpCtrl.text)   ?? 0,
          tradePrice:  double.tryParse(_priceCtrl.text) ?? 0,
          stockQty:    int.tryParse(_stockCtrl.text)    ?? 0,
          isActive:    _isActive,
          updatedAt:   DateTime.now(),
        );
        await notifier.add(p, image: _imageFile);
        if (mounted) context.showSnack('Product added');
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, width: 140, height: 140, fit: BoxFit.cover)
                          : ProductAvatar(
                              imageUrl:    _existingImageUrl,
                              productName: _nameCtrl.text,
                              company:     _coCtrl.text,
                              composition: _compCtrl.text,
                              size:        140,
                            ),
                    ),
                    Positioned(
                      bottom: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _field(_nameCtrl,  'Product Name',  Icons.medication_outlined,
                required: true),
            _field(_compCtrl,  'Composition',   Icons.science_outlined, required: true),
            _field(_coCtrl,    'Company Name',  Icons.business_outlined, required: true),

            // Category dropdown
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category.isEmpty ? null : _category,
              decoration:  const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: cats.map((c) => DropdownMenuItem(
                value: c.name, child: Text(c.name))).toList(),
              onChanged: (v) { setState(() => _category = v ?? ''); },
              validator:   (v) => (v == null || v.isEmpty) ? 'Select a category' : null,
            ),
            const SizedBox(height: 16),

            _field(_descCtrl,  'Description',   Icons.notes_outlined, maxLines: 3),
            Row(children: [
              Expanded(child: _field(_mrpCtrl,   'MRP (₹)',
                  Icons.currency_rupee, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(_priceCtrl, 'Trade Price (₹)',
                  Icons.price_change_outlined, type: TextInputType.number)),
            ]),
            _field(_stockCtrl, 'Stock Quantity', Icons.inventory_outlined,
                type: TextInputType.number, required: true),

            // Active toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Product Active'),
              subtitle: const Text('Inactive products won\'t appear to users'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeThumbColor: AppColors.primary,
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isEdit ? 'Update Product' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool required = false,
    TextInputType type = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          maxLines:   maxLines,
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            alignLabelWithHint: maxLines > 1,
          ),
          validator: required
              ? (v) => v!.trim().isEmpty ? 'Required' : null
              : null,
        ),
      );
}
