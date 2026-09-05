import 'package:test/test.dart';
import 'package:webview_payment_resolver/webview_payment_resolver.dart';

void main() {
  group('SchemePolicy.webOnly', () {
    test('allows http, https, file, and about', () {
      expect(SchemePolicy.webOnly.allows(Uri.parse('https://example.com')),
          isTrue);
      expect(
          SchemePolicy.webOnly.allows(Uri.parse('http://example.com')), isTrue);
      expect(SchemePolicy.webOnly.allows(Uri.parse('file:///tmp/receipt.html')),
          isTrue);
      expect(SchemePolicy.webOnly.allows(Uri.parse('about:blank')), isTrue);
    });

    test('hands off bank-app and OS schemes', () {
      expect(
        SchemePolicy.webOnly.allows(
          Uri.parse('intent://pay#Intent;scheme=bankapp;end'),
        ),
        isFalse,
      );
      expect(SchemePolicy.webOnly.allows(Uri.parse('myBank://approve?tx=1')),
          isFalse);
      expect(
          SchemePolicy.webOnly.allows(Uri.parse('tel:+201000000000')), isFalse);
      expect(SchemePolicy.webOnly.allows(Uri.parse('mailto:pay@example.com')),
          isFalse);
    });

    test('compares schemes case-insensitively', () {
      expect(SchemePolicy.webOnly.allows(Uri.parse('HTTPS://example.com')),
          isTrue);
    });
  });

  group('custom policies', () {
    test('the allowed set is configurable', () {
      const policy = SchemePolicy({'https', 'myapp'});

      expect(policy.allows(Uri.parse('myapp://home')), isTrue);
      expect(policy.allows(Uri.parse('http://example.com')), isFalse);
    });
  });
}
