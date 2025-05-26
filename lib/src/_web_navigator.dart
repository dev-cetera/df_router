import 'package:web/web.dart' as web;
import 'platform_navigator.dart';

class WebNavigator implements PlatformNavigator {
  @override
  String? getCurrentPath() {
    return normalizePathQuery(web.window.location.href);
  }

  @override
  void pushState(String path) {
    web.window.history.pushState(null, '', path);
  }

  @override
  void addPopStateListener(PopStateCallback callback) {
    web.window.onPopState.listen((event) {
      callback(getCurrentPath());
    });
  }

  @override
  void removePopStateListener(PopStateCallback callback) {
    // No-op: web.dart doesn't provide a way to remove specific listeners
  }
}
