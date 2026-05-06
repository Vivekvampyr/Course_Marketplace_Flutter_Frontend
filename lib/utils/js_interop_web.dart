import 'dart:js' as js;

void openRazorpayWeb({
  required String keyId,
  required int amount,
  required String orderId,
  required Function(String, String, String) onSuccess,
}) {
  js.context['razorpayCallback'] = (paymentId, rzpOrderId, signature) {
    onSuccess(paymentId, rzpOrderId, signature);
  };

  js.context.callMethod('eval', [
    '''
    var options = {
      key: "$keyId",
      amount: $amount,
      currency: "INR",
      order_id: "$orderId",
      name: "Course Marketplace",
      description: "Course Purchase",
      theme: { color: "#6C63FF" },
      handler: function(response) {
        window.razorpayCallback(
          response.razorpay_payment_id,
          response.razorpay_order_id,
          response.razorpay_signature
        );
      }
    };
    var rzp = new Razorpay(options);
    rzp.open();
  ''',
  ]);
}
