import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pos/domain/entities/pos_entities.dart';
import '../../../pos/presentation/providers/pos_provider.dart';
import '../../../pos/presentation/widgets/product_image.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productsAsync = ref.watch(allProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final user = ref.watch(currentUserProvider);
    final canManage = user?.isManager == true || user?.isOwnerOrAdmin == true;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(context.tr('Product Catalog')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showProductForm(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('Add Product')),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('Search by name, SKU or barcode...'),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productSearchProvider.notifier).state = '';
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {}); // rebuild close button visibility
                if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                  if (mounted) {
                    ref.read(productSearchProvider.notifier).state = val;
                  }
                });
              },
            ),
          ),

          // Categories Filter Row
          productsAsync.when(
            data: (products) {
              final categories = {'All'};
              for (final p in products) {
                if (p.categoryName != null && p.categoryName!.isNotEmpty) {
                  categories.add(p.categoryName!);
                }
              }

              return SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: categories.map((category) {
                    final isSelected = category == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category),
                        onSelected: (selected) {
                          ref.read(selectedCategoryProvider.notifier).state = category;
                        },
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(height: 52),
          ),

          // Main Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allProductsProvider);
                ref.invalidate(inventoryProductsProvider);
                ref.invalidate(posProductsProvider);
              },
              child: productsAsync.when(
                data: (products) {
                  // Filter by category locally
                  final filteredProducts = selectedCategory == 'All'
                      ? products
                      : products.where((p) => p.categoryName == selectedCategory).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 72,
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('No products found'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('Try adjusting your filters or search query.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductListTile(
                        product: product,
                        canManage: canManage,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${context.tr('Failed to load product catalog.')}\n$err'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => const _ProductFormSheet(),
    );
  }
}

class _ProductListTile extends ConsumerWidget {
  const _ProductListTile({
    required this.product,
    required this.canManage,
  });

  final Product product;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Opacity(
        opacity: product.isActive ? 1.0 : 0.6,
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  placeholder: Container(
                    color: const Color(0xFFE8EEF9),
                    alignment: Alignment.center,
                    child: const Icon(Icons.coffee_rounded, color: AppTheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleMenuOption(context, ref, value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'restock',
                              child: Row(
                                children: [
                                  Icon(Icons.add_box_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Quick Restock'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: product.isActive ? 'deactivate' : 'activate',
                              child: Row(
                                children: [
                                  Icon(
                                    product.isActive
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(product.isActive ? 'Discontinue' : 'Resume Selling'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (product.sku.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${product.sku}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusBadge(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        color: AppTheme.primary,
                        background: AppTheme.primaryContainer,
                      ),
                      if (product.costPrice != null && product.costPrice! > 0)
                        _StatusBadge(
                          text: 'Cost \$${product.costPrice!.toStringAsFixed(2)}',
                          color: Colors.blueGrey,
                          background: Colors.blueGrey.withOpacity(0.08),
                        ),
                      _StatusBadge(
                        text: 'Stock ${product.stockQuantity}',
                        color: product.isLowStock ? AppTheme.warning : AppTheme.success,
                        background: product.isLowStock
                            ? AppTheme.warningSurface
                            : AppTheme.successSurface,
                      ),
                      _StatusBadge(
                        text: product.isActive ? 'Active' : 'Discontinued',
                        color: product.isActive ? AppTheme.success : Colors.grey,
                        background: product.isActive
                            ? AppTheme.successSurface
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuOption(BuildContext context, WidgetRef ref, String option) async {
    final messenger = ScaffoldMessenger.of(context);
    if (option == 'edit') {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        builder: (context) => _ProductFormSheet(product: product),
      );
      return;
    }

    if (option == 'restock') {
      showDialog(
        context: context,
        builder: (context) => _QuickRestockDialog(product: product),
      );
      return;
    }

    if (option == 'deactivate' || option == 'activate') {
      final isNewActive = option == 'activate';
      try {
        await ref.read(posApiServiceProvider).setProductStatus(product.id, isNewActive);
        ref.invalidate(allProductsProvider);
        ref.invalidate(posProductsProvider);
        ref.invalidate(inventoryProductsProvider);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isNewActive
                  ? '${product.name} is now Active.'
                  : '${product.name} has been Discontinued.',
            ),
          ),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update status: $error')),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  static const int _maxImageBytes = 900 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reorderController;

  final _picker = ImagePicker();
  String? _imageDataUrl;
  bool _isSaving = false;
  bool _isActive = true;
  String? _selectedChipCategory;
  bool _isCustomCategory = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(2) : '',
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice != null ? widget.product!.costPrice!.toStringAsFixed(2) : '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0',
    );
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _barcodeController = TextEditingController(text: widget.product?.sku ?? '');
    _categoryController = TextEditingController(text: widget.product?.categoryName ?? 'General');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _reorderController = TextEditingController(text: '10');
    _isActive = widget.product?.isActive ?? true;
    _imageDataUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final products = ref.watch(allProductsProvider).valueOrNull ?? [];
    final existingCategories = <String>{'General'};
    for (final p in products) {
      if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
        existingCategories.add(p.categoryName!.trim());
      }
    }

    if (_selectedChipCategory == null) {
      final initialCategory = widget.product?.categoryName ?? 'General';
      if (existingCategories.contains(initialCategory)) {
        _selectedChipCategory = initialCategory;
        _isCustomCategory = false;
      } else {
        _selectedChipCategory = null;
        _isCustomCategory = true;
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? 'Edit Product Details' : 'Add New Product',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing
                      ? 'Update details in the ERP system.'
                      : 'Create a new product that can be sold in POS.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _nameController,
                  label: 'Product Name *',
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceController,
                        label: 'Selling Price *',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _costPriceController,
                        label: 'Cost Price',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid cost';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _stockController,
                        label: 'Stock Level *',
                        keyboardType: TextInputType.number,
                        enabled: !_isEditing, // Stock adjustments should happen via restock, not direct edit
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter starting stock';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _skuController,
                        label: 'SKU / Code',
                        hintText: 'Leave blank to auto-generate',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _reorderController,
                  label: 'Low Stock Level',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Product Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...existingCategories.map((cat) {
                      final isSelected = !_isCustomCategory && _selectedChipCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedChipCategory = cat;
                              _isCustomCategory = false;
                              _categoryController.text = cat;
                            });
                          }
                        },
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: _isCustomCategory
                                ? AppTheme.primary
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(width: 4),
                          Text(context.tr('Custom')),
                        ],
                      ),
                      selected: _isCustomCategory,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _isCustomCategory = true;
                            if (widget.product?.categoryName != null &&
                                !existingCategories.contains(widget.product!.categoryName)) {
                              _categoryController.text = widget.product!.categoryName!;
                            } else {
                              _categoryController.text = '';
                            }
                          });
                        }
                      },
                      selectedColor: AppTheme.primary.withOpacity(0.15),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: _isCustomCategory
                            ? AppTheme.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: _isCustomCategory ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _categoryController,
                    label: context.tr('Custom Category Name *'),
                    validator: (value) => _isCustomCategory && (value == null || value.trim().isEmpty)
                        ? context.tr('Custom category name is required')
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                _buildField(
                  controller: _descriptionController,
                  label: context.tr('Product Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Active/Inactive toggle
                SwitchListTile(
                  title: Text(context.tr('Available for Sale (Active)')),
                  subtitle: Text(context.tr('Inactive products will not appear in the POS register')),
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _ImagePickerField(
                  imageDataUrl: _imageDataUrl,
                  onPick: _isSaving ? null : _pickImage,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                              ? 'Save Changes'
                              : 'Create Product',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 45,
      maxWidth: 800,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    if (!mounted) {
      return;
    }

    if (bytes.length > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large. Please choose a smaller photo.'),
        ),
      );
      return;
    }

    setState(() {
      _imageDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      final costPrice = double.tryParse(_costPriceController.text);
      final stock = int.parse(_stockController.text);
      final sku = _skuController.text.trim();
      final description = _descriptionController.text.trim();
      final category = _categoryController.text.trim();
      final reorder = int.tryParse(_reorderController.text) ?? 10;

      if (_isEditing) {
        await ref.read(posApiServiceProvider).updateProduct(
              productId: widget.product!.id,
              name: name,
              price: price,
              stockQuantity: stock,
              imageUrl: _imageDataUrl,
              sku: sku.isNotEmpty ? sku : null,
              description: description.isNotEmpty ? description : null,
              costPrice: costPrice,
              categoryId: category.toLowerCase().replaceAll(' ', '_'),
              categoryName: category,
              reorderLevel: reorder,
              isActive: _isActive,
            );
      } else {
        await ref.read(posApiServiceProvider).createProduct(
              name: name,
              price: price,
              stockQuantity: stock,
              imageUrl: _imageDataUrl,
              sku: sku.isNotEmpty ? sku : null,
              description: description.isNotEmpty ? description : null,
              costPrice: costPrice,
              categoryId: category.toLowerCase().replaceAll(' ', '_'),
              categoryName: category,
              reorderLevel: reorder,
              isActive: _isActive,
            );
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(posProductsProvider);
      ref.invalidate(inventoryProductsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Product updated successfully.'
                  : 'Product added successfully.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.imageDataUrl,
    required this.onPick,
  });

  final String? imageDataUrl;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : AppTheme.lightBorder,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: ProductImage(
                  imageUrl: imageDataUrl,
                  placeholder: Container(
                    color: const Color(0xFFE8EEF9),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Image',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageDataUrl == null ? 'Tap to upload' : 'Tap to change image',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _QuickRestockDialog extends ConsumerStatefulWidget {
  const _QuickRestockDialog({required this.product});

  final Product product;

  @override
  ConsumerState<_QuickRestockDialog> createState() => _QuickRestockDialogState();
}

class _QuickRestockDialogState extends ConsumerState<_QuickRestockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '10');
  final _noteController = TextEditingController(text: 'Restock product');
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Quick Restock: ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Add Quantity',
                suffixText: 'units',
              ),
              validator: (val) {
                final parsed = int.tryParse(val ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submitRestock,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text(_isSaving ? 'Saving...' : 'Add Stock'),
        ),
      ],
    );
  }

  Future<void> _submitRestock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final change = int.parse(_quantityController.text);
      final note = _noteController.text.trim();

      await ref.read(posApiServiceProvider).adjustProductStock(
            productId: widget.product.id,
            quantityChange: change,
            note: note,
          );

      ref.invalidate(allProductsProvider);
      ref.invalidate(posProductsProvider);
      ref.invalidate(inventoryProductsProvider);

      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Successfully restocked ${widget.product.name} by $change units.',
            ),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to restock: $err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
