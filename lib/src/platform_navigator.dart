typedef PopStateCallback = void Function(String? path);

// Abstract interface for platform-specific navigation
class PlatformNavigator {
  String? getCurrentPath() => null;
  void pushState(String path) {}
  void addPopStateListener(PopStateCallback callback) {}
  void removePopStateListener(PopStateCallback callback) {}
}

String? normalizePathQuery(String input) {
  final url = Uri.parse(input.trim());
  var p = url.path;
  if (p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  final q = url.query.isNotEmpty ? '?${url.query}' : '';
  final pq = '$p$q';
  return pq.isEmpty ? null : pq;
}
