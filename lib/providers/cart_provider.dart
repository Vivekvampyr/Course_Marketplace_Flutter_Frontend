import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';

final cartServiceProvider = Provider((ref) => CartService());

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>(
      (ref) => CartNotifier(ref.read(cartServiceProvider)),
    );

class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  final CartService _service;
  CartNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getCart();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeItem(int courseId) async {
    await _service.removeFromCart(courseId);
    await fetchCart();
  }

  double get totalAmount {
    return state.valueOrNull?.fold(
          0.0,
          (sum, item) => sum! + item.course.price,
        ) ??
        0.0;
  }
}

// Total amount provider
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.valueOrNull?.fold(0.0, (sum, item) => sum! + item.course.price) ??
      0.0;
});
