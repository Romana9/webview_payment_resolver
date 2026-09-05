import 'payment_state.dart';

/// What the UI should do after a resolution step.
enum SuggestedUiAction {
  /// Payment confirmed — show the success screen.
  showSuccess,

  /// Gateway or server said no — show the declined screen.
  showDeclined,

  /// Outcome not known yet — keep the confirming state and keep checking.
  showConfirming,

  /// Outcome not known and the user wants to leave — ask them to confirm.
  askToCancel,
}

/// A [PaymentState] paired with the UI action it justifies.
///
/// The pairing is closed: [Unknown] can only carry
/// [SuggestedUiAction.showConfirming] or [SuggestedUiAction.askToCancel],
/// so "unknown treated as failure" can't be constructed.
class ResolutionResult {
  const ResolutionResult._(this.state, this.action, this.orderId);

  /// Confirmed paid.
  const ResolutionResult.paid({String? orderId})
      : this._(const Paid(), SuggestedUiAction.showSuccess, orderId);

  /// Declined or cancelled.
  ResolutionResult.declined({String? orderId, String? reason})
      : this._(
          Declined(reason: reason),
          SuggestedUiAction.showDeclined,
          orderId,
        );

  /// Not known yet; keep confirming.
  const ResolutionResult.confirming({String? orderId})
      : this._(const Unknown(), SuggestedUiAction.showConfirming, orderId);

  /// Not known and the user is leaving; ask first.
  const ResolutionResult.askToCancel({String? orderId})
      : this._(const Unknown(), SuggestedUiAction.askToCancel, orderId);

  /// The resolved payment state.
  final PaymentState state;

  /// The UI action this state justifies.
  final SuggestedUiAction action;

  /// The order this result refers to, when known.
  final String? orderId;

  @override
  String toString() =>
      'ResolutionResult(state: $state, action: $action, orderId: $orderId)';
}
