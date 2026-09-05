import 'package:test/test.dart';
import 'package:webview_payment_resolver/webview_payment_resolver.dart';

void main() {
  final matcher = ReturnUrlMatcher(
    target: Uri.parse('https://example.com/pay/return'),
  );

  group('ReturnUrlMatcher.matches', () {
    test('matches the exact path, ignoring the query string', () {
      expect(
        matcher.matches(
          Uri.parse('https://example.com/pay/return?order_id=77&txn=abc'),
        ),
        isTrue,
      );
    });

    test('tolerates a trailing slash difference', () {
      expect(
        matcher.matches(Uri.parse('https://example.com/pay/return/')),
        isTrue,
      );
    });

    test('does not match a URL that merely contains "success" or "return"', () {
      expect(
        matcher.matches(
          Uri.parse('https://example.com/gateway/3ds?next=return-success'),
        ),
        isFalse,
      );
      expect(
        matcher.matches(
          Uri.parse('https://example.com/pay/return/success'),
        ),
        isFalse,
      );
    });

    test('does not match a longer path that starts with the target path', () {
      expect(
        matcher.matches(Uri.parse('https://example.com/pay/return/extra')),
        isFalse,
      );
    });

    test('does not match a different host or scheme', () {
      expect(
        matcher.matches(Uri.parse('https://evil.example.org/pay/return')),
        isFalse,
      );
      expect(
        matcher.matches(Uri.parse('myapp://example.com/pay/return')),
        isFalse,
      );
    });
  });

  group('ReturnUrlMatcher.orderIdOf', () {
    test('extracts the order id from the query string', () {
      expect(
        matcher.orderIdOf(
          Uri.parse('https://example.com/pay/return?order_id=915'),
          'order_id',
        ),
        '915',
      );
    });

    test('returns null when the parameter is absent or empty', () {
      expect(
        matcher.orderIdOf(
            Uri.parse('https://example.com/pay/return'), 'order_id'),
        isNull,
      );
      expect(
        matcher.orderIdOf(
          Uri.parse('https://example.com/pay/return?order_id='),
          'order_id',
        ),
        isNull,
      );
    });
  });
}
