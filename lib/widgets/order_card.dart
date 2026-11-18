import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/format.dart';

// One order with its status, date, total, and items. Admins also get a
// dropdown to change the status (onStatusChanged is null for customers).
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onStatusChanged});

  final Order order;
  final ValueChanged<String>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (onStatusChanged == null)
                  StatusChip(status: order.status)
                else
                  DropdownButton<String>(
                    value: order.status,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final status in orderStatuses)
                        DropdownMenuItem(
                          value: status,
                          child: Text(statusLabel(status)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != order.status) {
                        onStatusChanged!(value);
                      }
                    },
                  ),
              ],
            ),
            if (order.customerName != null)
              Text(order.customerName!, style: theme.textTheme.bodyMedium),
            Text(
              formatDateTime(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.quantity} × ${item.productName}'),
                    ),
                    Text(formatPeso(item.subtotal)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Text(
                  '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'Total ${formatPeso(order.total)}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String statusLabel(String status) =>
    status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = status == 'cancelled' ? scheme.error : scheme.primary;
    return Chip(
      label: Text(statusLabel(status)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
