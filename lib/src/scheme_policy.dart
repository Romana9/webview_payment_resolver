/// Decides which URL schemes the WebView may load itself.
///
/// 3-D Secure often navigates to bank-app schemes (`intent://`,
/// `mybank://`, `tel:`). A WebView asked to load one lands on a blank
/// page, so those must be handed to the OS instead.
class SchemePolicy {
  /// Creates a policy allowing exactly [allowedSchemes], lowercase.
  const SchemePolicy(this.allowedSchemes);

  /// The schemes the WebView may load in-place.
  final Set<String> allowedSchemes;

  /// Default for payment WebViews: http, https, file, about.
  static const SchemePolicy webOnly =
      SchemePolicy({'http', 'https', 'file', 'about'});

  /// Whether the WebView may load [uri]. If false, launch it externally.
  bool allows(Uri uri) => allowedSchemes.contains(uri.scheme.toLowerCase());
}
