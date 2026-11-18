import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_provider.dart';
import '../utils/errors.dart';
import '../widgets/message_view.dart';
import '../widgets/order_card.dart';

// The signed-in customer's own orders, newest first.
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return MessageView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet.',
              detail: 'Your orders will appear here after checkout.',
              buttonLabel: 'Start shopping',
              onPressed: () => Navigator.pop(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: OrderCard(order: orders[index]),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => MessageView(
          icon: isPermissionDenied(error)
              ? Icons.lock_outline
              : Icons.cloud_off,
          title: 'Could not load your orders.',
          detail: friendlyError(error),
          buttonLabel: 'Try again',
          onPressed: () => ref.invalidate(myOrdersProvider),
        ),
      ),
    );
  }
}
