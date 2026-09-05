# Changelog

## 0.1.0

- Initial release.
- Sealed `PaymentState` (`Paid` / `Declined` / `Unknown`) — no "failed"
  state for ambiguous endings, by design.
- `PaymentResolver` orchestrating all five flow endings: return redirect,
  cancel redirect, user exit, bank-app hand-off resume, and missed
  callback.
- `ReturnUrlMatcher` with exact scheme + host + path matching; substring
  matching is not expressible through the public API.
- `SchemePolicy` (`webOnly` default) for deciding which URLs the WebView
  may load versus hand off to the OS.
- `BackoffPoller`, a generic `Future<T?>` poller driven by a configurable
  delay schedule, fully testable with `fake_async`.
- Pure Dart core — no WebView dependency; integrate with any WebView
  package.
