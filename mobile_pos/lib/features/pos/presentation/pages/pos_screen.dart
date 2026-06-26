import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/pos_entities.dart';
import '../providers/pos_provider.dart';
import '../widgets/product_image.dart';

/// POS Screen - Product listing and cart optimized for cashiers & physical register POS workflows
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _selectedCategory = 'All Items';
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(posSearchProvider),
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
    final productsAsync = ref.watch(posProductsProvider);
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Time-aware Header and Register Info
            _buildHeader(context, ref),

            // 2. Table & Take Away Register Selector
            _buildTableSelector(context, ref),

            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Filter products locally by selected category
                  final filteredProducts = _selectedCategory == 'All Items'
                      ? products
                      : products
                          .where((p) => p.categoryName == _selectedCategory)
                          .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Category Selector
                      _buildCategorySelector(
                        context,
                        products,
                        _selectedCategory,
                        (cat) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: context.tr('Search items or sku...'),
                            filled: true,
                            fillColor: isDark ? AppTheme.darkCard : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(posSearchProvider.notifier).state = '';
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {}); // to rebuild search clear icon
                            if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                            _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                              if (mounted) {
                                ref.read(posSearchProvider.notifier).state = value;
                              }
                            });
                          },
                        ),
                      ),

                      if (cart.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cart.error!,
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).clearError();
                                  },
                                )
                              ],
                            ),
                          ),
                        ),

                      // 5. Product Grid List optimized for cashiers (Tap adds directly)
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? Center(
                                child: Text(
                                  context.tr('No items available.'),
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return _ProductCard(
                                    product: product,
                                    onTapDetail: () => _showProductDetailSheet(context, product),
                                    onAdd: () {
                                      ref.read(cartProvider.notifier).addToCart(product);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${context.tr('Failed to load register catalog.')}\n$error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.name ?? context.tr('Cashier');
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);

    final hour = DateTime.now().hour;
    String greeting = 'Good Afternoon';
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.computer_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('Active Register'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${context.tr(greeting)}, $name',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('No alerts'))),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _showCartSheet(context, ref);
                },
                icon: Badge(
                  label: cart.itemCount > 0 ? Text('${cart.itemCount}') : null,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final selectedTable = ref.watch(selectedTableProvider);
    final tables = ref.watch(tablesListProvider);
    final allCarts = ref.watch(tableCartsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded, 
                      color: AppTheme.primaryLight, 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Table & Take Away Registers',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAllTablesDialog(context, ref),
                  icon: const Icon(Icons.grid_view_rounded, size: 16),
                  label: const Text(
                    'Grid View',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Scrollable horizontal list
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: tables.length + 1, // +1 for the "Add custom" button
              itemBuilder: (context, index) {
                if (index == tables.length) {
                  // Add custom table/take-away
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: InkWell(
                      onTap: () => _showAddCustomTableDialog(context, ref),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBg : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                final table = tables[index];
                final isSelected = table == selectedTable;
                final cart = allCarts[table];
                final hasItems = cart != null && cart.items.isNotEmpty;
                final itemCount = cart?.itemCount ?? 0;
                final total = cart?.total ?? 0.0;
                
                final isTakeAway = table.toLowerCase().contains('take away');

                Color itemBgColor;
                Color itemBorderColor;
                Color textColor;
                Color subtextColor;

                if (isSelected) {
                  itemBgColor = AppTheme.primary;
                  itemBorderColor = AppTheme.primary;
                  textColor = Colors.white;
                  subtextColor = Colors.white70;
                } else if (hasItems) {
                  itemBgColor = AppTheme.primary.withOpacity(0.08);
                  itemBorderColor = AppTheme.primaryLight.withOpacity(0.5);
                  textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
                  subtextColor = AppTheme.primaryLight;
                } else {
                  itemBgColor = isDark ? AppTheme.darkBg : Colors.grey.shade50;
                  itemBorderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
                  textColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
                  subtextColor = Colors.grey;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedTableProvider.notifier).state = table;
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: itemBgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: itemBorderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isTakeAway ? Icons.takeout_dining : Icons.restaurant_menu,
                                color: isSelected 
                                    ? Colors.white 
                                    : (hasItems ? AppTheme.primaryLight : Colors.grey),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                table,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (hasItems) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$itemCount items • \$${total.toStringAsFixed(2)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: subtextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text(
                              'Empty',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: subtextColor,
                                fontSize: 9,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllTablesDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final theme = Theme.of(context);
            final selectedTable = ref.watch(selectedTableProvider);
            final tables = ref.watch(tablesListProvider);
            final allCarts = ref.watch(tableCartsProvider);

            return DefaultTabController(
              length: 4,
              child: AlertDialog(
                titlePadding: const EdgeInsets.fromLTRB(20, 16, 10, 0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Table Registers Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppTheme.primaryLight,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryLight,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'Dine In'),
                          Tab(text: 'Take Away'),
                          Tab(text: 'Occupied'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. All
                            _buildGrid(context, ref, tables, selectedTable, allCarts),
                            // 2. Dine In
                            _buildGrid(
                              context, 
                              ref, 
                              tables.where((t) => !t.toLowerCase().contains('take away')).toList(), 
                              selectedTable, 
                              allCarts
                            ),
                            // 3. Take Away
                            _buildGrid(
                              context, 
                              ref, 
                              tables.where((t) => t.toLowerCase().contains('take away')).toList(), 
                              selectedTable, 
                              allCarts
                            ),
                            // 4. Occupied
                            _buildGrid(
                              context, 
                              ref, 
                              tables.where((t) => allCarts[t]?.items.isNotEmpty == true).toList(), 
                              selectedTable, 
                              allCarts
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddCustomTableDialog(context, ref);
                    },
                    child: const Text('Add Register'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrid(
    BuildContext context, 
    WidgetRef ref, 
    List<String> tablesList, 
    String selectedTable,
    Map<String, CartState> allCarts,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (tablesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No tables found in this category.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: tablesList.length,
      itemBuilder: (context, index) {
        final table = tablesList[index];
        final isSelected = table == selectedTable;
        final cart = allCarts[table];
        final hasItems = cart != null && cart.items.isNotEmpty;
        final itemCount = cart?.itemCount ?? 0;
        final total = cart?.total ?? 0.0;
        final isTakeAway = table.toLowerCase().contains('take away');

        Color cardColor;
        Color borderColor;
        Color textColor;

        if (isSelected) {
          cardColor = AppTheme.primary;
          borderColor = AppTheme.primary;
          textColor = Colors.white;
        } else if (hasItems) {
          cardColor = AppTheme.primary.withOpacity(0.08);
          borderColor = AppTheme.primaryLight.withOpacity(0.6);
          textColor = isDark ? Colors.white : Colors.black87;
        } else {
          cardColor = isDark ? AppTheme.darkCard : Colors.grey.shade50;
          borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
          textColor = isDark ? Colors.white70 : Colors.black87;
        }

        return InkWell(
          onTap: () {
            ref.read(selectedTableProvider.notifier).state = table;
            Navigator.pop(context); // Close overview
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTakeAway ? Icons.takeout_dining : Icons.table_restaurant_rounded,
                  color: isSelected ? Colors.white70 : (hasItems ? AppTheme.primaryLight : Colors.grey),
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  table,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasItems)
                  Text(
                    '$itemCount item${itemCount > 1 ? 's' : ''}\n\$${total.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : AppTheme.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  )
                else
                  Text(
                    'Empty',
                    style: TextStyle(
                      color: isSelected ? Colors.white54 : Colors.grey,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCustomTableDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Custom Table / Register',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a name for the table or take away register:',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Table 11, Take Away C',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final list = ref.read(tablesListProvider);
                  if (!list.contains(name)) {
                    ref.read(tablesListProvider.notifier).state = [...list, name];
                  }
                  ref.read(selectedTableProvider.notifier).state = name;
                  Navigator.pop(context);
                }
              },
              child: const Text('Add & Select'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    List<Product> products,
    String selected,
    Function(String) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = ['All Items'];
    for (final p in products) {
      final cat = p.categoryName ?? 'Other';
      if (cat.isNotEmpty && !categories.contains(cat)) {
        categories.add(cat);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            context.tr('Register Catalog'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selected;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: InkWell(
                  onTap: () => onSelected(category),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark ? AppTheme.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr(category),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all items':
        return Icons.grid_view_rounded;
      case 'hot drink':
      case 'coffee':
      case 'drinks':
      case 'beverages':
        return Icons.coffee_rounded;
      case 'cold drink':
      case 'juice':
      case 'soda':
        return Icons.local_drink_rounded;
      case 'breakfast':
      case 'food':
      case 'bakery':
        return Icons.breakfast_dining_rounded;
      case 'muffin':
      case 'dessert':
      case 'desserts':
      case 'cake':
        return Icons.cake_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  void _showProductDetailSheet(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final isLowStock = product.isLowStock;
            final stockColor = isLowStock ? Colors.orange.shade800 : AppTheme.success;

            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            context.tr('Item Details'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.local_cafe_rounded,
                              size: 80,
                              color: isDark ? AppTheme.darkTextDisabled : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product.categoryName != null && product.categoryName!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          product.categoryName!,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.name,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU: ${product.sku.isNotEmpty ? product.sku : "N/A"}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Stock available: ${product.stockQuantity}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: stockColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            context.tr('Description'),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description ?? 'Freshly prepared item, monitored by standard registers.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('Quantity to Add'),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setState(() => quantity--);
                                        }
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        '$quantity',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () {
                                        if (quantity < product.stockQuantity) {
                                          setState(() => quantity++);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Cannot add more than stock limit (${product.stockQuantity})'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart_rounded),
                                  onPressed: product.isInStock
                                      ? () {
                                          for (int i = 0; i < quantity; i++) {
                                            ref.read(cartProvider.notifier).addToCart(product);
                                          }
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added $quantity x ${product.name} to Cart'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      : null,
                                  label: Text(
                                    product.isInStock ? context.tr('Add to Register') : context.tr('Out of Stock'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Future<void> _showCartSheet(BuildContext context, WidgetRef ref) async {
    final selectedTable = ref.read(selectedTableProvider);
    final TextEditingController promoController = TextEditingController();
    final TextEditingController cashReceivedController = TextEditingController();
    final TextEditingController tableNumberController = TextEditingController(
      text: selectedTable,
    );

    String appliedCode = '';
    const double deliveryFee = 1.0;
    String promoError = '';
    String promoSuccess = '';

    String orderType = selectedTable.toLowerCase().contains('take away') ? 'Take Away' : 'Dine In'; // Dine In vs Take Away
    String paymentMethod = 'Cash'; // Cash vs Card vs QR Code
    double cashReceived = 0.0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                final cart = ref.watch(cartProvider);
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            final subtotal = cart.total;
            double finalDiscount = 0;
            if (appliedCode == 'WELCOME10') {
              finalDiscount = subtotal * 0.10;
            } else if (appliedCode == 'DISCOUNT5') {
              finalDiscount = subtotal > 5 ? 5.00 : subtotal;
            }
            final total = subtotal - finalDiscount + deliveryFee;
            final actualTotal = total < 0 ? 0.0 : total;

            final changeDue = cashReceived >= actualTotal ? cashReceived - actualTotal : 0.0;

            // Generate standard cash denominations based on total
            List<double> getQuickCashOptions(double total) {
              final options = <double>[total];
              final standardBills = [5.0, 10.0, 20.0, 50.0, 100.0];
              for (final bill in standardBills) {
                if (bill > total && !options.contains(bill)) {
                  options.add(bill);
                }
              }
              return options.take(4).toList();
            }
            final cashOptions = getQuickCashOptions(actualTotal);

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Handle Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('Current Transaction'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(cartProvider.notifier).clearCart();
                            },
                            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                            label: Text(
                              context.tr('Clear'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Summary
                            Text(
                              context.tr('Order Items'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (cart.items.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        context.tr('Register is empty.'),
                                        style: TextStyle(color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = cart.items[index];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.darkCard : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: ProductImage(
                                            imageUrl: item.product.imageUrl,
                                            placeholder: Icon(Icons.coffee_outlined, color: Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                // Quantity Incrementor/Decrementor inline
                                                InkWell(
                                                  onTap: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Icon(Icons.remove, size: 12),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Icon(Icons.add, size: 12),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '@ \$${item.product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                            onPressed: () {
                                              ref.read(cartProvider.notifier).removeFromCart(item.product.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 20),

                            // POS METADATA: Order Type & Table
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('Order Type'),
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => orderType = 'Dine In'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: orderType == 'Dine In' ? AppTheme.primary : (isDark ? AppTheme.darkCard : Colors.grey.shade200),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.restaurant, color: orderType == 'Dine In' ? Colors.white : Colors.grey, size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(context.tr('Dine In'), style: TextStyle(color: orderType == 'Dine In' ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => orderType = 'Take Away'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: orderType == 'Take Away' ? AppTheme.primary : (isDark ? AppTheme.darkCard : Colors.grey.shade200),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.takeout_dining, color: orderType == 'Take Away' ? Colors.white : Colors.grey, size: 16),
                                                    const SizedBox(width: 6),
                                                    Text(context.tr('Take Away'), style: TextStyle(color: orderType == 'Take Away' ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('Table / Queue #'),
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: tableNumberController,
                                        readOnly: true,
                                        keyboardType: TextInputType.text,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText: context.tr('e.g. Table 5, Queue 12'),
                                          filled: true,
                                          fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Payment Method
                            Text(
                              context.tr('Payment Method'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => paymentMethod = 'Cash'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: paymentMethod == 'Cash' ? AppTheme.primary : (isDark ? AppTheme.darkCard : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: paymentMethod == 'Cash' ? AppTheme.primary : (isDark ? AppTheme.darkBorder : Colors.grey.shade300)),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.payments_outlined, color: paymentMethod == 'Cash' ? Colors.white : Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(context.tr('Cash'), style: TextStyle(color: paymentMethod == 'Cash' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => paymentMethod = 'Card'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: paymentMethod == 'Card' ? AppTheme.primary : (isDark ? AppTheme.darkCard : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: paymentMethod == 'Card' ? AppTheme.primary : (isDark ? AppTheme.darkBorder : Colors.grey.shade300)),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.credit_card_outlined, color: paymentMethod == 'Card' ? Colors.white : Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(context.tr('Card'), style: TextStyle(color: paymentMethod == 'Card' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => paymentMethod = 'QR Code'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: paymentMethod == 'QR Code' ? AppTheme.primary : (isDark ? AppTheme.darkCard : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: paymentMethod == 'QR Code' ? AppTheme.primary : (isDark ? AppTheme.darkBorder : Colors.grey.shade300)),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.qr_code_scanner_outlined, color: paymentMethod == 'QR Code' ? Colors.white : Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(context.tr('QR Code'), style: TextStyle(color: paymentMethod == 'QR Code' ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // CASH CHANGE REGISTER details (only show if Cash payment selected)
                            if (paymentMethod == 'Cash') ...[
                              Text(
                                context.tr('Cash Tendered'),
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: cashReceivedController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        prefixText: '\$ ',
                                        filled: true,
                                        fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          cashReceived = double.tryParse(val) ?? 0.0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Denomination Quick Chips
                              SizedBox(
                                height: 38,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cashOptions.length,
                                  itemBuilder: (context, i) {
                                    final cashValue = cashOptions[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text('\$${cashValue.toStringAsFixed(2)}'),
                                        onPressed: () {
                                          setState(() {
                                            cashReceived = cashValue;
                                            cashReceivedController.text = cashValue.toStringAsFixed(2);
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Change Due
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cashReceived >= actualTotal
                                      ? AppTheme.success.withOpacity(0.08)
                                      : Colors.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cashReceived >= actualTotal
                                          ? context.tr('Change Due:')
                                          : context.tr('Remaining Balance:'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cashReceived >= actualTotal ? AppTheme.success : Colors.amber.shade900,
                                      ),
                                    ),
                                    Text(
                                      cashReceived >= actualTotal
                                          ? '\$${changeDue.toStringAsFixed(2)}'
                                          : '\$${(actualTotal - cashReceived).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: cashReceived >= actualTotal ? AppTheme.success : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Coupon Section
                            Text(
                              context.tr('POS Discount Coupon'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: promoController,
                                    decoration: InputDecoration(
                                      hintText: context.tr('Enter Promo Code'),
                                      filled: true,
                                      fillColor: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  onPressed: () {
                                    final val = promoController.text.trim().toUpperCase();
                                    if (val == 'WELCOME10') {
                                      setState(() {
                                        appliedCode = 'WELCOME10';
                                        promoSuccess = context.tr('Applied 10% Discount!');
                                        promoError = '';
                                      });
                                    } else if (val == 'DISCOUNT5') {
                                      setState(() {
                                        appliedCode = 'DISCOUNT5';
                                        promoSuccess = context.tr('Applied \$5.00 Off Discount!');
                                        promoError = '';
                                      });
                                    } else if (val.isEmpty) {
                                      setState(() {
                                        appliedCode = '';
                                        promoSuccess = '';
                                        promoError = '';
                                      });
                                    } else {
                                      setState(() {
                                        appliedCode = '';
                                        promoSuccess = '';
                                        promoError = context.tr('Invalid Code. Try WELCOME10 or DISCOUNT5.');
                                      });
                                    }
                                  },
                                  child: Text(context.tr('Apply')),
                                ),
                              ],
                            ),
                            if (promoError.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(promoError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            if (promoSuccess.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(promoSuccess, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 24),

                            // Totals Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('Sub total'),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                                ),
                                Text(
                                  '\$${subtotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (finalDiscount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr('Discount'),
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  Text(
                                    '-\$${finalDiscount.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('Service charges'),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                                ),
                                Text(
                                  '\$${deliveryFee.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('Grand Total'),
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${actualTotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: (cart.items.isEmpty || (paymentMethod == 'Cash' && cashReceived < actualTotal))
                              ? null
                              : () async {
                                  try {
                                    final tableRef = tableNumberController.text.trim();
                                    final notesParts = [
                                      '${context.tr('Order Type')}: $orderType',
                                      if (tableRef.isNotEmpty) '${context.tr('Table/Ref')}: $tableRef',
                                      if (paymentMethod == 'Cash') ...[
                                        '${context.tr('Cash Tendered')}: \$${cashReceived.toStringAsFixed(2)}',
                                        '${context.tr('Change Due:')} \$${changeDue.toStringAsFixed(2)}'
                                      ],
                                      if (appliedCode.isNotEmpty) '${context.tr('Promo applied')}: $appliedCode'
                                    ];

                                    final order = await ref
                                        .read(posApiServiceProvider)
                                        .createOrder(
                                          items: cart.items,
                                          notes: notesParts.join(' | '),
                                          paymentMethod: paymentMethod.toLowerCase(),
                                        );

                                    ref.read(cartProvider.notifier).clearCart();

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _showCheckoutSuccessDialog(context, order, orderType, paymentMethod, cashReceived, changeDue);
                                      ref.invalidate(posProductsProvider);
                                      ref.invalidate(posOrdersProvider);
                                      ref.invalidate(receiptPerformanceProvider);
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${context.tr('Checkout failed:')} $error'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            context.tr('Process Transaction'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
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
  },
);
  }

  void _showCheckoutSuccessDialog(
    BuildContext context,
    Order order,
    String orderType,
    String paymentMethod,
    double cashReceived,
    double changeDue,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
          title: Text(context.tr('Transaction Completed!')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '${context.tr('Receipt')}: ${order.receiptNumber ?? order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.tr('Service Type')}:'),
                    Text(orderType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.tr('Payment Mode')}:'),
                    Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.tr('Grand Total')}:'),
                    Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (paymentMethod == 'Cash') ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${context.tr('Tendered')}:'),
                      Text('\$${cashReceived.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${context.tr('Change Returned')}:', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('\$${changeDue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    context.tr('Simulating thermal print receipt...'),
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('Simulated Printing Receipt to Local Thermal Printer')),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(context.tr('Print')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Done')),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTapDetail,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTapDetail;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBorder
        : AppTheme.lightBorder;
    final addEnabled = product.isInStock;
    final theme = Theme.of(context);

    return InkWell(
      onTap: addEnabled ? onAdd : null, // cashier workflow: tap card directly increments quantity
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppTheme.darkBg
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        ProductImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          placeholder: _placeholder(theme),
                        ),
                        // Information Info button to check item details (essential for cashier descriptions)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black.withOpacity(0.4),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onTapDetail,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (product.categoryName != null && product.categoryName!.isNotEmpty)
                Text(
                  product.categoryName!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          product.isInStock
                              ? '${context.tr('Stock')}: ${product.stockQuantity}'
                              : context.tr('Out of stock'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: product.isInStock
                                ? (product.isLowStock ? Colors.orange : AppTheme.success)
                                : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: addEnabled ? AppTheme.primary : theme.disabledColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: addEnabled ? onAdd : null,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.brightness == Brightness.dark ? AppTheme.darkCard : const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_cafe_outlined,
        size: 36,
        color: theme.brightness == Brightness.dark ? AppTheme.darkTextSecondary : Colors.grey.shade400,
      ),
    );
  }
}
