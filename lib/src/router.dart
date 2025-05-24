import 'package:flutter/widgets.dart';
import 'get_platform_navigator.dart';
import 'platform_navigator.dart';

// RouteConfig (new builder signature)
class RouteConfig {
  final String path;
  final bool maintainState;
  final Widget Function(BuildContext context, Map<String, String>) builder;

  RouteConfig({required this.path, required this.maintainState, required this.builder});
}

// RouteController to manage routing logic
class RouteController {
  final ValueNotifier<String> _currentRoute;
  final Map<String, Widget> _preservedWidgets;
  final PlatformNavigator _platformNavigator;
  final List<RouteConfig> _routes;

  RouteController({required String initialRoute, required List<RouteConfig> routes})
    : _currentRoute = ValueNotifier<String>(getPlatformNavigator().getCurrentPath()),
      _preservedWidgets = {},
      _platformNavigator = getPlatformNavigator(),
      _routes = routes {
    // Add initial route if preserved
    final uri = Uri.parse(initialRoute);
    final basePath = uri.path;
    final config = _routes.firstWhere(
      (r) => r.path == basePath && r.maintainState,
      orElse:
          () => RouteConfig(
            path: basePath,
            maintainState: false,
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );
    if (config.maintainState) {
      _preservedWidgets[initialRoute] = DisposableWidget(
        builder: (context) => config.builder(context, uri.queryParameters),
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

  void goToNew(String route) {
    _platformNavigator.pushState(route);
    _currentRoute.value = route;
  }

  void goTo(String route) {
    disposeRoute(route);
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
    final queryParams = uri.queryParameters;
    final config = _routes.firstWhere(
      (r) => r.path == basePath,
      orElse:
          () => RouteConfig(
            path: basePath,
            maintainState: false,
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );

    final isPreserved = config.maintainState;

    // If preserved route, create or retrieve widget for full URI
    if (isPreserved && !_preservedWidgets.containsKey(currentRoute)) {
      _preservedWidgets[currentRoute] = DisposableWidget(
        builder: (context) => config.builder(context, queryParams),
        onDispose: () => print('Disposed: $currentRoute'),
      );
    }

    return Stack(
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
        Offstage(offstage: isPreserved, child: _buildNonPreservedScreen(context, currentRoute)),
      ],
    );
  }

  Widget _buildNonPreservedScreen(BuildContext context, String route) {
    final uri = Uri.parse(route);
    final basePath = uri.path;
    final queryParams = uri.queryParameters;
    final config = _routes.firstWhere(
      (r) => r.path == basePath && !r.maintainState,
      orElse:
          () => RouteConfig(
            path: basePath,
            maintainState: false,
            builder: (context, _) => const SizedBox.shrink(),
          ),
    );
    return config.builder(context, queryParams);
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

class CustomRouter extends StatefulWidget {
  final String initialRoute;
  final List<RouteConfig> routes;

  const CustomRouter({super.key, required this.initialRoute, required this.routes});

  @override
  State<CustomRouter> createState() => _CustomRouterState();
}

class _CustomRouterState extends State<CustomRouter> {
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

// class _RebuilderState extends State<Rebuilder> with AutomaticKeepAliveClientMixin {
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return widget.child;
//   }

//   @override
//   bool get wantKeepAlive => true;
// }

// import 'package:flutter/widgets.dart';
// import 'get_platform_navigator.dart';
// import 'platform_navigator.dart';

// // RouteConfig class (unchanged)
// class RouteConfig {
//   final String path;
//   final bool maintainState;
//   final Widget Function(BuildContext, void Function(String), Map<String, String>) builder;

//   RouteConfig({required this.path, required this.maintainState, required this.builder});
// }

// class CustomRouter extends StatefulWidget {
//   final String initialRoute;
//   final List<RouteConfig> routes;

//   const CustomRouter({super.key, required this.initialRoute, required this.routes});

//   @override
//   State<CustomRouter> createState() => _CustomRouterState();
// }

// class _CustomRouterState extends State<CustomRouter> {
//   late ValueNotifier<String> _currentRoute;
//   late Map<String, Widget> _preservedWidgets;
//   late PlatformNavigator _platformNavigator;

//   @override
//   void initState() {
//     super.initState();
//     _platformNavigator = getPlatformNavigator();
//     _currentRoute = ValueNotifier<String>(_platformNavigator.getCurrentPath());

//     // Initialize preserved widgets as an empty map
//     _preservedWidgets = {};

//     // Add the initial route if it’s preserved
//     final uri = Uri.parse(widget.initialRoute);
//     final basePath = uri.path;
//     final config = widget.routes.firstWhere(
//       (r) => r.path == basePath && r.maintainState,
//       orElse:
//           () => RouteConfig(
//             path: basePath,
//             maintainState: false,
//             builder: (context, navigateTo, _) => const SizedBox.shrink(),
//           ),
//     );
//     if (config.maintainState) {
//       _preservedWidgets[widget.initialRoute] = config.builder(
//         context,
//         navigateTo,
//         uri.queryParameters,
//       );
//     }

//     // Listen for platform navigation events
//     _platformNavigator.addPopStateListener((path) {
//       _currentRoute.value = path;
//     });
//   }

//   @override
//   void dispose() {
//     _platformNavigator.removePopStateListener((path) => _currentRoute.value = path);
//     _currentRoute.dispose();
//     super.dispose();
//   }

//   void navigateTo(String route) {
//     _platformNavigator.pushState(route);
//     _currentRoute.value = route;
//   }

//   Map<String, String> _parseQueryParams(String route) {
//     final uri = Uri.parse(route);
//     return uri.queryParameters;
//   }

//   Widget _buildNonPreservedScreen(String route) {
//     final uri = Uri.parse(route);
//     final basePath = uri.path;
//     final queryParams = uri.queryParameters;
//     final config = widget.routes.firstWhere(
//       (r) => r.path == basePath && !r.maintainState,
//       orElse:
//           () => RouteConfig(
//             path: basePath,
//             maintainState: false,
//             builder: (context, navigateTo, _) => const SizedBox.shrink(),
//           ),
//     );
//     return config.builder(context, navigateTo, queryParams);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<String>(
//       valueListenable: _currentRoute,
//       builder: (context, currentRoute, child) {
//         final uri = Uri.parse(currentRoute);
//         final basePath = uri.path;
//         final queryParams = uri.queryParameters;
//         final config = widget.routes.firstWhere(
//           (r) => r.path == basePath,
//           orElse:
//               () => RouteConfig(
//                 path: basePath,
//                 maintainState: false,
//                 builder: (context, navigateTo, _) => const SizedBox.shrink(),
//               ),
//         );

//         final isPreserved = config.maintainState;

//         // If preserved route, create or retrieve widget for full URI
//         if (isPreserved && !_preservedWidgets.containsKey(currentRoute)) {
//           _preservedWidgets[currentRoute] = config.builder(context, navigateTo, queryParams);
//         }

//         return Stack(
//           children: [
//             Offstage(
//               offstage: !isPreserved,
//               child: IndexedStack(
//                 index: _preservedWidgets.keys.toList().indexOf(currentRoute),
//                 children:
//                     _preservedWidgets.entries.map((entry) {
//                       final fullRoute = entry.key;
//                       final widget = entry.value;
//                       return KeyedSubtree(key: ValueKey(fullRoute), child: widget);
//                     }).toList(),
//               ),
//             ),
//             Offstage(offstage: isPreserved, child: _buildNonPreservedScreen(currentRoute)),
//           ],
//         );
//       },
//     );
//   }
// }

// // Rebuilder (unchanged, included for completeness)
// class Rebuilder extends StatefulWidget {
//   final Widget child;
//   const Rebuilder({super.key, required this.child});

//   @override
//   State<Rebuilder> createState() => _RebuilderState();
// }

// class _RebuilderState extends State<Rebuilder> with AutomaticKeepAliveClientMixin {
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return widget.child;
//   }

//   @override
//   bool get wantKeepAlive => true;
// }
