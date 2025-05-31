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

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:df_pwa_utils/df_pwa_utils.dart';
import 'package:df_widgets/_common.dart';
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
    for (final builder in builders) {
      _widgetCache[builder.routeState] = SizedBox.shrink(key: builder.routeState.key);
    }
    platformNavigator.addStateCallback(pushUri);
    push(routeState);
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

  void addStatesToCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is Builder) continue;
      _widgetCache[routeState] = Builder(
        key: routeState.key,
        builder: (context) {
          return builder.builder(context, routeState);
        },
      );

      _pRouteState.notifyListeners();
    }
  }

  //
  //
  //

  void removeStatesFromCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is SizedBox) continue;
      _widgetCache[routeState] = SizedBox.shrink(key: _widgetCache[routeState]?.key);
      _pRouteState.notifyListeners();
    }
  }

  //
  //
  //

  void clearCache() {
    removeStatesFromCache(_widgetCache.keys);
  }

  //
  //
  //

  // void resetCache() {
  //   clearCache();
  //   final routeStates = builders
  //       .where((builder) => builder.shouldPrebuild)
  //       .map((e) => e.routeState);
  //   cacheStates(routeStates);
  // }

  //
  //
  //

  void pushUri(Uri uri) => push(RouteState(uri));

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
    print('PUSHING!!!');
    final uri = routeState.uri;
    final skipCurrent = routeState.skipCurrent;
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
    final condition = routeState.condition;
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
    platformNavigator.pushState(uri);
    _prevRouteState = _pRouteState.value;
    _pRouteState.value = routeState;
    addStatesToCache([routeState]);
    // final shouldAnimate = routeState.shouldAnimate;
    // if (shouldAnimate) {
    //   Future.microtask(() {
    //     _controller.reset();
    //   });
    // }
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

  Widget buildScreen(BuildContext context, RouteState routeState) {
    // return IndexedStack(
    //   index: _widgetCache.keys.toList().indexOf(routeState),
    //   children: _widgetCache.values.toList(),
    // );

    return AnimatedStackWrapper(
      indices: [
        _widgetCache.keys.toList().indexOf(routeState),
        _widgetCache.keys.toList().indexOf(_prevRouteState),
      ],

      children: _widgetCache.values.toList(),
      transition: PISTopLayerSlideTransition(),
    );
  }

  //
  //
  //

  void dispose() {
    platformNavigator.removeStateCallback(pushUri);
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
