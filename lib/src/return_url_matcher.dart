/// Matches a navigated URL against the gateway's return or cancel URL on
/// scheme + host + path.
///
/// Substring checks like `url.contains('success')` break on intermediate
/// gateway pages, so they aren't exposed here.
class ReturnUrlMatcher {
  /// Creates a matcher for [target].
  ReturnUrlMatcher({required this.target});

  /// The URL that ends the flow when reached.
  final Uri target;

  /// Whether [url] is the target. Query and fragment are ignored, and one
  /// trailing slash difference is tolerated.
  bool matches(Uri url) =>
      url.scheme.toLowerCase() == target.scheme.toLowerCase() &&
      url.host.toLowerCase() == target.host.toLowerCase() &&
      _normalizePath(url.path) == _normalizePath(target.path);

  /// Reads query parameter [param] from [url], or null if absent or empty.
  String? orderIdOf(Uri url, String param) {
    final value = url.queryParameters[param];
    return (value == null || value.isEmpty) ? null : value;
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) return '/';
    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }
}
