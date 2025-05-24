import 'package:web/web.dart' as web;
import 'platform_navigator.dart';

class WebNavigator implements PlatformNavigator {
  @override
  String getCurrentPath() {
    return web.window.location.href;
  }

  @override
  void pushState(String path) {
    web.window.history.pushState(null, '', path);
  }

  @override
  void addPopStateListener(PopStateCallback callback) {
    web.window.onPopState.listen((event) {
      final path = web.window.location.pathname;
      callback(path);
    });
  }

  @override
  void removePopStateListener(PopStateCallback callback) {
    // No-op: web.dart doesn't provide a way to remove specific listeners
  }
}
