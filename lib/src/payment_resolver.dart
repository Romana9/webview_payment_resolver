import 'backoff_poller.dart';
import 'order_status_client.dart';
import 'payment_state.dart';
import 'resolution_result.dart';
import 'return_url_matcher.dart';

/// Resolves the five ways a WebView payment flow can end: return
/// redirect, cancel redirect, user exit, bank-app hand-off, and missed
/// callback.
///
/// The last three are unknown rather than failed, and are settled by
/// asking the server through [OrderStatusClient].
class PaymentResolver {
  /// Creates a resolver.
  ///
  /// [returnUrl] and [cancelUrl] match on scheme + host + path.
  /// [orderIdParam] is the query parameter carrying the order id, and
  /// [backoff] is the retry schedule in seconds for
  /// [confirmWithBackoff].
  PaymentResolver({
    required this.client,
    required Uri returnUrl,
    required Uri cancelUrl,
    this.orderIdParam = 'order_id',
    List<int> backoff = const [2, 4, 8, 16],
  })  : _returnMatcher = ReturnUrlMatcher(target: returnUrl),
        _cancelMatcher = ReturnUrlMatcher(target: cancelUrl),
        _poller = BackoffPoller(
          delays: [for (final seconds in backoff) Duration(seconds: seconds)],
        );

  /// The app's source of truth for server-side payment status.
  final OrderStatusClient client;

  /// The query parameter carrying the order id on redirects.
  final String orderIdParam;

  final ReturnUrlMatcher _returnMatcher;
  final ReturnUrlMatcher _cancelMatcher;
  final BackoffPoller _poller;

  /// Handles a WebView navigation to [url].
  ///
  /// Returns null for ordinary in-flow navigations. The cancel URL is
  /// declined immediately; the return URL is verified with the server,
  /// since gateways also redirect there for voided transactions.
  Future<ResolutionResult?> onNavigation(Uri url) async {
    if (_cancelMatcher.matches(url)) {
      return ResolutionResult.declined(
        orderId: _cancelMatcher.orderIdOf(url, orderIdParam),
        reason: 'Gateway redirected to the cancel URL',
      );
    }
    if (_returnMatcher.matches(url)) {
      final orderId = _returnMatcher.orderIdOf(url, orderIdParam);
      if (orderId == null) {
        return const ResolutionResult.confirming();
      }
      return _verify(orderId,
          whenUnknown: ResolutionResult.confirming(orderId: orderId));
    }
    return null;
  }

  /// Handles the user leaving the payment screen.
  ///
  /// Asks the server first, since leaving on an unknown state can orphan
  /// a captured charge.
  Future<ResolutionResult> onUserExit(String orderId) => _verify(orderId,
      whenUnknown: ResolutionResult.askToCancel(orderId: orderId));

  /// Handles the app returning to the foreground after a bank-app or
  /// external 3-D Secure hand-off.
  Future<ResolutionResult> onResumed(String orderId) => _verify(orderId,
      whenUnknown: ResolutionResult.confirming(orderId: orderId));

  /// Polls the server on the backoff schedule when no redirect arrived.
  ///
  /// Still resolves to confirming, never declined, if the schedule runs
  /// out without an answer.
  Future<ResolutionResult> confirmWithBackoff(String orderId) async {
    final state = await _poller.poll<PaymentState>(() async {
      final status = await client.statusOf(orderId);
      return status is Unknown ? null : status;
    });
    return switch (state) {
      Paid() => ResolutionResult.paid(orderId: orderId),
      Declined(reason: final reason) =>
        ResolutionResult.declined(orderId: orderId, reason: reason),
      Unknown() || null => ResolutionResult.confirming(orderId: orderId),
    };
  }

  Future<ResolutionResult> _verify(
    String orderId, {
    required ResolutionResult whenUnknown,
  }) async {
    final status = await client.statusOf(orderId);
    return switch (status) {
      Paid() => ResolutionResult.paid(orderId: orderId),
      Declined(reason: final reason) =>
        ResolutionResult.declined(orderId: orderId, reason: reason),
      Unknown() => whenUnknown,
    };
  }
}
