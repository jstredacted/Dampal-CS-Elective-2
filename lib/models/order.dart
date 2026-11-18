// Statuses an admin can choose. Checkout always saves an order as "done".
const List<String> orderStatuses = [
  'done',
  'shipped',
  'delivered',
  'cancelled',
];

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int id;
  // null when the product was deleted after the order was placed.
  final int? productId;
  // Saved copies of the name and price at checkout time, so old orders stay
  // correct even if the product is edited or deleted later.
  final String productName;
  final int quantity;
  final double unitPrice;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String? ?? 'Removed product',
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.customerName,
  });

  final int id;
  final String userId;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  // Only filled in on the admin order list.
  final String? customerName;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromMap(Map<String, dynamic> map) {
    final itemMaps = map['order_items'] as List<dynamic>? ?? const [];
    final profile = map['profiles'] as Map<String, dynamic>?;
    String? customerName;
    if (profile != null) {
      final name = '${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}'
          .trim();
      customerName = name.isNotEmpty
          ? name
          : profile['email'] as String? ?? 'Customer';
    }

    return Order(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      status: map['status'] as String,
      total: (map['total'] as num).toDouble(),
      // Supabase sends times in UTC; toLocal() shows the phone's time zone.
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      items: itemMaps
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      customerName: customerName,
    );
  }
}

// What the place_order database function sends back after checkout.
class OrderReceipt {
  const OrderReceipt({required this.orderId, required this.total});

  final int orderId;
  final double total;

  factory OrderReceipt.fromMap(Map<String, dynamic> map) {
    return OrderReceipt(
      orderId: map['order_id'] as int,
      total: (map['total'] as num).toDouble(),
    );
  }
}
