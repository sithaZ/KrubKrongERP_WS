import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../domain/entities/pos_entities.dart';
import '../providers/pos_provider.dart';
import '../widgets/product_image.dart';

/// POS Screen - Product listing and cart
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(posProductsProvider);
    final cart = ref.watch(cartProvider);
    final searchController = TextEditingController(
      text: ref.watch(posSearchProvider),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Point of Sale')),
        actions: [
          IconButton(
            onPressed: () {
              _showCartSheet(context, ref);
            },
            icon: Badge(
              label: cart.itemCount > 0 ? Text('${cart.itemCount}') : null,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('Search products'),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          ref.read(posSearchProvider.notifier).state = '';
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(posSearchProvider.notifier).state = value;
              },
            ),
          ),
          if (cart.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  cart.error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(context.tr('No products available right now.')),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onAdd: () async {
                        ref.read(cartProvider.notifier).addToCart(product);
                        await _showCartSheet(context, ref);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load POS products.\n$error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCartSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final cart = ref.watch(cartProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('Current Cart'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (cart.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(context.tr('No items in cart yet.')),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.product.name),
                              subtitle: Text(
                                '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            item.product.id,
                                            item.quantity - 1,
                                          );
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            item.product.id,
                                            item.quantity + 1,
                                          );
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () async {
                                try {
                                  final order = await ref
                                      .read(posApiServiceProvider)
                                      .createOrder(items: cart.items);
                                  ref.read(cartProvider.notifier).clearCart();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Receipt ${order.receiptNumber ?? order.id} created successfully.',
                                        ),
                                      ),
                                    );
                                    ref.invalidate(posProductsProvider);
                                    ref.invalidate(posOrdersProvider);
                                    ref.invalidate(receiptPerformanceProvider);
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Checkout failed: $error'),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(context.tr('Checkout')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBorder
        : AppTheme.lightBorder;
    final addEnabled = product.isInStock;
    final stockColor =
        product.isLowStock ? Colors.orange.shade800 : AppTheme.success;
    final stockBackground = product.isLowStock
        ? Colors.orange.withOpacity(0.12)
        : AppTheme.successSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  placeholder: _placeholder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Stock ${product.stockQuantity}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: addEnabled ? onAdd : null,
                child: Text(addEnabled ? 'Add to cart' : 'Unavailable'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 42),
    );
  }
}
