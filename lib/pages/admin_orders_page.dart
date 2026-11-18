import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_provider.dart';
import '../utils/errors.dart';
import '../widgets/message_view.dart';
import '../widgets/order_card.dart';

// Admin only: every customer's orders, newest first, with a status control.
class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const MessageView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet.',
              detail: 'Orders appear here after customers check out.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: OrderCard(
                    order: order,
                    onStatusChanged: (status) async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(adminOrdersProvider.notifier)
                            .updateStatus(order.id, status);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order #${order.id} is now ${statusLabel(status)}',
                            ),
                          ),
                        );
                      } catch (error) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(friendlyError(error))),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => MessageView(
          icon: isPermissionDenied(error)
              ? Icons.lock_outline
              : Icons.cloud_off,
          title: 'Could not load orders.',
          detail: friendlyError(error),
          buttonLabel: 'Try again',
          onPressed: () => ref.invalidate(adminOrdersProvider),
        ),
      ),
    );
  }
}
