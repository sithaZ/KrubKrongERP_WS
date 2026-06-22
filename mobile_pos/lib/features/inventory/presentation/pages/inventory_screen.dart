import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pos/domain/entities/pos_entities.dart';
import '../../../pos/presentation/providers/pos_provider.dart';
import '../../../pos/presentation/widgets/product_image.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(inventoryProductsProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final user = ref.watch(currentUserProvider);
    final canManage = user?.isManager == true || user?.isOwnerOrAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Inventory Tracking')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProductSheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('Add Product')),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(inventoryProductsProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            lowStockAsync.when(
              data: (lowStockItems) => _InventoryHeader(
                totalProductsFuture: productsAsync,
                lowStockCount: lowStockItems.length,
              ),
              loading: () => _InventoryHeader(
                totalProductsFuture: productsAsync,
                lowStockCount: 0,
              ),
              error: (_, __) => _InventoryHeader(
                totalProductsFuture: productsAsync,
                lowStockCount: 0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Products'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyInventoryState(
                    canManage: canManage,
                    onAdd: canManage
                        ? () => _showAddProductSheet(context, ref)
                        : null,
                  );
                }

                return Column(
                  children: products
                      .map(
                        (product) => _InventoryProductTile(
                          product: product,
                          canManage: canManage,
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Failed to load inventory.\n$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ProductFormSheet(),
    );
  }
}

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const InventoryScreen();
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.totalProductsFuture,
    required this.lowStockCount,
  });

  final AsyncValue<List<Product>> totalProductsFuture;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final totalProducts = totalProductsFuture.maybeWhen(
      data: (products) => products.length,
      orElse: () => 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1840AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage stock, pricing, and the products your staff sell in POS.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.86),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Products',
                  value: '$totalProducts',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricChip(
                  label: 'Low Stock',
                  value: '$lowStockCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _InventoryProductTile extends ConsumerWidget {
  const _InventoryProductTile({
    required this.product,
    required this.canManage,
  });

  final Product product;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(
                imageUrl: product.imageUrl,
                placeholder: _imagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (canManage)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          final messenger = ScaffoldMessenger.of(context);
                          if (value == 'edit-product') {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => _ProductFormSheet(product: product),
                            );
                            return;
                          }

                          if (value == 'discontinue') {
                            try {
                              await ref
                                  .read(posApiServiceProvider)
                                  .stopSellingProduct(product.id);
                              ref.invalidate(inventoryProductsProvider);
                              ref.invalidate(posProductsProvider);
                              ref.invalidate(lowStockProductsProvider);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} marked as Discontinued.'),
                                ),
                              );
                            } catch (error) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update product: $error'),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit-product',
                            child: Text('Edit Product'),
                          ),
                          PopupMenuItem<String>(
                            value: 'discontinue',
                            child: Text('Discontinued'),
                          ),
                        ],
                      ),
                  ],
                ),
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
                    _StatusBadge(
                      text: 'Stock ${product.stockQuantity}',
                      color: product.isLowStock
                          ? AppTheme.warning
                          : AppTheme.success,
                      background: product.isLowStock
                          ? AppTheme.warningSurface
                          : AppTheme.successSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE8EEF9),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
    );
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

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({
    required this.canManage,
    required this.onAdd,
  });

  final bool canManage;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No products yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            canManage
                ? 'Add your first product so staff can sell it in POS.'
                : 'A manager needs to add products before POS can be used.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (canManage) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
          ],
        ],
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
  late final TextEditingController _stockController;
  final _picker = ImagePicker();
  String? _imageDataUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(2) : '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0',
    );
    _imageDataUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  _isEditing ? 'Edit Product' : 'Add Product',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing
                      ? 'Update the product details you need.'
                      : 'Add only the basics and save.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _nameController,
                  label: 'Product Name',
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceController,
                        label: 'Price',
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
                        controller: _stockController,
                        label: 'Stock',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter stock';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ImagePickerField(
                  imageDataUrl: _imageDataUrl,
                  onPick: _isSaving ? null : _pickImage,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    child: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                              ? 'Save Changes'
                              : 'Save Product',
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
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
      if (_isEditing) {
        await ref.read(posApiServiceProvider).updateProduct(
              productId: widget.product!.id,
              name: _nameController.text,
              price: double.parse(_priceController.text),
              stockQuantity: int.parse(_stockController.text),
              imageUrl: _imageDataUrl,
            );
      } else {
        await ref.read(posApiServiceProvider).createProduct(
              name: _nameController.text,
              price: double.parse(_priceController.text),
              stockQuantity: int.parse(_stockController.text),
              imageUrl: _imageDataUrl,
            );
      }

      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(posProductsProvider);
      ref.invalidate(lowStockProductsProvider);

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
          SnackBar(content: Text('Failed to add product: $error')),
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
