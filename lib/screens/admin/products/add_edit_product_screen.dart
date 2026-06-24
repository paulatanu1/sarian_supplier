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
    setState(() {
      _category         = p.category;
      _isActive         = p.isActive;
      _existingImageUrl = p.imageUrl;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _compCtrl.dispose(); _coCtrl.dispose();
    _descCtrl.dispose();
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
    // Existing category values currently in use on products — used to power
    // the autocomplete suggestions. Admins can also type a brand-new
    // category name, which will appear in the sidebar as soon as the
    // product is saved (because the sidebar is derived from products).
    final existingCategories = ref.watch(productCategoriesProvider);

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

            // Category — free-text with suggestions from existing products.
            // Type any name; the user-side sidebar updates automatically.
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Autocomplete<String>(
                initialValue: TextEditingValue(text: _category),
                optionsBuilder: (textEditingValue) {
                  final input = textEditingValue.text.trim().toLowerCase();
                  if (input.isEmpty) return existingCategories;
                  return existingCategories.where(
                    (c) => c.toLowerCase().contains(input),
                  );
                },
                onSelected: (selection) =>
                    setState(() => _category = selection),
                fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                  // Keep external _category in sync as user types so a brand
                  // new (unselected) name is also saved.
                  ctrl.addListener(() {
                    if (_category != ctrl.text) _category = ctrl.text;
                  });
                  return TextFormField(
                    controller: ctrl,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Anti-Spasmodic',
                      helperText: 'Pick existing or type a new one',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter or select a category'
                        : null,
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 240, maxWidth: 360),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (_, i) {
                            final o = options.elementAt(i);
                            return ListTile(
                              dense: true,
                              title: Text(o,
                                  style: const TextStyle(fontSize: 13)),
                              onTap: () => onSelected(o),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            _field(_descCtrl,  'Description',   Icons.notes_outlined, maxLines: 3),

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
