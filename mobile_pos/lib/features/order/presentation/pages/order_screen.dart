import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../pos/presentation/providers/pos_provider.dart';
import '../../../pos/domain/entities/pos_entities.dart' as pos_entities;

/// Order management screen
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(posOrdersProvider);
    final performanceAsync = ref.watch(receiptPerformanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Orders')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(posOrdersProvider);
          ref.invalidate(receiptPerformanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            performanceAsync.when(
              data: (data) => _PerformanceHeader(data: data),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Recent Receipts'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(context.tr('No receipts available yet.')),
                    ),
                  );
                }

                return Column(
                  children: orders
                      .map((order) => _OrderTile(order: order))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Failed to load receipts.\n$error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceHeader extends StatelessWidget {
  const _PerformanceHeader({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Receipts', '${data['totalReceipts'] ?? 0}'),
      ('Completed', '${data['completedReceipts'] ?? 0}'),
      ('Revenue', '\$${((data['totalRevenue'] ?? 0) as num).toStringAsFixed(2)}'),
      (
        'Average',
        '\$${((data['averageReceiptValue'] ?? 0) as num).toStringAsFixed(2)}',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (metric) => Container(
              width: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkBorder
                      : AppTheme.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.$1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metric.$2,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final pos_entities.Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkBorder
              : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.receiptNumber ?? order.id,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.items.length} items • ${order.paymentMethod ?? 'cash'} • ${order.status.name}',
          ),
          const SizedBox(height: 6),
          Text(
            order.createdAt.toLocal().toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
