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

// Central navigation engine. Owns the route history, widget cache, and
// animation state. Separated from the widget tree so it can be tested
// and shared across the app without depending on BuildContext.
class RouteController {
  //
  //
  //

  // A reactive Pod so the UI can subscribe to navigation changes without
  // polling or manual setState calls.
  final _pNavigationState = Pod(
    _NavigationState(routes: [RouteState.parse('/')], index: 0),
  );

  GenericPod<_NavigationState> get pNavigationState => _pNavigationState;

  // Derived Pod that extracts the current route from the navigation state.
  // Consumers only rebuild when the actual route changes, not when history
  // structure changes (e.g. forward entries being trimmed).
  late final pCurrentRouteState = _pNavigationState.map(
    (state) => state.routes[state.index],
  );
  RouteState get currentRouteState => pCurrentRouteState.value;

  // Tracks which route we're transitioning FROM so the animation system
  // knows which two screens to composite during the transition.
  late RouteState _previousRouteForTransition = currentRouteState;

  //
  //
  //

  // Keeps built widgets alive between navigations. Using RouteState as the key
  // ensures routes with different query params or extras get separate widgets.
  // SizedBox.shrink placeholders mark "disposed" slots — the entry stays so the
  // PrioritizedIndexedStack index mapping remains stable.
  final _widgetCache = <RouteState, Widget>{};
  late final Map<String, RouteBuilder> _builderMap;
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;
  // Captures what the browser's URL bar shows at construction time, so we can
  // honour deep links on first load.
  RouteState? _requested;
  RouteState? get requested => _requested;
  AnimationEffect _nextAnimationEffect = const NoEffect();
  // Guards against creating duplicate browser history entries when the browser
  // itself triggers navigation (e.g. back/forward buttons fire popstate).
  bool _isBrowserTriggered = false;

