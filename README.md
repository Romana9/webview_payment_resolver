# webview_payment_resolver

Honest payment resolution for WebView-based gateway flows, as pure Dart.

## The five ways a WebView payment ends

1. **Success** — the gateway redirects to the return URL.
2. **Declined** — the gateway redirects to the failure/cancel URL.
3. **Abandoned mid-flow** — the user pops the screen after the charge but
   before the redirect. *(usually mishandled)*
4. **Handed off to a bank app** — 3-D Secure navigates to a non-http scheme
   and the WebView is left on a blank page. *(usually mishandled)*
5. **Offline after capture** — the money left the account, the callback never
   arrived. *(usually mishandled)*

Most implementations handle 1 and 2 and treat 3–5 as *failed*. That is the
dangerous mistake: in those three endings the charge may have gone through.
Showing "payment failed" invites the user to pay again — a double charge —
or to abandon an order that is actually paid.

## The three-state model

The truthful answers are `Paid`, `Declined`, and `Unknown` — a sealed
hierarchy with **no failed state for ambiguous endings**. Every resolver
method returns a `ResolutionResult` pairing a state with a suggested UI
action (`showSuccess`, `showDeclined`, `showConfirming`, `askToCancel`), and
the pairing is closed: "unknown → show failure" cannot be constructed through
this API. Ambiguity is always settled by asking *your server* through the
`OrderStatusClient` you implement.

```dart
abstract class OrderStatusClient {
  Future<PaymentState> statusOf(String orderId);
}

final resolver = PaymentResolver(
  client: myOrderStatusClient,
  returnUrl: Uri.parse('https://example.com/pay/return'),
  cancelUrl: Uri.parse('https://example.com/pay/cancel'),
  orderIdParam: 'order_id',
  backoff: const [2, 4, 8, 16], // seconds
);

// 1 & 2 — a navigation happened (null = ordinary in-flow navigation)
final r = await resolver.onNavigation(currentUrl);

// 3 — user is leaving the screen
final r = await resolver.onUserExit(orderId);

// 4 — should the WebView load this URL?
if (!SchemePolicy.webOnly.allows(uri)) { launchExternally(uri); }

// 4b — app came back to the foreground
final r = await resolver.onResumed(orderId);

// 5 — the redirect never arrived
final r = await resolver.confirmWithBackoff(orderId);
```

Return/cancel URLs are matched on exact scheme + host + path — never by
substring, so an intermediate gateway page containing the word "success"
can't end the flow early. The core has **no WebView dependency**: wire it to
any WebView package with the glue below.

## Integration: flutter_inappwebview

```dart
InAppWebView(
  initialUrlRequest: URLRequest(url: WebUri(gatewayUrl)),
  shouldOverrideUrlLoading: (controller, action) async {
    final uri = Uri.parse(action.request.url.toString());
    if (!SchemePolicy.webOnly.allows(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication); // url_launcher
      return NavigationActionPolicy.CANCEL;
    }
    final result = await resolver.onNavigation(uri);
    if (result != null) {
      handleResult(result); // switch on result.action
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  },
)
```

## Integration: webview_flutter

```dart
final controller = WebViewController()
  ..setNavigationDelegate(NavigationDelegate(
    onNavigationRequest: (request) async {
      final uri = Uri.parse(request.url);
      if (!SchemePolicy.webOnly.allows(uri)) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      }
      final result = await resolver.onNavigation(uri);
      if (result != null) {
        handleResult(result);
        return NavigationDecision.prevent;
      }
      return NavigationDecision.navigate;
    },
  ))
  ..loadRequest(Uri.parse(gatewayUrl));
```

For endings 3–5, call `onUserExit` from your `PopScope`/back handler,
`onResumed` from an `AppLifecycleListener` when the app returns to the
foreground, and `confirmWithBackoff` when a "confirming…" screen has been
visible too long.

```dart
void handleResult(ResolutionResult result) {
  switch (result.action) {
    case SuggestedUiAction.showSuccess:    // navigate to success screen
    case SuggestedUiAction.showDeclined:   // show decline + retry option
    case SuggestedUiAction.showConfirming: // keep spinner, keep polling
    case SuggestedUiAction.askToCancel:    // "Leave before we confirm?"
  }
}
```

## License

MIT © Khaled Romana
