typedef PopStateCallback = void Function(String path);

// Abstract interface for platform-specific navigation
class PlatformNavigator {
  String getCurrentPath() => '';
  void pushState(String path) {}
  void addPopStateListener(PopStateCallback callback) {}
  void removePopStateListener(PopStateCallback callback) {}
}
