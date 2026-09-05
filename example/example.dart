// ignore_for_file: avoid_print

import 'package:webview_payment_resolver/webview_payment_resolver.dart';

/// Stand-in for a real order endpoint; flips to paid after two checks.
class FakeOrderStatusClient implements OrderStatusClient {
  int _checks = 0;

  @override
  Future<PaymentState> statusOf(String orderId) async {
    _checks++;
    return _checks >= 3 ? const Paid() : const Unknown();
  }
}

Future<void> main() async {
  final resolver = PaymentResolver(
    client: FakeOrderStatusClient(),
    returnUrl: Uri.parse('https://example.com/pay/return'),
    cancelUrl: Uri.parse('https://example.com/pay/cancel'),
    orderIdParam: 'order_id',
    backoff: const [1, 1, 1],
  );

  // Non-terminal URLs resolve to null: let the WebView load them.
  final midFlow = await resolver.onNavigation(
    Uri.parse('https://example.com/gateway/card-entry'),
  );
  print('mid-flow navigation: $midFlow');

  final bankApp = Uri.parse('mybank://approve?tx=99');
  if (!SchemePolicy.webOnly.allows(bankApp)) {
    print('hand off externally: $bankApp');
  }

  final onExit = await resolver.onUserExit('order-99');
  print('on exit: ${onExit.action}');

  final confirmed = await resolver.confirmWithBackoff('order-99');
  print('after polling: ${confirmed.state} -> ${confirmed.action}');
}
