import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import 'cart_provider.dart';
import 'product_provider.dart';
import 'supabase_provider.dart';
import 'user_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(supabaseProvider));
});

// The signed-in customer's own orders, newest first.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return [];
  return ref.watch(orderServiceProvider).fetchMyOrders(userId);
});

final adminOrdersProvider =
    AsyncNotifierProvider<AdminOrdersNotifier, List<Order>>(
      AdminOrdersNotifier.new,
    );

class AdminOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() {
    return ref.read(orderServiceProvider).fetchAllOrders();
  }

  Future<void> updateStatus(int orderId, String status) async {
    await ref.read(orderServiceProvider).updateStatus(orderId, status);
    ref.invalidateSelf();
    ref.invalidate(myOrdersProvider);
  }
}

// Holds the result of the last checkout: loading while it runs, the receipt
// when it worked, or the error when it failed.
final checkoutProvider = AsyncNotifierProvider<CheckoutNotifier, OrderReceipt?>(
  CheckoutNotifier.new,
);

class CheckoutNotifier extends AsyncNotifier<OrderReceipt?> {
  @override
  Future<OrderReceipt?> build() async => null;

  Future<OrderReceipt?> checkout() async {
    final items = ref.read(cartProvider);
    state = const AsyncLoading();
    // guard() catches the error and stores it in state instead of throwing.
    state = await AsyncValue.guard(
      () => ref.read(orderServiceProvider).placeOrder(items),
    );

    // Stock changed in either case, so reload the product list.
    ref.invalidate(productProvider);
    final receipt = state.value;
    if (receipt != null) {
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
    }
    return receipt;
  }
}
