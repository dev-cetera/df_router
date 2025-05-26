import 'dart:ui';

import 'package:df_router/main.dart';
import 'package:df_router/src/capture_widget_picture.dart';
import 'package:df_widgets/_common.dart';

import 'package:flutter/material.dart';
import 'get_platform_navigator.dart';
import 'platform_navigator.dart';

class RouteBuilder {
  final String basePath;
  final bool preserveWidget;
  final bool enableTransition;
  final bool prebuildWidget;
  final Widget Function(BuildContext context, Widget? previous, String pathQuery) builder;

  const RouteBuilder({
    required this.basePath,
    this.preserveWidget = true,
    this.enableTransition = true,
    this.prebuildWidget = false,
    required this.builder,
  });
}

// RouteController to manage routing logic
class RouteController {
  late final ValueNotifier<String> _pCurrentPathQuery; // todo change to pod
  var _widgetCache = <String, Widget>{};
  late final PlatformNavigator _platformNavigator;
  late final List<RouteBuilder> routes;
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

  BuildContext? _captureContext;

  void _maybeCapture() {
    if (enablePrevsCapturing) {
      _repaintKey ??= GlobalKey();
      _picture = captureWidgetPicture(_captureContext!);
    }
  }

  RouteController({
    String? initialRoute,
    required this.routes,
    this.enablePrevsCapturing = true,
    this.drawPrevAtStackBottom = false,
    required this.transitionBuilder,
  }) {
    final platformNavigator = getPlatformNavigator();
    _pCurrentPathQuery = ValueNotifier<String>(
      initialRoute ?? platformNavigator.getCurrentPath() ?? '/home',
    );

    _platformNavigator = platformNavigator;

    _widgetCache = Map.fromEntries(
      routes
          .where((route) => route.prebuildWidget)
          .map(
            (e) => MapEntry(
              e.basePath,
              Builder(
                builder: (context) {
                  return e.builder(context, _pictureWidget(context), e.basePath);
                },
              ),
            ),
          ),
    );

    _platformNavigator.addPopStateListener((path) {
      _pCurrentPathQuery.value = path!;
    });
  }

  ValueNotifier<String> get pCurrentPathQuery => _pCurrentPathQuery;

  void repush(String route) {
    disposeExactRoute(route);
    push(route);
  }

  void only(String route) {
    disposeAllRoutes();
    push(route);
  }

  void push(String route, {bool skipCurrent = true}) {
    if (skipCurrent && _pCurrentPathQuery.value == route) {
      return;
    }

    _maybeCapture();
    _platformNavigator.pushState(route);
    _prevRoute = _pCurrentPathQuery.value;
    _pCurrentPathQuery.value = route;
    _cleanUpRoute(_prevRoute);
    _controller.reanimate();
  }

  void disposeExactRoute(String pathQuery) {
    _widgetCache.removeWhere((pq, _) => pq == pathQuery);
  }

  void disposeMatchingRoutes(String path) {
    _widgetCache.removeWhere((pq, _) => _matchesBaseRoute(path, pq));
  }

  void disposeAllRoutes() {
    _widgetCache.clear();
  }

  void pushBack() {
    if (_prevRoute != null) {
      push(_prevRoute!);
    }
  }

  void onlyBack() {
    if (_prevRoute != null) {
      only(_prevRoute!);
    }
  }

  void repushBack() {
    if (_prevRoute != null) {
      repush(_prevRoute!);
    }
  }

  String? _prevRoute;

  void _cleanUpRoute(String? route) {
    if (route == null) return;
    final a = routes.firstWhereOrNull((e) => _matchesBaseRoute(e.basePath, route));
    if (a == null) return;
    if (a.prebuildWidget && !a.preserveWidget) {
      print("STALE: $route");
      _widgetCache[route] =
          const SizedBox.shrink(); // repalce with empty widget instead of removing it to avoid strange state changes
    }
  }

  bool _matchesBaseRoute(String path, String pathQuery) {
    return pathQuery == path || pathQuery.startsWith('$path?');
  }

  Widget buildScreen(BuildContext context, String currentPathQuery) {
    final config = routes.firstWhereOrNull((r) => _matchesBaseRoute(r.basePath, currentPathQuery));

    if (config == null) {
      return const SizedBox.shrink();
    }

    _widgetCache[currentPathQuery] = Builder(
      builder: (context) => config.builder(context, _pictureWidget(context), currentPathQuery),
    );

    final aaa = Builder(
      builder: (context) {
        _captureContext = context;
        return RepaintBoundary(
          child: Builder(
            builder: (context) {
              return IndexedStack(
                index: _widgetCache.keys.toList().indexOf(currentPathQuery),
                children:
                    _widgetCache.entries.map((entry) {
                      final fullRoute = entry.key;
                      final widget = entry.value;
                      return KeyedSubtree(key: ValueKey(fullRoute), child: widget);
                    }).toList(),
              );
            },
          ),
        );
      },
    );
    final bbb = SlideWidget(
      prev: _pictureWidget(context) ?? const SizedBox.shrink(),
      controller: _controller,
      duration: Durations.medium3,
      child: aaa,
    );
    return bbb;
  }

  final _controller = SlideWidgetController();

  void dispose() {
    _platformNavigator.removePopStateListener((path) => _pCurrentPathQuery.value = path!);
    _pCurrentPathQuery.dispose();
    _widgetCache.clear();
    _controller.clear();
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
      transitionBuilder: (Widget a, {Duration duration = Durations.medium3, Widget? prev}) => a,
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
        valueListenable: _controller.pCurrentPathQuery,
        builder: (context, currentRoute, child) {
          return _controller.buildScreen(context, currentRoute);
        },
      ),
    );
  }
}
