import 'payment_state.dart';

/// The app's source of truth for a payment's server-side status.
///
/// Implement it against your own order endpoint, and return [Unknown] for
/// anything you can't prove — including network errors while checking.
///
/// ```dart
/// class ApiOrderStatusClient implements OrderStatusClient {
///   @override
///   Future<PaymentState> statusOf(String orderId) async {
///     final status = await api.fetchOrderStatus(orderId);
///     return switch (status) {
///       'paid' => const Paid(),
///       'declined' => const Declined(),
///       _ => const Unknown(),
///     };
///   }
/// }
/// ```
abstract class OrderStatusClient {
  /// The server's current view of [orderId]'s payment state.
  Future<PaymentState> statusOf(String orderId);
}
