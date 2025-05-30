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

  // TODO: Convert to Pod once that flashing error is fixed.
  final _pRouteState = ValueNotifier(RouteState.parse('/'));
  ValueListenable<RouteState> get pRouteState => _pRouteState;
  RouteState get routeState => _pRouteState.value;

  final _widgetCache = <RouteState, Widget>{};
  late final List<RouteBuilder> builders;
  final bool shouldCapture;
  final TRouteTransitionBuilder transitionBuilder;

  Picture? _prevSnapshotPicture;
  BuildContext? _captureContext;
  late RouteState _prevRouteState = _pRouteState.value;
  final _controller = TransitionController();
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;
  RouteState? _requestedRouteState;

  //
  //
  //

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required this.builders,
    this.shouldCapture = true,
    required this.transitionBuilder,
  }) {
    _requestedRouteState = getNavigatorRouteState();
    final routeState = initialRouteState?.call() ?? _requestedRouteState ?? fallbackRouteState();
    platformNavigator.addStateCallback(_onStateChange);
    resetCache();
    push(routeState);
  }

  //
  //
  //

  void resetCache() {
    clearCache();
    final routeStates = builders
        .where((routeState) => routeState.shouldPrebuild)
        .map((e) => routeState);
    cacheStates(routeStates);
  }

  //
  //
  //

  void cacheStates(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      if (_widgetCache.containsKey(routeState)) {
        // TODO: Handle this case.
        continue;
      }
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) {
        // TODO: Handle this case.
        continue;
      }
      _widgetCache[routeState] = Builder(
        builder: (context) => builder.builder(context, routeState),
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      _pRouteState.notifyListeners();
    }
  }

  //
  //
  //

  RouteState getNavigatorOrFallbackRouteState() => _requestedRouteState ?? fallbackRouteState();

  //
  //
  //

  RouteState? getNavigatorRouteState() {
    final url = platformNavigator.getCurrentUrl();
    if (url == null) {
      return null;
    }
    return _getBuilderByPath(url)?.routeState.copyWith(queryParameters: url.queryParameters);
  }

  //
  //
  //

  void _onStateChange(Uri uri) {
    final builder = _getBuilderByPath(uri);
    if (builder == null) {
      debugPrint('[RouteController._onStateChange] Condition not met!');
      return;
    }
    final condition = builder.condition;
    if (condition != null && !condition()) {
      debugPrint('[RouteController._onStateChange] Condition not met!');
      return;
    }
    _pRouteState.value = RouteState(uri);
  }

  //
  //
  //

  Widget _pictureWidget() {
    if (_prevSnapshotPicture == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return PictureWidget(picture: _prevSnapshotPicture, size: size);
      },
    );
  }

  //
  //
  //

  void _maybeCapture() {
    if (shouldCapture && _captureContext != null && _captureContext!.mounted) {
      _prevSnapshotPicture = captureWidgetPicture(_captureContext!);
    }
  }

  //
  //
  //

  void pushBack({RouteState? fallback}) {
    if (_prevRouteState.path == '/') {
      push(fallback ?? fallbackRouteState());
    } else {
      push(_prevRouteState);
    }
  }

  //
  //
  //

  void push<TExtra extends Object?>(
    RouteState<TExtra> routeState, {
    RouteState? errorFallback,
    RouteState? fallback,
  }) {
    final uri = routeState.uri;
    final extra = routeState.extra;
    final skipCurrent = routeState.skipCurrent;
    final shouldAnimate = routeState.shouldAnimate;
    final condition = routeState.condition;
    if (skipCurrent && _pRouteState.value.uri == uri) {
      return;
    }
    if (_checkExtraTypeMismatch<TExtra>(uri) == false) {
      debugPrint('[RouteController.push] Error!');
      final errorFallback1 = errorFallback ?? errorRouteState?.call();
      if (errorFallback1 != null) {
        push(errorFallback1);
      }
      return;
    }
    if (!pathExists(uri)) {
      debugPrint('[RouteController.push] Error!');
      final errorFallback1 = errorFallback ?? errorRouteState?.call();
      if (errorFallback1 != null) {
        push(errorFallback1);
      }
      return;
    }
    final a = condition == null || condition();
    if (!a) {
      debugPrint('[RouteController.push] Condition not met!');
      push(fallback ?? fallbackRouteState());
      return;
    }
    final condition2 = _getBuilderByPath(uri)?.condition;
    final b = condition2 == null || condition2.call();
    if (!b) {
      debugPrint('[RouteController.push] Condition not met!');
      push(fallback ?? fallbackRouteState());
      return;
    }
    _maybeCapture();
    platformNavigator.pushState(uri);
    _prevRouteState = _pRouteState.value;
    _pRouteState.value = RouteState(uri, extra: extra);
    _cleanUpState(_prevRouteState);
    if (shouldAnimate) {
      Future.microtask(() {
        _controller.reset();
      });
    }
  }

  //
  //
  //

  bool pathExists(Uri path) {
    return builders.any((e) => e.routeState.path == path.path);
  }

  //
  //
  //

  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    return builders.any((e) {
      return e.routeState.path == path.path && e is RouteBuilder<TExtra>;
    });
  }

  //
  //
  //

  RouteBuilder? _getBuilderByPath(Uri path) {
    return builders.where((routeState) => routeState.routeState.path == path.path).firstOrNull;
  }

  //
  //
  //

  Widget? disposeState(RouteState routeState) {
    return _widgetCache.remove(routeState);
  }

  //
  //
  //

  void disposePath(Uri path) {
    _widgetCache.removeWhere((routeState, widget) => routeState.uri.path == path.path);
  }

  //
  //
  //

  void clearCache() {
    _widgetCache.clear();
  }

  //
  //
  //

  void _cleanUpState(RouteState? routeState) {
    if (routeState == null) return;
    final a = builders.where((e) => e.routeState.path == routeState.uri.path).firstOrNull;
    if (a == null) return;
    if (a.shouldPrebuild && !a.shouldPreserve) {
      // Replace with empty widget instead of removing it to avoid rebuilds.
      _widgetCache[routeState] = const SizedBox.shrink();
    }
  }

  //
  //
  //

  Widget buildScreen(BuildContext context, RouteState routeState) {
    var config = builders.where((e) => e.routeState.path == routeState.uri.path).firstOrNull;
    if (config == null) {
      return const SizedBox.shrink();
    }
    if (errorRouteState != null) {
      config =
          builders.where((e) => e.routeState.path == errorRouteState?.call().uri.path).firstOrNull;
    }
    if (config == null) {
      return const SizedBox.shrink();
    }
    _widgetCache[routeState] = Builder(builder: (context) => config!.builder(context, routeState));
    return transitionBuilder(
      context,
      RouteTransitionBuilderParams(
        controller: _controller,
        prevRouteState: _prevRouteState,
        routeState: routeState,
        prevSnapshot: _pictureWidget(),
        child: Builder(
          builder: (context) {
            _captureContext = context;
            return RepaintBoundary(
              child: Builder(
                builder: (context) {
                  return IndexedStack(
                    index: _widgetCache.keys.toList().indexOf(routeState),
                    children:
                        _widgetCache.entries.map((entry) {
                          final fullRouteState = entry.key;
                          final widget = entry.value;
                          return KeyedSubtree(key: ValueKey(fullRouteState), child: widget);
                        }).toList(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  //
  //
  //

  void dispose() {
    platformNavigator.removeStateCallback(_onStateChange);
    _pRouteState.dispose();
    _widgetCache.clear();
    _controller.clear();
  }

  //
  //
  //

  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteStateControllerProvider found in context');
    }
    return provider.controller;
  }
}
