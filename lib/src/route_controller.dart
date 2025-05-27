//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_pwa_utils/df_pwa_utils.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteController {
  //
  //
  //

  late final ValueNotifier<String> _pCurrentPathQuery;
  ValueListenable<String> get pCurrentPathQuery => _pCurrentPathQuery;

  var _widgetCache = <String, Widget>{};
  late final List<RouteBuilder> routes;
  final bool enablePrevsCapturing;
  final TTransitionBuilder transitionBuilder;

  Picture? _picture;
  BuildContext? _captureContext;
  String? _prevRoute;
  final _controller = TransitionController();

  //
  //
  //

  RouteController({
    String? initialRoute,
    required String fallbackRoute,
    required this.routes,
    this.enablePrevsCapturing = true,
    required this.transitionBuilder,
  }) {
    final pathQuery = initialRoute ?? platformNavigator.getCurrentPath() ?? fallbackRoute;
    _pCurrentPathQuery = ValueNotifier<String>(pathQuery);

    _widgetCache = Map.fromEntries(
      routes
          .where((route) => route.shouldPrebuild)
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

    platformNavigator.addStateCallback((path) {
      _pCurrentPathQuery.value = path;
    });
  }

  //
  //
  //

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

  //
  //
  //

  void _maybeCapture() {
    if (enablePrevsCapturing) {
      _picture = captureWidgetPicture(_captureContext!);
    }
  }

  //
  //
  //

  void repush(String route) {
    disposeExactRoute(route);
    push(route);
  }

  //
  //
  //

  void only(String route) {
    disposeAllRoutes();
    push(route);
  }

  //
  //
  //

  void push(String route, {bool skipCurrent = true}) {
    if (skipCurrent && _pCurrentPathQuery.value == route) {
      return;
    }
    _maybeCapture();
    platformNavigator.pushState(route);
    _prevRoute = _pCurrentPathQuery.value;
    _pCurrentPathQuery.value = route;
    _cleanUpRoute(_prevRoute);

    Future.microtask(() {
      _controller.reset1();
    });
  }

  //
  //
  //

  void disposeExactRoute(String pathQuery) {
    _widgetCache.removeWhere((pq, _) => pq == pathQuery);
  }

  //
  //
  //

  void disposeMatchingRoutes(String path) {
    _widgetCache.removeWhere((pq, _) => _matchesBaseRoute(path, pq));
  }

  //
  //
  //

  void disposeAllRoutes() {
    _widgetCache.clear();
  }

  //
  //
  //

  void pushBack() {
    if (_prevRoute != null) {
      push(_prevRoute!);
    }
  }

  //
  //
  //

  void onlyBack() {
    if (_prevRoute != null) {
      only(_prevRoute!);
    }
  }

  //
  //
  //

  void repushBack() {
    if (_prevRoute != null) {
      repush(_prevRoute!);
    }
  }

  //
  //
  //

  void _cleanUpRoute(String? route) {
    if (route == null) return;
    final a = routes.where((e) => _matchesBaseRoute(e.basePath, route)).firstOrNull;
    if (a == null) return;
    if (a.shouldPrebuild && !a.shouldPreserve) {
      print("STALE: $route");
      // Replace with empty widget instead of removing it to avoid rebuilds.
      _widgetCache[route] = const SizedBox.shrink();
    }
  }

  //
  //
  //

  bool _matchesBaseRoute(String path, String pathQuery) {
    return pathQuery == path || pathQuery.startsWith('$path?');
  }

  //
  //
  //

  Widget buildScreen(BuildContext context, String currentPathQuery) {
    final config = routes.where((r) => _matchesBaseRoute(r.basePath, currentPathQuery)).firstOrNull;
    if (config == null) {
      return const SizedBox.shrink();
    }
    _widgetCache[currentPathQuery] = Builder(
      builder: (context) => config.builder(context, _pictureWidget(context), currentPathQuery),
    );
    return transitionBuilder(
      context,
      _controller,
      config.shouldAnimate,
      _pictureWidget(context),
      Builder(
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
      ),
    );
  }

  //
  //
  //

  void dispose() {
    platformNavigator.removeStateCallback((path) => _pCurrentPathQuery.value = path);
    _pCurrentPathQuery.dispose();
    _widgetCache.clear();
    _controller.clear();
  }

  //
  //
  //

  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }
}
