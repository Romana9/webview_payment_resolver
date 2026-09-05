import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:webview_payment_resolver/webview_payment_resolver.dart';

void main() {
  group('BackoffPoller', () {
    test('returns immediately when the first attempt succeeds', () {
      fakeAsync((async) {
        const poller = BackoffPoller(delays: [Duration(seconds: 2)]);
        int? result;

        poller.poll(() async => 42).then((r) => result = r);
        async.flushMicrotasks();

        expect(result, 42);
        expect(async.elapsed, Duration.zero);
      });
    });

    test('resolves on the third attempt, waiting the configured delays', () {
      fakeAsync((async) {
        const poller = BackoffPoller(
          delays: [Duration(seconds: 2), Duration(seconds: 4)],
        );
        var attempts = 0;
        int? result;

        poller.poll(() async {
          attempts++;
          return attempts == 3 ? 7 : null;
        }).then((r) => result = r);

        async.flushMicrotasks();
        expect(attempts, 1);
        expect(result, isNull);

        async.elapse(const Duration(seconds: 2));
        expect(attempts, 2);
        expect(result, isNull);

        async.elapse(const Duration(seconds: 4));
        expect(attempts, 3);
        expect(result, 7);
      });
    });

    test('gives up with null after the delay list is exhausted', () {
      fakeAsync((async) {
        const poller = BackoffPoller(
          delays: [
            Duration(seconds: 2),
            Duration(seconds: 4),
            Duration(seconds: 8),
          ],
        );
        var attempts = 0;
        var completed = false;
        int? result = -1;

        poller.poll<int>(() async {
          attempts++;
          return null;
        }).then((r) {
          result = r;
          completed = true;
        });

        async.elapse(const Duration(seconds: 14));

        expect(attempts, 4, reason: 'immediate attempt + one per delay');
        expect(completed, isTrue);
        expect(result, isNull);
      });
    });

    test('never waits in real time under fakeAsync', () {
      fakeAsync((async) {
        const poller = BackoffPoller(delays: [Duration(minutes: 30)]);
        var completed = false;

        poller.poll<int>(() async => null).then((_) => completed = true);
        async.elapse(const Duration(minutes: 30));

        expect(completed, isTrue);
      });
    });
  });
}
