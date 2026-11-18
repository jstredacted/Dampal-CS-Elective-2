import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  // Only product ids and quantities are sent. The place_order database
  // function reads the real names, prices, and stock itself, saves the order
  // and its items, and lowers the stock, all as one operation.
  Future<OrderReceipt> placeOrder(List<CartItem> items) async {
    final rows = await _client.rpc<List<dynamic>>(
      'place_order',
      params: {
        'p_items': [
          for (final item in items)
            {'product_id': item.product.id, 'quantity': item.quantity},
        ],
      },
    );
    return OrderReceipt.fromMap(rows.first as Map<String, dynamic>);
  }

  // RLS already hides other customers' orders; the eq() makes it explicit.
  Future<List<Order>> fetchMyOrders(String userId) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map(Order.fromMap).toList();
  }

  // Admins can read every order, plus the customer's name from profiles.
  Future<List<Order>> fetchAllOrders() async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*), profiles(firstname, lastname, email)')
        .order('created_at', ascending: false);
    return data.map(Order.fromMap).toList();
  }

  Future<void> updateStatus(int orderId, String status) async {
    final updated = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select();
    // RLS blocks updates by returning zero rows instead of an error.
    if (updated.isEmpty) {
      throw const PostgrestException(
        message: 'Only admins can change an order status.',
        code: '42501',
      );
    }
  }
}
