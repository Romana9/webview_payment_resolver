/// Retries an async probe on a fixed schedule until it returns a value.
class BackoffPoller {
  /// Creates a poller that waits each of [delays] between attempts.
  const BackoffPoller({required this.delays});

  /// Pauses between attempts. The first attempt runs immediately, so `n`
  /// delays means `n + 1` attempts.
  final List<Duration> delays;

  /// Calls [attempt] until it returns non-null or the schedule runs out.
  ///
  /// Uses `Future.delayed`, so tests can drive it with `fakeAsync`.
  Future<T?> poll<T>(Future<T?> Function() attempt) async {
    final first = await attempt();
    if (first != null) return first;
    for (final delay in delays) {
      await Future<void>.delayed(delay);
      final result = await attempt();
      if (result != null) return result;
    }
    return null;
  }
}
