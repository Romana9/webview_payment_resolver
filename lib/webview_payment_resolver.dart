/// Three-state payment resolution (paid, declined, unknown) for WebView
/// gateway flows.
///
/// Pure Dart with no WebView dependency — see the README for glue with
/// `flutter_inappwebview` or `webview_flutter`.
library;

export 'src/backoff_poller.dart';
export 'src/order_status_client.dart';
export 'src/payment_resolver.dart';
export 'src/payment_state.dart';
export 'src/resolution_result.dart';
export 'src/return_url_matcher.dart';
export 'src/scheme_policy.dart';
