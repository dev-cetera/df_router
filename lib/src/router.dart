import 'dart:ui';

import 'package:df_router/src/capture_widget_picture.dart';
import 'package:flutter/widgets.dart';
import 'get_platform_navigator.dart';
import 'platform_navigator.dart';

// RouteConfig (new builder signature)
class RouteBuilder {
  final String path;
  final bool preserve;
  final Widget Function(BuildContext context, Widget? previous, Uri uri) builder;

  const RouteBuilder({required this.path, this.preserve = true, required this.builder});
}

// RouteController to manage routing logic
class RouteController {
  final ValueNotifier<String> _currentRoute;
  final Map<String, Widget> _preservedWidgets;
  final PlatformNavigator _platformNavigator;
  final List<RouteBuilder> _routes;
  final bool enableCapturing;
  final bool lowerPicture;

  GlobalKey? _repaintKey;
  Picture? _picture;

  Widget? _pictureWidget(BuildContext context) {
    if (_picture == null) {
      return null;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return PictureWidget(picture: _picture, size: size);
      },
    );
  }

  void _maybeCapture() {
    if (enableCapturing) {
      _repaintKey ??= GlobalKey();
      _picture = captureWidgetPicture(_repaintKey!);
    }
  }

  RouteController({
    required String initialRoute,
    required List<RouteBuilder> routes,
    this.enableCapturing = true,
    this.lowerPicture = false,
  }) : _currentRoute = ValueNotifier<String>(getPlatformNavigator().getCurrentPath()),
       _preservedWidgets = {},
       _platformNavigator = getPlatformNavigator(),
       _routes = routes {
    // Add initial route if preserved
    final uri = Uri.parse(initialRoute);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath && r.preserve,
      orElse:
          () => RouteBuilder(
            path: basePath,
            preserve: false,
            builder: (_, __, ___) => const SizedBox.shrink(),
          ),
    );
    if (config.preserve) {
      _preservedWidgets[initialRoute] = DisposableWidget(
        builder: (context) => config.builder(context, _pictureWidget(context), uri),
        onDispose: () => print('Disposed: $initialRoute'),
      );
    }

    // Listen for platform navigation events
    _platformNavigator.addPopStateListener((path) {
      _currentRoute.value = path;
    });
  }

  ValueNotifier<String> get currentRoute => _currentRoute;

  List<String> get preservedRoutes => _preservedWidgets.keys.toList();

  /// Goes to the new route, without disposing any existing routes with
  /// different query parameters.
  void goToNew(String route) {
    _maybeCapture();
    _platformNavigator.pushState(route);
    _currentRoute.value = route;
  }

  /// Goes to the new route, disposing any existing routes with the same base
  /// path.
  void goTo(String route) {
    disposeRoute(route);
    goToNew(route);
  }

  /// Goes to the new route, disposing all existing routes even ones marked
  /// as preserved.
  void goToReset(String route) {
    disposeAllRoutes();
    goToNew(route);
  }

  void disposeFullRoute(String fullRoute) {
    if (_preservedWidgets.containsKey(fullRoute)) {
      _preservedWidgets.remove(fullRoute);
    }
  }

  void disposeRoute(String route) {
    final basePath = Uri.parse(route).path;
    _preservedWidgets.removeWhere((key, _) => key.startsWith(basePath));
  }

  void disposeAllRoutes() {
    _preservedWidgets.clear();
  }

  Map<String, String> _parseQueryParams(String route) {
    final uri = Uri.parse(route);
    return uri.queryParameters;
  }

  Widget buildScreen(BuildContext context, String currentRoute) {
    final uri = Uri.parse(currentRoute);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath,
      orElse:
          () => RouteBuilder(
            path: basePath,
            preserve: false,
            builder: (_, __, ___) => const SizedBox.shrink(),
          ),
    );

    final isPreserved = config.preserve;

    // If preserved route, create or retrieve widget for full URI
    if (isPreserved && !_preservedWidgets.containsKey(currentRoute)) {
      _preservedWidgets[currentRoute] = DisposableWidget(
        builder: (context) => config.builder(context, _pictureWidget(context), uri),
        onDispose: () => print('Disposed: $currentRoute'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          children: [
            if (enableCapturing && lowerPicture)
              PictureWidget(picture: _picture, size: Size(width, height)),
            RepaintBoundary(
              key: _repaintKey,
              child: Stack(
                children: [
                  Offstage(
                    offstage: !isPreserved,
                    child: IndexedStack(
                      index: _preservedWidgets.keys.toList().indexOf(currentRoute),
                      children:
                          _preservedWidgets.entries.map((entry) {
                            final fullRoute = entry.key;
                            final widget = entry.value;
                            return KeyedSubtree(key: ValueKey(fullRoute), child: widget);
                          }).toList(),
                    ),
                  ),
                  Offstage(
                    offstage: isPreserved,
                    child: _buildNonPreservedScreen(context, currentRoute),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNonPreservedScreen(BuildContext context, String route) {
    final uri = Uri.parse(route);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath && !r.preserve,
      orElse:
          () => RouteBuilder(
            path: basePath,
            preserve: false,
            builder: (_, __, ___) => const SizedBox.shrink(),
          ),
    );
    return config.builder(context, _pictureWidget(context), uri);
  }

  void dispose() {
    _platformNavigator.removePopStateListener((path) => _currentRoute.value = path);
    _currentRoute.dispose();
    _preservedWidgets.clear();
  }

  // Static method to access RouteController
  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }
}

// InheritedWidget to provide RouteController
class RouteControllerProvider extends InheritedWidget {
  final RouteController controller;

  const RouteControllerProvider({super.key, required this.controller, required super.child});

  @override
  bool updateShouldNotify(RouteControllerProvider oldWidget) => controller != oldWidget.controller;
}

class RouteManager extends StatefulWidget {
  final String initialRoute;
  final List<RouteBuilder> routes;

  const RouteManager({super.key, required this.initialRoute, required this.routes});

  @override
  State<RouteManager> createState() => _RouteManagerState();
}

class _RouteManagerState extends State<RouteManager> {
  late final RouteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RouteController(initialRoute: widget.initialRoute, routes: widget.routes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RouteControllerProvider(
      controller: _controller,
      child: ValueListenableBuilder<String>(
        valueListenable: _controller.currentRoute,
        builder: (context, currentRoute, child) {
          return _controller.buildScreen(context, currentRoute);
        },
      ),
    );
  }
}

class DisposableWidget extends StatefulWidget {
  final WidgetBuilder builder;
  final void Function()? onDispose;

  const DisposableWidget({super.key, required this.builder, this.onDispose});

  @override
  State<DisposableWidget> createState() => _DisposableWidgetState();
}

class _DisposableWidgetState extends State<DisposableWidget> {
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
