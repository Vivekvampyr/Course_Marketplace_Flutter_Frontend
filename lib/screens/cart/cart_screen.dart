import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/cart_model.dart';
import '../../providers/cart_provider.dart';
import '../../config/api_config.dart';
import '../../services/cart_service.dart';
import '../../utils/js_interop.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'
    if (dart.library.html) '../../utils/razorpay_stub.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final CartService _cartService = CartService();
  bool _paymentLoading = false;
  dynamic _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initRazorpay();
    // ← Refresh cart every time screen opens
    Future.microtask(() => ref.read(cartProvider.notifier).fetchCart());
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ── Payment Success ──────────────────────────────────
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _cartService.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      if (mounted) {
        ref.read(cartProvider.notifier).fetchCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! You are enrolled!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _paymentLoading = false);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _paymentLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _paymentLoading = false);
  }

  // ── Initiate Checkout ────────────────────────────────
  Future<void> _checkout() async {
    setState(() => _paymentLoading = true);

    setState(() => _paymentLoading = true);

    // Safety timeout — reset after 30s if nothing happens
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _paymentLoading) {
        setState(() => _paymentLoading = false);
      }
    });

    try {
      final orderData = await _cartService.createRazorpayOrder();
      debugPrint('Order created: $orderData'); // ← check terminal

      if (kIsWeb) {
        _showWebPaymentDialog(orderData);
        setState(() => _paymentLoading = false);
        return;
      }

      // Android
      if (_razorpay == null) {
        throw Exception('Razorpay not initialized');
      }

      final options = {
        'key': ApiConfig.razorpayKeyId,
        'amount': orderData['amount'],
        'currency': 'INR',
        'order_id': orderData['razorpay_order_id'],
        'name': 'Course Marketplace',
        'description': 'Course Purchase',
        'prefill': {'contact': '9000000000', 'email': 'test@razorpay.com'},
        'theme': {'color': '#6C63FF'},
      };

      debugPrint('Opening Razorpay with options: $options'); // ← check terminal
      _razorpay.open(options);
      // ← DO NOT set _paymentLoading = false here
      // It will be set in success/error callbacks
    } catch (e) {
      debugPrint('Checkout error: $e');
      setState(() => _paymentLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWebPaymentDialog(Map<String, dynamic> orderData) {
    openRazorpayWeb(
      keyId: ApiConfig.razorpayKeyId,
      amount: orderData['amount'] as int,
      orderId: orderData['razorpay_order_id'],
      onSuccess: (paymentId, orderId, signature) {
        _handleWebPaymentSuccess(paymentId, orderId, signature);
      },
    );
    setState(() => _paymentLoading = false);
  }

  Future<void> _handleWebPaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    try {
      await _cartService.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
      if (mounted) {
        ref.read(cartProvider.notifier).fetchCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! You are enrolled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          cartAsync
                  .whenData(
                    (items) =>
                        items.isNotEmpty
                            ? TextButton(
                              onPressed: () async {
                                await _cartService.removeFromCart(0);
                                ref.read(cartProvider.notifier).fetchCart();
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : const SizedBox(),
                  )
                  .valueOrNull ??
              const SizedBox(),
        ],
      ),
      body: cartAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
        error: (e, _) => Center(child: Text(e.toString())),
        data:
            (items) =>
                items.isEmpty
                    ? _buildEmptyCart()
                    : Column(
                      children: [
                        // ── Cart Items ─────────────────────────
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildCartItem(item);
                            },
                          ),
                        ),

                        // ── Order Summary ──────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${items.length} item${items.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '₹${total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _paymentLoading ? null : _checkout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child:
                                      _paymentLoading
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                          : const Text(
                                            'Proceed to Payment',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child:
                item.course.thumbnail != null
                    ? Image.network(
                      '${ApiConfig.baseUrl}/${item.course.thumbnail}',
                      width: 100,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                    : _thumbPlaceholder(),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.course.category ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.course.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await ref.read(cartProvider.notifier).removeItem(item.courseId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removed from cart')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add courses to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 100,
      height: 90,
      color: const Color(0xFF6C63FF).withOpacity(0.1),
      child: const Icon(Icons.play_lesson_rounded, color: Color(0xFF6C63FF)),
    );
  }
}
