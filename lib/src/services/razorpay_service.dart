import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  RazorpayService({
    required this.onSuccess,
    required this.onError,
    required this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  late final Razorpay _razorpay;
  final void Function(PaymentSuccessResponse) onSuccess;
  final void Function(PaymentFailureResponse) onError;
  final void Function(ExternalWalletResponse) onExternalWallet;

  void openCheckout({
    required int amountInRupees,
    required String name,
    required String email,
    required String contact,
    String orderId = 'order_test_local',
    String keyId = 'rzp_test_1234567890abcdef',
  }) {
    final options = {
      'key': keyId,
      'amount': amountInRupees * 100,
      'currency': 'INR',
      'name': 'MOSPL',
      'description': 'Premium leather products',
      'order_id': orderId,
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'theme': {'color': '#0B63CE'},
      'retry': {'enabled': true, 'max_count': 2},
    };
    try {
      _razorpay.open(options);
    } catch (error) {
      debugPrint('Razorpay open failed: $error');
    }
  }

  void dispose() => _razorpay.clear();
}