  //
  //
  //

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required List<RouteBuilder> builders,
  }) {
    // Index by path string for O(1) lookup during navigation validation.
    _builderMap = {
      for (var builder in builders) builder.routeState.uri.path: builder,
    };

    // Listen to browser popstate events so the back/forward buttons work.
    platformNavigator.addStateCallback(pushUri);
    // Pre-build routes marked shouldPrebuild so they're ready before first nav.
    resetState();
    // Resolve the browser URL as a deep link (checks isRedirectable + condition).
    _requested = _resolveDeepLink();
    // Priority: explicit initial → deep link → fallback. This order lets the
    // host app override the deep link when needed (e.g. auth redirects).
    final routeState =
        initialRouteState?.call() ?? _requested ?? fallbackRouteState();

    _pNavigationState.set(_NavigationState(routes: [routeState], index: 0));
    addToCache([routeState]);
    // Sync the browser URL AFTER the current frame. This must be deferred
    // because MaterialApp's Navigator overwrites the URL with "/" during its
    // build phase. A post-frame callback ensures we write last.
    // Capture the URI now so the callback doesn't access the Pod (which may
    // be disposed by the time the callback fires, e.g. in tests).
    final initialUri = routeState.uri;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      platformNavigator.replaceState(initialUri);
    });
  }

  //
  //
  //

  bool get canGoBackward => _pNavigationState.getValue().index > 0;
  bool get canGoForward =>
      _pNavigationState.getValue().index <
      _pNavigationState.getValue().routes.length - 1;

  RouteState getNavigatorOrFallbackRouteState() =>
      _requested ?? fallbackRouteState();

  /// Returns the RouteState for the current browser URL, or null if the URL
  /// doesn't match any registered route.
  RouteState? get current {
    final browserUrl = platformNavigator.getCurrentUrl();
    if (browserUrl == null) return null;
    final appRelativeUrl = platformNavigator.stripBaseHref(browserUrl);
    return _getBuilderByPath(
      appRelativeUrl,
    )?.routeState.copyWith(queryParameters: appRelativeUrl.queryParameters);
  }

  /// Resolves the current browser URL into a deep link RouteState. Returns null
  /// if no matching route exists, the route is not redirectable, or its
  /// condition is not met.
  RouteState? _resolveDeepLink() {
    final browserUrl = platformNavigator.getCurrentUrl();
    if (browserUrl == null) return null;
    final relative = platformNavigator.stripBaseHref(browserUrl);
    final builder = _getBuilderByPath(relative);
    if (builder == null) return null;
    if (!builder.isRedirectable) return null;
    if (!(builder.condition?.call() ?? true)) return null;
    return builder.routeState
        .copyWith(queryParameters: relative.queryParameters);
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

  // Only creates widgets that don't already exist (or were disposed to
  // SizedBox placeholders). RepaintBoundary isolates each screen's repaints
  // so animations on one screen don't trigger repaints of others. Builder
  // defers the actual widget construction until layout time, when
  // BuildContext is available.
  void addToCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      final existing = _widgetCache[routeState];
      if (existing != null && existing is! SizedBox) continue;
      _widgetCache[routeState] = RepaintBoundary(
        key: routeState.key,
        child: Builder(
          builder: (context) => builder.builder(context, routeState),
        ),
      );
    }
  }

  _TPreservationStrategy _preservationStrategy = defaultPreservationStrategy;

  static _TPreservationStrategy defaultPreservationStrategy =
      (routeBuilder, routeState) =>
          routeBuilder.shouldPreserve || routeState.shouldPreserve;

  void setPreservationStrategy(_TPreservationStrategy preservationStrategy) =>
      _preservationStrategy = preservationStrategy;

  // Replaces the cached widget with an empty SizedBox instead of removing it,
  // so the PrioritizedIndexedStack's child indices remain stable. Preserved
  // routes skip this step entirely to keep their state alive across navigations.
  void _maybeRemoveStaleRoute(RouteState routeState) {
    final routeBuilder = _getBuilderByPath(routeState.uri);
    if (routeBuilder == null) return;
    // Pass both the builder and the actual history route state separately,
    // avoiding copyWith which fails due to generic type mismatch.
    if (!_preservationStrategy(routeBuilder, routeState)) {
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

  // Entry point for browser-initiated navigation (popstate events). When the
  // browser fires popstate, it has ALREADY changed its URL bar, so we must NOT
  // call pushState again — otherwise we'd create a duplicate history entry and
  // break the back/forward stack. The _isBrowserTriggered flag prevents that.
  void pushUri(
    Uri uri, {
    RouteState<Object?>? errorFallback,
    AnimationEffect forwardAnimationEffect = const NoEffect(),
    AnimationEffect backwardAnimationEffect = const NoEffect(),
  }) {
    final state = _pNavigationState.getValue();
    final indexInHistory = state.routes.indexWhere((r) => r.uri == uri);

    // Already on this route — nothing to do.
    if (indexInHistory == state.index) return;

    _isBrowserTriggered = true;
    try {
      if (indexInHistory != -1) {
        // URI exists in our history — jump to it rather than creating a new
        // entry, which preserves the user's mental model of back/forward.
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
        // Unknown URI (typed in manually or external link) — treat as a new
        // push if a builder exists and is redirectable, otherwise fall back.
        final builder = _getBuilderByPath(uri);
        if (builder != null && builder.isRedirectable) {
          push(
            RouteState(uri),
            errorFallback: errorFallback,
            animationEffect: forwardAnimationEffect,
          );
        } else {
          if (builder != null && !builder.isRedirectable) {
            Log.alert('Route $uri is not redirectable from browser URL.');
          }
          push(
            errorFallback ?? fallbackRouteState(),
            animationEffect: forwardAnimationEffect,
          );
        }
      }
    } finally {
      _isBrowserTriggered = false;
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

  // Moves to an absolute index in the history list WITHOUT modifying the list.
  // This is what powers goBackward/goForward — they just step the index.
  // Protected because callers should use push/goBackward/goForward/step instead;
  // direct index access is only needed internally or in tests.
  @protected
  bool go(
    int index, {
    AnimationEffect forwardAnimationEffect = const NoEffect(),
    AnimationEffect backwardAnimationEffect = const NoEffect(),
  }) {
    final state = _pNavigationState.getValue();
    if (index < 0 || index >= state.routes.length) return false;

    _previousRouteForTransition = currentRouteState;
    // Pick the right animation direction based on whether we're going
    // backward or forward in the history.
    _nextAnimationEffect =
        index < state.index ? backwardAnimationEffect : forwardAnimationEffect;

    final newRoute = state.routes[index];
    // Ensure the target widget is built before we show it.
    addToCache([newRoute]);
    _pNavigationState.set(_NavigationState(routes: state.routes, index: index));

    // Only sync the browser URL when the navigation was app-initiated.
    // Browser-initiated navigations (popstate) have already updated the URL.
    // Use replaceState (not pushState) because go() moves within existing
    // history — pushState would add duplicate browser entries and cause
    // back/forward oscillation loops.
    if (!_isBrowserTriggered) {
      platformNavigator.replaceState(newRoute.uri);
    }
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
    return true;
  }

  // Appends a new route, truncating any forward history (like a web browser).
  // This is the primary navigation method — go() just moves the cursor,
  // push() actually grows the history.
  void push<TExtra extends Object?>(
    RouteState<TExtra> routeState, {
    RouteState? errorFallback,
    AnimationEffect? animationEffect,
  }) {
    final uri = routeState.uri;
    // skipCurrent prevents accidental double-pushes (e.g. rapid button taps).
    if (routeState.skipCurrent && currentRouteState.uri == uri) return;
    if (!_validateRoute<TExtra>(uri, routeState, errorFallback)) return;

    _nextAnimationEffect = animationEffect ?? routeState.animationEffect;
    _previousRouteForTransition = currentRouteState;

    final state = _pNavigationState.getValue();
    final currentCacheKeys = _widgetCache.keys.toList();

    // Truncate forward history — same semantics as browser navigation.
    // Any routes after the current index are discarded.
    final newRoutes = state.routes.sublist(0, state.index + 1);
    newRoutes.add(routeState);

    // Clean up widgets for routes that are no longer in the timeline,
    // unless they're marked as preserved.
    _clearStaleRoutesFromCache(
      newRouteTimeline: newRoutes,
      existingCacheKeys: currentCacheKeys,
    );

    addToCache([routeState]);

    _pNavigationState.set(
      _NavigationState(routes: newRoutes, index: newRoutes.length - 1),
      notifyImmediately: true,
    );

    if (!_isBrowserTriggered) {
      platformNavigator.pushState(uri);
    }
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
    final routes = pNavigationState.getValue().routes;
    if (index >= 0 && index < routes.length) {
      final b = routes[index];
      return checker(b);
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
    // Check path existence first — a missing path is a different problem
    // than a type mismatch, and deserves a distinct error message.
    if (!pathExists(uri)) {
      Log.err('The path $uri does not exist!');
      final error = errorFallback ?? errorRouteState?.call();
      if (error != null) push(error);
      return false;
    }
    if (!_checkExtraTypeMismatch<TExtra>(uri)) {
      Log.err('Expected extra type $TExtra for route: $uri!');
      final error = errorFallback ?? errorRouteState?.call();
      if (error != null) push(error);
      return false;
    }
    if (!(routeState.condition?.call() ?? true)) {
      Log.alert('Route condition not met for $uri!');
      return false;
    }
    if (!(_getBuilderByPath(uri)?.condition?.call() ?? true)) {
      Log.alert('Builder condition not met for $uri!');
      return false;
    }
    return true;
  }

  bool pathExists(Uri path) => _builderMap.containsKey(path.path);

  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    final builder = _builderMap[path.path];
    // If no builder exists, pathExists already handles it — no type mismatch.
    if (builder == null) return true;
    return builder is RouteBuilder<TExtra>;
  }

  RouteBuilder? _getBuilderByPath(Uri path) => _builderMap[path.path];

  final _globalKey = GlobalKey<AnimationEffectBuilderState>();

  // Builds the visual output: a PrioritizedIndexedStack that shows two layers
  // (current + previous) during transitions, with AnimationEffectBuilder
  // driving the interpolation. The current route is on top; the previous route
  // is below it and gets cleaned up once the animation completes.
  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: _globalKey,
      // Only dispose the old screen AFTER the animation finishes, so the
      // user sees a smooth transition rather than a blank frame.
      onComplete: () {
        _maybeRemoveStaleRoute(_previousRouteForTransition);
      },
      builder: (context, results) {
        final children = _widgetCache.values.toList();
        final layerEffects =
            results.isNotEmpty ? results.map((e) => e.data).first : null;
        return PrioritizedIndexedStack(
          // Two indices: current on top, previous underneath. The stack
          // renders bottom-up so index 0 is the topmost visible layer.
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

  // Marked visibleForTesting because in production the controller lives as
  // long as the app. Tests need explicit disposal to avoid leaked listeners.
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

typedef _TPreservationStrategy = bool Function(
  RouteBuilder routeBuilder,
  RouteState routeState,
);
