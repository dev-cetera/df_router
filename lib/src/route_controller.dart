//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteController {
  //
  //
  //

  final _pNavigationState = Pod(
    _NavigationState(routes: [RouteState.parse('/')], index: 0),
  );

  GenericPod<_NavigationState> get pNavigationState => _pNavigationState;

  late final pCurrentRouteState = _pNavigationState.map(
    (state) => state.routes[state.index],
  );
  RouteState get currentRouteState => pCurrentRouteState.value;

  late RouteState _previousRouteForTransition = currentRouteState;

  //
  //
  //

  final _widgetCache = <RouteState, Widget>{};
  late final Map<String, RouteBuilder> _builderMap;
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;
  RouteState? _requested;
  RouteState? get requested => _requested;
  AnimationEffect _nextAnimationEffect = const NoEffect();

  //
  //
  //

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required List<RouteBuilder> builders,
  }) {
    _builderMap = {
      for (var builder in builders) builder.routeState.path: builder,
    };

    platformNavigator.addStateCallback(pushUri);
    resetState();
    _requested = current;
    final routeState =
        initialRouteState?.call() ?? _requested ?? fallbackRouteState();

    _pNavigationState.set(_NavigationState(routes: [routeState], index: 0));
    addToCache([routeState]);
  }

  //
  //
  //

  bool get canGoBack => _pNavigationState.getValue().index > 0;
  bool get canGoForward =>
      _pNavigationState.getValue().index <
      _pNavigationState.getValue().routes.length - 1;

  RouteState getNavigatorOrFallbackRouteState() =>
      _requested ?? fallbackRouteState();

  RouteState? get current {
    final browserUrl = platformNavigator.getCurrentUrl();
    if (browserUrl == null) return null;
    final appRelativeUrl = platformNavigator.stripBaseHref(browserUrl);
    return _getBuilderByPath(
      appRelativeUrl,
    )?.routeState.copyWith(queryParameters: appRelativeUrl.queryParameters);
  }

  //
  //
  //

  void clearHistory() {
    final currentState = _pNavigationState.getValue();
    final currentRoute = currentState.routes[currentState.index];
    _clearStaleRoutesFromCache(
      newRouteTimeline: [currentRoute],
      existingCacheKeys: _widgetCache.keys.toList(),
    );

    _pNavigationState.set(
      _NavigationState(routes: [currentRoute], index: 0),
      notifyImmediately: true,
    );
  }

  void addToCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is Builder) continue;
      _widgetCache[routeState] = Builder(
        key: routeState.key,
        builder: (context) => builder.builder(context, routeState),
      );
    }
  }

  void _maybeRemoveStaleRoute(RouteState routeState) {
    final builder = _getBuilderByPath(routeState.uri);
    if (builder == null) return;
    if (!builder.shouldPreserve) {
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
    }
  }

  void _clearStaleRoutesFromCache({
    required List<RouteState> newRouteTimeline,
    required List<RouteState> existingCacheKeys,
  }) {
    final newRouteSet = Set.of(newRouteTimeline);
    for (final cachedRoute in existingCacheKeys) {
      if (!newRouteSet.contains(cachedRoute)) {
        _maybeRemoveStaleRoute(cachedRoute);
      }
    }
  }

  void removeFromCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is SizedBox) continue;
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
    }
  }

  void resetState() {
    clearCache();
    final routeStates = _builderMap.values
        .where((builder) => builder.shouldPrebuild)
        .map((e) => e.routeState);
    addToCache(routeStates);
  }

  void clearCache() {
    _widgetCache.clear();
  }

  //
  //
  //

  void pushUri(
    Uri uri, {
    RouteState<Object?>? errorFallback,
    AnimationEffect forwardAnimationEffect = const NoEffect(),
    AnimationEffect backwardAnimationEffect = const NoEffect(),
  }) {
    final state = _pNavigationState.getValue();
    final indexInHistory = state.routes.indexWhere((r) => r.uri == uri);

    if (indexInHistory == state.index) return;

    if (indexInHistory != -1) {
      final didGo = go(
        indexInHistory,
        forwardAnimationEffect: forwardAnimationEffect,
        backwardAnimationEffect: backwardAnimationEffect,
      );
      if (!didGo && errorFallback != null) {
        push(
          errorFallback,
          errorFallback: errorFallback,
          animationEffect: forwardAnimationEffect,
        );
      }
    } else {
      push(
        RouteState(uri),
        errorFallback: errorFallback,
        animationEffect: forwardAnimationEffect,
      );
    }
  }

  @Deprecated('Renamed to goBackward')
  bool goBack({AnimationEffect animationEffect = const NoEffect()}) {
    return goBackward(animationEffect: animationEffect);
  }

  bool goBackward({AnimationEffect animationEffect = const NoEffect()}) {
    return step(-1, backwardAnimationEffect: animationEffect);
  }

  bool goForward({AnimationEffect animationEffect = const NoEffect()}) {
    return step(1, forwardAnimationEffect: animationEffect);
  }

  bool step(
    int steps, {
    AnimationEffect forwardAnimationEffect = const NoEffect(),
    AnimationEffect backwardAnimationEffect = const NoEffect(),
  }) {
    return go(
      _pNavigationState.getValue().index + steps,
      forwardAnimationEffect: forwardAnimationEffect,
      backwardAnimationEffect: backwardAnimationEffect,
    );
  }

  @protected
  bool go(
    int index, {
    AnimationEffect forwardAnimationEffect = const NoEffect(),
    AnimationEffect backwardAnimationEffect = const NoEffect(),
  }) {
    final state = _pNavigationState.getValue();
    if (index < 0 || index >= state.routes.length) return false;

    _previousRouteForTransition = currentRouteState;
    _nextAnimationEffect =
        index < state.index ? backwardAnimationEffect : forwardAnimationEffect;

    final newRoute = state.routes[index];
    addToCache([newRoute]); // Ensure widget exists before navigating.
    _pNavigationState.set(_NavigationState(routes: state.routes, index: index));

    platformNavigator.pushState(newRoute.uri);
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
    return true;
  }

  void push<TExtra extends Object?>(
    RouteState<TExtra> routeState, {
    RouteState? errorFallback,
    AnimationEffect? animationEffect,
  }) {
    final uri = routeState.uri;
    if (routeState.skipCurrent && currentRouteState.uri == uri) return;
    if (!_validateRoute<TExtra>(uri, routeState, errorFallback)) return;

    _nextAnimationEffect = animationEffect ?? routeState.animationEffect;
    _previousRouteForTransition = currentRouteState;

    final state = _pNavigationState.getValue();
    final currentCacheKeys = _widgetCache.keys.toList();

    final newRoutes = state.routes.sublist(0, state.index + 1);
    newRoutes.add(routeState);

    _clearStaleRoutesFromCache(
      newRouteTimeline: newRoutes,
      existingCacheKeys: currentCacheKeys,
    );

    addToCache([routeState]);

    _pNavigationState.set(
      _NavigationState(routes: newRoutes, index: newRoutes.length - 1),
      notifyImmediately: true,
    );

    platformNavigator.pushState(uri);
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
  }

  //
  //
  //

  /// Safely retrieves a [RouteState] at a specific [index] in the
  /// history and evaluates it with the provided [checker].
  ///
  /// Returns `false` if the index is out of bounds.
  bool checkRouteFromIndex(
    int index,
    bool Function(RouteState routeState) checker,
  ) {
    if (index > 0) {
      final backRoute = pNavigationState.getValue().routes[index];
      if (checker(backRoute)) {
        return true;
      }
    }
    return false;
  }

  /// Checks a [RouteState] at a relative position from the current
  /// one without performing navigation. The [step] determines
  /// the direction and distance (e.g., -1 for the previous route,1 for the next).
  /// 
  /// Returns the result of the [checker] or
  bool checkRouteFromStep(
    int step,
    bool Function(RouteState routeState) checker,
  ) {
    final index = pNavigationState.getValue().index + step;
    return checkRouteFromIndex(index, checker);
  }

  /// Whether the previous/backward route is [routeState].
  bool checkBackwardRoute(RouteState routeState) {
    return checkRouteFromStep(-1, (r) => r == routeState);
  }

  /// Whether the next/forward route is [routeState].
  bool checkForwardRoute(RouteState routeState) {
    return checkRouteFromStep(1, (r) => r == routeState);
  }

  //
  //
  //

  bool _validateRoute<TExtra extends Object?>(
    Uri uri,
    RouteState<TExtra> routeState,
    RouteState? errorFallback,
  ) {
    if (!_checkExtraTypeMismatch<TExtra>(uri)) {
      Log.err('Expected extra type $TExtra for route: $uri!');
      final error = errorFallback ?? errorRouteState?.call();
      if (error != null) push(error);
      return false;
    }
    if (!pathExists(uri)) {
      Log.err('The path $uri does not exist!');
      final error = errorFallback ?? errorRouteState?.call();
      if (error != null) push(error);
      return false;
    }
    if (!(routeState.condition?.call() ?? true)) {
      Log.err('Route condition not met for $uri!');
      return false;
    }
    if (!(_getBuilderByPath(uri)?.condition?.call() ?? true)) {
      Log.err('Builder condition not met for $uri!');
      return false;
    }
    return true;
  }

  bool pathExists(Uri path) => _builderMap.containsKey(path.path);

  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    final builder = _builderMap[path.path];
    return builder != null && builder is RouteBuilder<TExtra>;
  }

  RouteBuilder? _getBuilderByPath(Uri path) => _builderMap[path.path];

  final _globalKey = GlobalKey<AnimationEffectBuilderState>();

  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: _globalKey,
      onComplete: () {
        _maybeRemoveStaleRoute(_previousRouteForTransition);
      },
      builder: (context, results) {
        final children = _widgetCache.values.toList();
        final layerEffects =
            results.isNotEmpty ? results.map((e) => e.data).first : null;
        return PrioritizedIndexedStack(
          indices: [
            _indexOfRouteState(routeState),
            _indexOfRouteState(_previousRouteForTransition),
          ],
          layerEffects: layerEffects,
          children: children,
        );
      },
    );
  }

  int _indexOfRouteState(RouteState routeState) {
    var n = -1;
    for (final key in _widgetCache.keys) {
      n++;
      if (key == routeState) {
        return n;
      }
    }
    return -1;
  }

  static RouteController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }

  @visibleForTesting
  void dispose() {
    platformNavigator.removeStateCallback(pushUri);
    _pNavigationState.dispose();
    _widgetCache.clear();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _NavigationState {
  final List<RouteState> routes;
  final int index;

  const _NavigationState({required this.routes, required this.index});

  _NavigationState copyWith({List<RouteState>? routes, int? index}) {
    return _NavigationState(
      routes: routes ?? this.routes,
      index: index ?? this.index,
    );
  }
}
