import 'dart:ui' show Picture;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'get_platform_navigator.dart';
import 'platform_navigator.dart';

// RouteConfig
class RouteBuilder {
  final String path;
  final bool preserve;
  final Widget Function(BuildContext context, Uri uri) builder;

  const RouteBuilder({required this.path, this.preserve = true, required this.builder});
}

// PicturePainter
class PicturePainter extends CustomPainter {
  final Picture picture;

  PicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// RouteController
class RouteController {
  final ValueNotifier<String> _currentRoute;
  final Map<String, Widget> _preservedWidgets;
  final PlatformNavigator _platformNavigator;
  final List<RouteBuilder> _routes;

  RouteController({required String initialRoute, required List<RouteBuilder> routes})
    : _currentRoute = ValueNotifier<String>(getPlatformNavigator().getCurrentPath()),
      _preservedWidgets = {},
      _platformNavigator = getPlatformNavigator(),
      _routes = routes {
    final uri = Uri.parse(initialRoute);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath && r.preserve,
      orElse:
          () => RouteBuilder(
            path: basePath,
            preserve: false,
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );
    if (config.preserve) {
      _preservedWidgets[initialRoute] = DisposableWidget(
        builder: (context) => config.builder(context, uri),
        onDispose: () => print('Disposed: $initialRoute'),
      );
    }
    _platformNavigator.addPopStateListener((path) {
      _currentRoute.value = path;
    });
  }

  ValueNotifier<String> get currentRoute => _currentRoute;

  List<String> get preservedRoutes => _preservedWidgets.keys.toList();

  void goToNew(String route) {
    _platformNavigator.pushState(route);
    _currentRoute.value = route;
  }

  void goTo(String route) {
    disposeRoute(route);
    goToNew(route);
  }

  void goToOnly(String route) {
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

  Widget buildScreen(BuildContext context, String currentRoute, GlobalKey repaintKey) {
    final uri = Uri.parse(currentRoute);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath,
      orElse:
          () => RouteBuilder(
            path: basePath,
            preserve: false,
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );

    final isPreserved = config.preserve;

    if (isPreserved && !_preservedWidgets.containsKey(currentRoute)) {
      _preservedWidgets[currentRoute] = DisposableWidget(
        builder: (context) => config.builder(context, uri),
        onDispose: () => print('Disposed: $currentRoute'),
      );
    }

    final index = _preservedWidgets.keys.toList().indexOf(currentRoute);
    final children =
        _preservedWidgets.entries.map((entry) {
          final fullRoute = entry.key;
          final widget = entry.value;
          return KeyedSubtree(key: ValueKey(fullRoute), child: widget);
        }).toList();

    return RepaintBoundary(
      key: repaintKey,
      child: Stack(
        children: [
          Offstage(offstage: !isPreserved, child: IndexedStack(index: index, children: children)),
          Offstage(offstage: isPreserved, child: _buildNonPreservedScreen(context, currentRoute)),
        ],
      ),
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
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );
    return config.builder(context, uri);
  }

  void dispose() {
    _platformNavigator.removePopStateListener((path) => _currentRoute.value = path);
    _currentRoute.dispose();
    _preservedWidgets.clear();
  }

  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }
}

// InheritedWidget
class RouteControllerProvider extends InheritedWidget {
  final RouteController controller;

  const RouteControllerProvider({super.key, required this.controller, required super.child});

  @override
  bool updateShouldNotify(RouteControllerProvider oldWidget) => controller != oldWidget.controller;
}

// CustomRouter
class CustomRouter extends StatefulWidget {
  final String initialRoute;
  final List<RouteBuilder> routes;

  const CustomRouter({super.key, required this.initialRoute, required this.routes});

  @override
  State<CustomRouter> createState() => _CustomRouterState();
}

class _CustomRouterState extends State<CustomRouter> with SingleTickerProviderStateMixin {
  late final RouteController _controller;
  final GlobalKey _repaintKey = GlobalKey();
  Picture? _previousPicture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _controller = RouteController(initialRoute: widget.initialRoute, routes: widget.routes);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.currentRoute.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    captureCurrentPicture();
    if (_previousPicture != null) {
      _animationController.forward(from: 0.0).then((_) {
        setState(() {
          _previousPicture?.dispose();
          _previousPicture = null;
        });
      });
    }
  }

  void captureCurrentPicture() {
    final renderObject = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (renderObject != null && renderObject.debugLayer != null) {
      if (renderObject.debugLayer is PictureLayer) {
        final pictureLayer = renderObject.debugLayer as PictureLayer;
        _previousPicture = pictureLayer.picture;
      } else {
        print(
          'Error: debugLayer is not a PictureLayer, found: ${renderObject.debugLayer.runtimeType}',
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.currentRoute.removeListener(_onRouteChanged);
    _animationController.dispose();
    _controller.dispose();
    _previousPicture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_previousPicture);
    return RouteControllerProvider(
      controller: _controller,
      child: ValueListenableBuilder<String>(
        valueListenable: _controller.currentRoute,
        builder: (context, currentRoute, child) {
          final newWidget = _controller.buildScreen(context, currentRoute, _repaintKey);
          return Stack(
            children: [
              if (_previousPicture != null)
                Positioned.fill(child: CustomPaint(painter: PicturePainter(_previousPicture!))),
              newWidget,
            ],
          );
        },
      ),
    );
  }
}

// DisposableWidget
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
