import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:webview_payment_resolver/webview_payment_resolver.dart';

/// Returns a scripted sequence of states, repeating the last one.
class _FakeClient implements OrderStatusClient {
  _FakeClient(this.script);

  final List<PaymentState> script;
  final List<String> queried = [];
  var _index = 0;

  @override
  Future<PaymentState> statusOf(String orderId) async {
    queried.add(orderId);
    final state = script[_index];
    if (_index < script.length - 1) _index++;
    return state;
  }
}

PaymentResolver _resolver(OrderStatusClient client, {List<int>? backoff}) =>
    PaymentResolver(
      client: client,
      returnUrl: Uri.parse('https://example.com/pay/return'),
      cancelUrl: Uri.parse('https://example.com/pay/cancel'),
      backoff: backoff ?? const [2, 4, 8, 16],
    );

void main() {
  group('onNavigation', () {
    test('ordinary in-flow navigation resolves to null', () async {
      final resolver = _resolver(_FakeClient([const Unknown()]));

      final result = await resolver.onNavigation(
        Uri.parse('https://example.com/gateway/card-entry'),
      );

      expect(result, isNull);
    });

    test('cancel URL produces Declined without asking the server', () async {
      final client = _FakeClient([const Paid()]);
      final resolver = _resolver(client);

      final result = await resolver.onNavigation(
        Uri.parse('https://example.com/pay/cancel?order_id=5'),
      );

      expect(result!.state, isA<Declined>());
      expect(result.action, SuggestedUiAction.showDeclined);
      expect(result.orderId, '5');
      expect(client.queried, isEmpty);
    });

    test('return URL is verified with the server, not trusted', () async {
      final client = _FakeClient([const Paid()]);
      final resolver = _resolver(client);

      final result = await resolver.onNavigation(
        Uri.parse('https://example.com/pay/return?order_id=9'),
      );

      expect(result!.state, isA<Paid>());
      expect(result.action, SuggestedUiAction.showSuccess);
      expect(client.queried, ['9']);
    });

    test('return URL with unknown server state stays confirming', () async {
      final resolver = _resolver(_FakeClient([const Unknown()]));

      final result = await resolver.onNavigation(
        Uri.parse('https://example.com/pay/return?order_id=9'),
      );

      expect(result!.state, isA<Unknown>());
      expect(result.action, SuggestedUiAction.showConfirming);
    });
  });

  group('onUserExit', () {
    test('paid on the server turns the exit into success', () async {
      final resolver = _resolver(_FakeClient([const Paid()]));

      final result = await resolver.onUserExit('31');

      expect(result.state, isA<Paid>());
      expect(result.action, SuggestedUiAction.showSuccess);
    });

    test('declined on the server shows declined', () async {
      final resolver = _resolver(_FakeClient([const Declined(reason: 'card')]));

      final result = await resolver.onUserExit('31');

      expect(result.state, isA<Declined>());
      expect(result.action, SuggestedUiAction.showDeclined);
    });

    test('unknown on the server asks the user before cancelling', () async {
      final resolver = _resolver(_FakeClient([const Unknown()]));

      final result = await resolver.onUserExit('31');

      expect(result.state, isA<Unknown>());
      expect(result.action, SuggestedUiAction.askToCancel);
    });
  });

  group('onResumed', () {
    test('unknown after a bank-app hand-off keeps confirming', () async {
      final resolver = _resolver(_FakeClient([const Unknown()]));

      final result = await resolver.onResumed('88');

      expect(result.state, isA<Unknown>());
      expect(result.action, SuggestedUiAction.showConfirming);
    });
  });

  group('confirmWithBackoff', () {
    test('polls until the server answers paid', () {
      fakeAsync((async) {
        final client = _FakeClient([
          const Unknown(),
          const Unknown(),
          const Paid(),
        ]);
        final resolver = _resolver(client, backoff: const [2, 4]);
        ResolutionResult? result;

        resolver.confirmWithBackoff('12').then((r) => result = r);
        async.elapse(const Duration(seconds: 6));

        expect(client.queried, hasLength(3));
        expect(result!.state, isA<Paid>());
        expect(result!.action, SuggestedUiAction.showSuccess);
      });
    });

    test('still confirming — never failed — when the schedule runs out', () {
      fakeAsync((async) {
        final resolver = _resolver(
          _FakeClient([const Unknown()]),
          backoff: const [1, 1],
        );
        ResolutionResult? result;

        resolver.confirmWithBackoff('12').then((r) => result = r);
        async.elapse(const Duration(seconds: 2));

        expect(result!.state, isA<Unknown>());
        expect(result!.action, SuggestedUiAction.showConfirming);
      });
    });
  });
}
