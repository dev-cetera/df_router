import 'dart:ui';

import 'package:df_router/src/capture_widget_picture.dart';
import 'package:df_router/src/slides/cupertino_screen_transition.dart';
import 'package:df_widgets/_common.dart';
import 'package:flutter/widgets.dart';
import 'get_platform_navigator.dart';
import 'platform_navigator.dart';

// RouteConfig (new builder signature)
class RouteBuilder {
  final String path;
  final bool preserve;
  final bool transition;
  final Widget Function(BuildContext context, Widget? previous, Uri uri) builder;

  const RouteBuilder({
    required this.path,
    this.preserve = true,
    this.transition = true,
    required this.builder,
  });
}

// RouteController to manage routing logic
class RouteController {
  late final ValueNotifier<String> _currentRoute;
  late final Map<String, Widget> _preservedWidgets;
  late final PlatformNavigator _platformNavigator;
  late final List<RouteBuilder> _routes;
  final bool enablePrevsCapturing;
  final bool drawPrevAtStackBottom;
  final Widget Function(Widget current, {Widget? prev, Duration duration}) transitionBuilder;

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
    if (enablePrevsCapturing) {
      _repaintKey ??= GlobalKey();
      _picture = captureWidgetPicture(_repaintKey!);
    }
  }

  RouteController({
    String? initialRoute,
    required List<RouteBuilder> routes,
    this.enablePrevsCapturing = true,
    this.drawPrevAtStackBottom = false,
    required this.transitionBuilder,
  }) {
    final platformNavigator = getPlatformNavigator();
    _currentRoute = ValueNotifier<String>(initialRoute ?? platformNavigator.getCurrentPath());

    _platformNavigator = platformNavigator;

    _preservedWidgets = {};
    _routes = routes;

    // Add initial route if preserved
    final uri = Uri.parse(_currentRoute.value);

    // platformNavigator.pushState(_currentRoute.value);
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
      _preservedWidgets[_currentRoute.value] = DisposableWidget(
        builder: (context) => config.builder(context, _pictureWidget(context), uri),
        onDispose: () => print('Disposed: ${_currentRoute.value}'),
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

    final preserve = config.preserve;
    final transition = config.transition;

    // If preserved route, create or retrieve widget for full URI
    if (preserve && !_preservedWidgets.containsKey(currentRoute)) {
      _preservedWidgets[currentRoute] = DisposableWidget(
        builder: (context) => config.builder(context, _pictureWidget(context), uri),
        onDispose: () => print('Disposed: $currentRoute'),
      );
    }

    final a = RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        children: [
          Offstage(
            offstage: !preserve,
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
          Offstage(offstage: preserve, child: _buildNonPreservedScreen(context, currentRoute)),
        ],
      ),
    );

    return transition
        ? KeyedSubtree(key: UniqueKey(), child: transitionBuilder(a, prev: _pictureWidget(context)))
        : a;
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
  final String? initialRoute;
  final List<RouteBuilder> routes;

  const RouteManager({super.key, this.initialRoute, required this.routes});

  @override
  State<RouteManager> createState() => _RouteManagerState();
}

class _RouteManagerState extends State<RouteManager> {
  late final RouteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RouteController(
      initialRoute: widget.initialRoute,
      routes: widget.routes,
      transitionBuilder: CupertinoScreenTransition.transition,
    );
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
