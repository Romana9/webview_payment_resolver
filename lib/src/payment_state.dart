/// The three possible answers to "did the customer pay?".
///
/// There is no failed state for ambiguous endings: an abandoned WebView,
/// a missed redirect, or a 3-D Secure hand-off is [Unknown].
sealed class PaymentState {
  const PaymentState();
}

/// The payment is confirmed captured.
final class Paid extends PaymentState {
  /// Creates the paid state.
  const Paid();

  @override
  String toString() => 'Paid';
}

/// The payment was explicitly declined or cancelled.
final class Declined extends PaymentState {
  /// Creates the declined state with an optional [reason].
  const Declined({this.reason});

  /// Why the payment was declined, when known.
  final String? reason;

  @override
  String toString() => 'Declined(${reason ?? ''})';
}

/// The outcome can't be determined yet — keep confirming, don't fail.
final class Unknown extends PaymentState {
  /// Creates the unknown state.
  const Unknown();

  @override
  String toString() => 'Unknown';
}
