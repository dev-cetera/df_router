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

  // Tentative-navigation state. When `_tentativeTarget` is non-null, an
  // interactive gesture (e.g. `DragNavigable`) is mid-transition: the
  // animation controller's value is driven by the gesture rather than the
  // standard restart() pipeline, and `buildScreen` renders the tentative
  // target as the incoming layer over the current route. Calling
  // `commitTentative()` flips the controller's state machine into the
  // committed navigation; `abortTentative()` reverses the animation and
  // discards the target.
  RouteState? _tentativeTarget;

  /// Whether a tentative (gesture-driven) navigation is currently active.
  bool get isTentativeActive => _tentativeTarget != null;

  //
  //
  //

  // The widget cache and its index map use IDENTITY-based equality, not
  // the value-equality `RouteState` inherits from `Equatable`. This lets
  // the same URI appear multiple times in the navigation stack with each
  // occurrence holding a distinct widget element. With value-equality,
  // `[home, dialog, dialog, dialog]` would collapse to two cache entries
  // and the three dialogs would share one widget instance — dismissing
  // any of them would dismiss all of them.
  final _widgetCache = LinkedHashMap<RouteState, Widget>(
    equals: identical,
    hashCode: identityHashCode,
  );
  // Memoized derivatives of `_widgetCache`, invalidated by `_invalidateCache`.
  // `buildScreen`'s AnimatedBuilder builder fires on every animation frame
  // (60–120 Hz). Without these, every frame would allocate a new `List<Widget>`
  // and run two O(n) linear scans of the cache keys.
  List<Widget>? _cachedChildren;
  Map<RouteState, int>? _cachedIndexMap;

  void _invalidateCachedViews() {
    _cachedChildren = null;
    _cachedIndexMap = null;
  }

  List<Widget> _childrenSnapshot() =>
      _cachedChildren ??= _widgetCache.values.toList(growable: false);

  Map<RouteState, int> _indexMap() {
    if (_cachedIndexMap != null) return _cachedIndexMap!;
    // Identity-keyed to match `_widgetCache` — otherwise duplicate-URI
    // RouteStates would collide in this lookup table and the second one
    // would overwrite the first's index.
    final map = LinkedHashMap<RouteState, int>(
      equals: identical,
      hashCode: identityHashCode,
    );
    var i = 0;
    for (final key in _widgetCache.keys) {
      map[key] = i++;
    }
    return _cachedIndexMap = map;
  }

  late final Map<String, RouteBuilder> _builderMap;
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;
  RouteState? _requested;
  RouteState? get requested => _requested;
  AnimationEffect _nextAnimationEffect = const NoEffect();

  //
  //
  //

  final UrlStrategy urlStrategy;

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required List<RouteBuilder> builders,
    this.urlStrategy = UrlStrategy.flat,
  }) {
    // Validation runs in BOTH debug and release. The previous version wrapped
    // these checks in `assert(() { ... return true; }())`, which is stripped
    // entirely in release builds — meaning misconfigurations could ship to
    // production with no diagnostic. Duplicate paths log a loud warning
    // (last-registration-wins is occasionally intentional). The `+`
    // delimiter under `UrlStrategy.stacked` would silently corrupt URL
    // encoding, so we throw immediately.
    final seen = <String>{};
    for (final b in builders) {
      final path = _normalizePath(b.routeState.uri);
      if (!seen.add(path)) {
        Log.err(
          'Duplicate RouteBuilder for path "$path" — last registration '
          'wins. Each route path should appear at most once in the '
          'builders list.',
        );
      }
      if (urlStrategy == UrlStrategy.stacked &&
          path.contains(RouteStackUri.delimiter)) {
        throw ArgumentError.value(
          path,
          'builders',
          'Route path contains "${RouteStackUri.delimiter}", which is '
              'reserved as the stack delimiter under UrlStrategy.stacked. '
              'Rename the route or switch to UrlStrategy.flat.',
        );
      }
    }

    _builderMap = {
      for (var builder in builders)
        _normalizePath(builder.routeState.uri): builder,
    };

    platformNavigator.addStateCallback(_handlePopState);
    resetState();

    final resolved = _resolveInitialRoutes(initialRouteState);

    _pNavigationState.set(
      _NavigationState(
        routes: resolved.routes,
        index: resolved.currentIndex,
      ),
    );
    // When cold-booting into a stack of two or more routes (typical for
    // `UrlStrategy.stacked` deep links like `/home+/sheet`), prime the
    // "previous for transition" slot with the entry directly below the
    // CURRENT index — not below the top of the list, because under
    // forward-history-aware decoding the list can extend past the current.
    // Without this, the `late` initializer on `_previousRouteForTransition`
    // assigns `currentRouteState` — i.e. the active route — on first read,
    // so `buildScreen` produces `indices = [top, top]` and the base under
    // the active route never paints.
    if (resolved.currentIndex >= 1) {
      _previousRouteForTransition = resolved.routes[resolved.currentIndex - 1];
    }
    addToCache(resolved.routes);
    // Canonicalize the browser URL to whatever stack we actually resolved.
    platformNavigator.replaceState(_encodeBrowserUri());
  }

  /// Decides what `pNavigationState.routes` and `index` should look like at
  /// construction time. Honors `initialRouteState` first; otherwise falls
  /// back to the browser URL — which, under `UrlStrategy.stacked`, can
  /// rehydrate the entire navigation history including forward routes (the
  /// URL fragment carries any routes beyond the active one).
  ({List<RouteState> routes, int currentIndex}) _resolveInitialRoutes(
    RouteState Function()? initialRouteState,
  ) {
    if (initialRouteState != null) {
      var rs = initialRouteState();
      if (!_isRouteValidForBoot(rs)) {
        rs = errorRouteState?.call() ?? fallbackRouteState();
      }
      return (routes: [_reuseFromPrebuilt(rs)], currentIndex: 0);
    }
    if (urlStrategy == UrlStrategy.stacked) {
      final stack = _readStackFromUrl();
      if (stack != null && stack.routes.isNotEmpty) {
        return (
          routes: stack.routes.map(_reuseFromPrebuilt).toList(),
          currentIndex: stack.currentIndex,
        );
      }
    }
    _requested = current;
    var rs = _requested ?? fallbackRouteState();
    if (!_isRouteValidForBoot(rs)) {
      rs = errorRouteState?.call() ?? fallbackRouteState();
    }
    return (routes: [_reuseFromPrebuilt(rs)], currentIndex: 0);
  }

  /// If [target] matches (by value) one of the routes registered with
  /// `shouldPrebuild: true`, return the BUILDER's canonical `RouteState`
  /// instance instead of [target]. That canonical instance is what
  /// `resetState()` adds to the cache at construction time, so reusing it
  /// here avoids creating a second Builder for the same prebuilt route
  /// (which would fire `initState` twice and double-mount the screen).
  ///
  /// Unlike the broader `_findReusableInCacheByValue`, this method does
  /// NOT touch arbitrary preserved entries — so cold-boot stacks like
  /// `/home+/dialog+/dialog` don't accidentally collapse the two
  /// `/dialog` segments into one shared widget.
  RouteState _reuseFromPrebuilt(RouteState target) {
    for (final b in _builderMap.values) {
      if (!b.shouldPrebuild) continue;
      if (b.routeState == target) return b.routeState;
    }
    return target;
  }

  /// Reads the browser URL, decodes it as a stacked URI (path + fragment),
  /// and returns the VALID route states plus the index of the active one.
  ///
  /// URL layout under `UrlStrategy.stacked`:
  ///   - **Path** holds the *visible* stack (`routes[0..currentIndex]`),
  ///     joined by `+`. The active route's queryParameters ride in the
  ///     standard `?` clause.
  ///   - **Fragment** holds the *forward* stack (`routes[currentIndex+1..]`),
  ///     joined by `+`, with each segment's queryParameters in a `;` matrix
  ///     clause. Browsers don't send fragments to servers, so this is a
  ///     SPA-friendly place to stash forward history that survives reloads
  ///     without affecting server routing.
  ///
  /// Returns null when the URL isn't shaped like a stacked URI AND has no
  /// fragment; returns null when nothing validates — callers treat both
  /// as "fall back to single-route boot."
  ({List<RouteState> routes, int currentIndex})? _readStackFromUrl() {
    final browserUrl = platformNavigator.getCurrentUrl();
    if (browserUrl == null) return null;
    final appRelativeUrl = platformNavigator.stripBaseHref(browserUrl);

    final hasStackedPath = RouteStackUri.isStacked(appRelativeUrl);
    final hasFragment = appRelativeUrl.fragment.isNotEmpty;
    if (!hasStackedPath && !hasFragment) return null;

    final visible = <RouteState>[];
    for (final segUri in RouteStackUri.decode(appRelativeUrl)) {
      final rs = _routeStateForSegment(segUri);
      if (rs != null) visible.add(rs);
    }
    final forward = <RouteState>[];
    if (hasFragment) {
      for (final segUri
          in RouteStackUri.decodeSegments(appRelativeUrl.fragment)) {
        final rs = _routeStateForSegment(segUri);
        if (rs != null) forward.add(rs);
      }
    }

    if (visible.isEmpty && forward.isEmpty) return null;

    // No valid visible portion but valid forward portion: promote the first
    // forward entry to be the active route (better than a blank screen).
    if (visible.isEmpty) {
      return (routes: forward, currentIndex: 0);
    }

    return (
      routes: [...visible, ...forward],
      currentIndex: visible.length - 1,
    );
  }

  /// Resolves a single URL segment (path + optional query) into a
  /// `RouteState` ready to live in the navigation history. Returns null if
  /// the segment names an unregistered path or fails any guard condition.
  RouteState? _routeStateForSegment(Uri segUri) {
    final builder = _getBuilderByPath(segUri);
    if (builder == null) return null;
    final rs = builder.routeState.copyWith(
      queryParameters: segUri.queryParameters,
    );
    if (!(rs.condition?.call() ?? true)) return null;
    if (!(builder.condition?.call() ?? true)) return null;
    return rs;
  }

  /// The current authoritative URL representation — what we send to
  /// `pushState` / `replaceState`.
  ///
  /// For `UrlStrategy.flat` this is just the active route's URI.
  ///
  /// For `UrlStrategy.stacked` the visible stack lives in the path (with
  /// the active route's query in the standard `?` clause), and any
  /// forward-history routes (`routes[index+1..]`) are encoded into the
  /// URL fragment. The fragment ride-along means a reload of a "stepped
  /// back" page recovers BOTH directions of history — `goForward` /
  /// browser-forward still work after a refresh.
  Uri _encodeBrowserUri() {
    if (urlStrategy == UrlStrategy.flat) {
      return currentRouteState.uri;
    }
    final state = _pNavigationState.getValue();
    final visible = [
      for (var i = 0; i <= state.index; i++) state.routes[i].uri,
    ];
    final base = RouteStackUri.encode(visible);
    if (state.index >= state.routes.length - 1) return base;
    final forward = [
      for (var i = state.index + 1; i < state.routes.length; i++)
        state.routes[i].uri,
    ];
    return base.replace(
      fragment: RouteStackUri.encodeSegments(forward),
    );
  }

  bool _isRouteValidForBoot(RouteState routeState) {
    if (!pathExists(routeState.uri)) return false;
    if (!(routeState.condition?.call() ?? true)) return false;
    if (!(_getBuilderByPath(routeState.uri)?.condition?.call() ?? true)) {
      return false;
    }
    return true;
  }

  /// True while a popstate event is being handled. Suppresses
  /// `platformNavigator.pushState` calls so we don't double-push the browser
  /// history when syncing from the browser's own back/forward navigation.
  bool _suppressBrowserSync = false;

  void _handlePopState(Uri uri) {
    _suppressBrowserSync = true;
    try {
      if (urlStrategy == UrlStrategy.stacked &&
          (RouteStackUri.isStacked(uri) || uri.fragment.isNotEmpty)) {
        _syncStackFromPopState(uri);
      } else {
        pushUri(uri);
      }
    } finally {
      _suppressBrowserSync = false;
    }
  }

  /// Reconciles the in-memory navigation history with a stacked URI that
  /// just arrived via browser popstate.
  ///
  /// The URL carries the FULL navigation timeline: visible routes in the
  /// path, forward-history routes in the fragment. If the URL's full
  /// stack matches our existing `routes` exactly (by URI), we just move
  /// the index — preserving cached widgets so `goForward` / browser
  /// forward still snap back to the same instances. Otherwise we rebuild
  /// `routes` from the URL.
  void _syncStackFromPopState(Uri uri) {
    final visibleUris = RouteStackUri.decode(uri);
    final forwardUris = uri.fragment.isEmpty
        ? const <Uri>[]
        : RouteStackUri.decodeSegments(uri.fragment);
    final allUris = [...visibleUris, ...forwardUris];
    final newIndex = visibleUris.length - 1;

    final state = _pNavigationState.getValue();

    final routesMatch = allUris.length == state.routes.length &&
        () {
          for (var i = 0; i < allUris.length; i++) {
            if (!_urisMatch(state.routes[i].uri, allUris[i])) return false;
          }
          return true;
        }();

    if (routesMatch) {
      if (newIndex == state.index) return;
      _previousRouteForTransition = currentRouteState;
      _pNavigationState.set(
        _NavigationState(routes: state.routes, index: newIndex),
      );
      _globalKey.currentState?.setEffects([_nextAnimationEffect]);
      _globalKey.currentState?.restart();
      return;
    }

    final validRoutes = <RouteState>[];
    for (final segUri in allUris) {
      final rs = _routeStateForSegment(segUri);
      if (rs == null) continue;
      validRoutes.add(rs);
    }
    if (validRoutes.isEmpty) {
      validRoutes.add(fallbackRouteState());
    }

    _previousRouteForTransition = currentRouteState;
    _clearStaleRoutesFromCache(
      newRouteTimeline: validRoutes,
      existingCacheKeys: _widgetCache.keys.toList(),
    );
    addToCache(validRoutes);
    // Index = end of the visible portion (number of valid visible routes
    // minus 1), clamped into bounds so a hand-typed URL with only forward
    // segments still lands somewhere sensible.
    final clampedIndex = newIndex.clamp(0, validRoutes.length - 1);
    _pNavigationState.set(
      _NavigationState(routes: validRoutes, index: clampedIndex),
    );
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
  }

  void _maybePushBrowserState(Uri uri) {
    if (_suppressBrowserSync) return;
    platformNavigator.pushState(_encodeBrowserUri());
  }

  //
  //
  //

  bool get canGoBackward => _pNavigationState.getValue().index > 0;
  bool get canGoForward {
    final state = _pNavigationState.getValue();
    return state.index < state.routes.length - 1;
  }

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

    _pNavigationState.set(_NavigationState(routes: [currentRoute], index: 0));
  }

  void addToCache(Iterable<RouteState> routeStates) {
    var mutated = false;
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is Builder) continue;
      _widgetCache[routeState] = Builder(
        key: routeState.key,
        builder: (context) => builder.builder(context, routeState),
      );
      mutated = true;
    }
    if (mutated) _invalidateCachedViews();
  }

  _TPreservationStrategy _preservationStrategy = defaultPreservationStrategy;

  static _TPreservationStrategy defaultPreservationStrategy = (routeBuider) =>
      routeBuider.shouldPreserve || routeBuider.routeState.shouldPreserve;

  void setPreservationStrategy(_TPreservationStrategy preservationStrategy) =>
      _preservationStrategy = preservationStrategy;

  void _maybeRemoveStaleRoute(RouteState routeState) {
    // An overlay route (modal, dialog, bottom sheet) renders on top of its
    // predecessor and expects that predecessor to remain visible underneath.
    // Without this guard, the standard preservation policy would replace the
    // base widget with a SizedBox.shrink the moment the overlay's forward
    // transition completes, leaving empty space behind the modal.
    if (_isBaseUnderCurrentOverlay(routeState)) return;
    final routeBuilder = _getBuilderByPath(
      routeState.uri,
    )?.copyWith(routeState: routeState);
    if (routeBuilder == null) return;
    if (_preservationStrategy(routeBuilder)) return;
    // If this route is still referenced (current or pending transition), keep
    // it as a placeholder so PrioritizedIndexedStack indices stay stable.
    // Otherwise drop it entirely to let GC reclaim the widget tree.
    final stillReferenced = identical(routeState, currentRouteState) ||
        identical(routeState, _previousRouteForTransition);
    if (stillReferenced) {
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
      // The map order/keys are unchanged but the widget at this slot is now a
      // different instance, so the children snapshot has to be rebuilt.
      _cachedChildren = null;
    } else {
      _widgetCache.remove(routeState);
      _invalidateCachedViews();
    }
  }

  /// True if [routeState] is the entry immediately beneath the current route
  /// and the current route's builder declares itself an overlay. Used to keep
  /// the base widget alive (so a modal can render against it) regardless of
  /// the base's own preservation flag.
  bool _isBaseUnderCurrentOverlay(RouteState routeState) {
    final state = _pNavigationState.getValue();
    if (state.index == 0) return false;
    final currentBuilder = _getBuilderByPath(currentRouteState.uri);
    if (currentBuilder == null || !currentBuilder.isOverlay) return false;
    // Identity check — under the new identity-keyed cache, equal-by-value
    // RouteStates (same uri+extra) at different stack positions are
    // distinct entries and must not be conflated here.
    return identical(state.routes[state.index - 1], routeState);
  }

  void _clearStaleRoutesFromCache({
    required List<RouteState> newRouteTimeline,
    required List<RouteState> existingCacheKeys,
  }) {
    // Identity set so duplicate-URI entries in the new timeline don't all
    // collapse into one "kept" key. Each cached RouteState instance is
    // compared by identity against the new timeline.
    final newRouteSet = Set<RouteState>.identity()..addAll(newRouteTimeline);
    for (final cachedRoute in existingCacheKeys) {
      if (!newRouteSet.contains(cachedRoute)) {
        _maybeRemoveStaleRoute(cachedRoute);
      }
    }
  }

  void removeFromCache(Iterable<RouteState> routeStates) {
    var mutated = false;
    for (final routeState in routeStates) {
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      final stillReferenced = identical(routeState, currentRouteState) ||
          identical(routeState, _previousRouteForTransition);
      if (stillReferenced) {
        if (_widgetCache[routeState] is SizedBox) continue;
        _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
        mutated = true;
      } else {
        if (_widgetCache.remove(routeState) != null) mutated = true;
      }
    }
    if (mutated) _invalidateCachedViews();
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
    _invalidateCachedViews();
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
    // If [uri] is a stack-encoded URL (path contains `+`), treat it as a
    // multi-route push: decode into segments and append all of them above
    // the current top, running a single transition into the new topmost
    // route. Lets callers do `controller.pushUri(Uri.parse('/sheet+/dialog'))`
    // and end up with both routes added in one call.
    if (RouteStackUri.isStacked(uri)) {
      _pushStack(
        RouteStackUri.decode(uri),
        errorFallback: errorFallback,
        animationEffect: forwardAnimationEffect,
      );
      return;
    }

    final state = _pNavigationState.getValue();
    final indexInHistory = state.routes.indexWhere(
      (r) => _urisMatch(r.uri, uri),
    );

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

  /// Appends every valid route in [segmentUris] to the current visible stack
  /// in a single update, animating only the final transition into the new
  /// topmost route. Used by `pushUri` (and `push`, indirectly) when the
  /// incoming URI is stack-encoded — `/sheet+/dialog+/toast` becomes three
  /// pushes that share one pNavigationState mutation and one URL update.
  void _pushStack(
    List<Uri> segmentUris, {
    RouteState? errorFallback,
    AnimationEffect animationEffect = const NoEffect(),
  }) {
    final resolved = <RouteState>[];
    for (final seg in segmentUris) {
      final rs = _routeStateForSegment(seg);
      if (rs == null) {
        // Loud — silent dropping of segments was previously hiding URL
        // typos and registry mismatches. Callers landing in this branch
        // typically have a typo'd path or a builder condition that's
        // returning false during cold-boot.
        Log.alert(
          'Stack segment "$seg" was dropped: path is unregistered or a '
          'route/builder condition returned false. The remaining segments '
          'will still be pushed.',
        );
        continue;
      }
      resolved.add(_reuseFromPrebuilt(rs));
    }
    if (resolved.isEmpty) {
      Log.alert(
        'Stack push resolved to zero routes — all segments failed '
        'validation. Falling back to errorFallback if provided.',
      );
      if (errorFallback != null) push(errorFallback);
      return;
    }

    _nextAnimationEffect = animationEffect;
    _previousRouteForTransition = currentRouteState;

    final state = _pNavigationState.getValue();
    final newRoutes = state.routes.sublist(0, state.index + 1)
      ..addAll(resolved);

    _clearStaleRoutesFromCache(
      newRouteTimeline: newRoutes,
      existingCacheKeys: _widgetCache.keys.toList(),
    );
    addToCache(resolved);

    _pNavigationState.set(
      _NavigationState(routes: newRoutes, index: newRoutes.length - 1),
    );

    _maybePushBrowserState(resolved.last.uri);
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
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

    _maybePushBrowserState(newRoute.uri);
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
    // If the caller hands us a stack-encoded URI (e.g.
    // `RouteState(Uri.parse('/sheet+/dialog'))`), expand it into multiple
    // routes and push them all in one go. The per-route registered builders
    // own the animationEffect / condition for each segment; the
    // [animationEffect] arg here applies to the final transition.
    if (RouteStackUri.isStacked(uri)) {
      _pushStack(
        RouteStackUri.decode(uri),
        errorFallback: errorFallback,
        animationEffect: animationEffect ?? routeState.animationEffect,
      );
      return;
    }
    if (routeState.skipCurrent && currentRouteState.uri == uri) return;
    if (!_validateRoute<TExtra>(uri, routeState, errorFallback)) return;

    _nextAnimationEffect = animationEffect ?? routeState.animationEffect;
    _previousRouteForTransition = currentRouteState;

    // Decide whether to dedup against the cache. Two modes:
    //
    //   skipCurrent=true (default) — the caller is saying "navigate to
    //   this route." If there's a live preserved widget with the same
    //   `(uri, extra)`, reuse it so `shouldPreserve` actually preserves
    //   State across re-visits (matches the controller's flat-strategy
    //   behavior before identity keying).
    //
    //   skipCurrent=false — the caller is saying "push this as a distinct
    //   stack entry, even if the same URI is already on top or below."
    //   Skip the cache lookup so each call produces its own widget (the
    //   modal-stacking case: dismissing one doesn't dismiss the others).
    //   Prebuilt routes still dedup so we don't accidentally double-mount
    //   a prebuilt widget.
    final RouteState effectiveRouteState;
    if (routeState.skipCurrent) {
      effectiveRouteState =
          _findReusableInCacheByValue(routeState) ?? routeState;
    } else {
      effectiveRouteState = _reuseFromPrebuilt(routeState);
    }

    final state = _pNavigationState.getValue();
    final currentCacheKeys = _widgetCache.keys.toList();

    final newRoutes = state.routes.sublist(0, state.index + 1);
    newRoutes.add(effectiveRouteState);

    _clearStaleRoutesFromCache(
      newRouteTimeline: newRoutes,
      existingCacheKeys: currentCacheKeys,
    );

    addToCache([effectiveRouteState]);

    _pNavigationState.set(
      _NavigationState(routes: newRoutes, index: newRoutes.length - 1),
    );

    _maybePushBrowserState(uri);
    _globalKey.currentState?.setEffects([_nextAnimationEffect]);
    _globalKey.currentState?.restart();
  }

  /// Walk the cache and return any key that's `==` to [target] AND still
  /// holds a live `Builder` widget (not a placeholder `SizedBox.shrink`
  /// from prior eviction). Returns null if no reusable entry exists.
  ///
  /// Used by `push` to honor the `shouldPreserve` contract under the new
  /// identity-keyed cache: an explicit re-push of an equivalent route
  /// rejoins its preserved widget element instead of being treated as a
  /// brand-new push that allocates a fresh widget (and resets State).
  RouteState? _findReusableInCacheByValue(RouteState target) {
    for (final entry in _widgetCache.entries) {
      if (entry.key == target && entry.value is Builder) {
        return entry.key;
      }
    }
    return null;
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

  bool pathExists(Uri path) => _builderMap.containsKey(_normalizePath(path));

  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    final builder = _builderMap[_normalizePath(path)];
    // If the path isn't registered there's no type to mismatch — return true
    // here so the subsequent `pathExists` check in `_validateRoute` reports
    // the real cause. Otherwise the developer sees a confusing
    // "Expected extra type X for route: /typo" message that points at the
    // generic parameter instead of the missing builder.
    if (builder == null) return true;
    return builder is RouteBuilder<TExtra>;
  }

  RouteBuilder? _getBuilderByPath(Uri path) =>
      _builderMap[_normalizePath(path)];

  static String _normalizePath(Uri uri) {
    var p = uri.path;
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p.isEmpty ? '/' : p;
  }

  /// URI equality that ignores query-parameter ordering and treats a missing
  /// fragment as equivalent across both URIs.
  static bool _urisMatch(Uri a, Uri b) {
    if (_normalizePath(a) != _normalizePath(b)) return false;
    if (a.queryParameters.length != b.queryParameters.length) return false;
    for (final entry in a.queryParameters.entries) {
      if (b.queryParameters[entry.key] != entry.value) return false;
    }
    if (a.fragment != b.fragment) return false;
    return true;
  }

  final _globalKey = GlobalKey<AnimationEffectBuilderState>();

  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: _globalKey,
      onComplete: () {
        _maybeRemoveStaleRoute(_previousRouteForTransition);
      },
      builder: (context, results) {
        // Both the children list and the indices are stable for the duration
        // of an animation — only `layerEffects` changes per frame. Reuse the
        // memoized list/map; the cache invalidates whenever `_widgetCache`
        // mutates (navigation, addToCache, removeFromCache, etc.).
        final children = _childrenSnapshot();
        final indexMap = _indexMap();
        final layerEffects = results.isNotEmpty ? results.first.data : null;

        // During a tentative navigation (e.g. user mid-drag), `pNavigationState`
        // has NOT yet been mutated — the actual current route is still the
        // page the user is leaving. We render the tentative target as the
        // "incoming" layer so the dragged-in page is visible while the
        // gesture is in flight; on commit the routes update and the
        // tentative slot clears; on abort the tentative slot clears and the
        // user is back where they started.
        final RouteState incomingForRender;
        final RouteState outgoingForRender;
        if (_tentativeTarget != null) {
          incomingForRender = _tentativeTarget!;
          outgoingForRender = routeState;
        } else {
          incomingForRender = routeState;
          outgoingForRender = _previousRouteForTransition;
        }

        // The top two slots are the active transition pair. Most effects
        // animate the incoming layer on top (CupertinoEffect, FadeEffect,
        // SlideUp, …), but page-turn effects let the OUTGOING page do the
        // visible motion — it needs to be the top layer so the user sees
        // it peel off. `AnimationEffect.previousOnTop` flips which route
        // occupies slot 0 vs slot 1.
        final RouteState topSlot;
        final RouteState bottomSlot;
        if (_nextAnimationEffect.previousOnTop) {
          topSlot = outgoingForRender;
          bottomSlot = incomingForRender;
        } else {
          topSlot = incomingForRender;
          bottomSlot = outgoingForRender;
        }

        // Beyond the active pair, paint every other route that's currently
        // in the visible stack (`routes.take(index + 1)`). Without this,
        // cold-booting to `/home+/sheet+/dialog` would only paint the top
        // pair (dialog + sheet) and leave home invisible — the layerEffects
        // array still only has 2 entries (from the active effect), so the
        // deeper routes render with the default identity transform and
        // appear as static layers beneath the transition.
        final indices = <int>[
          indexMap[topSlot] ?? -1,
          indexMap[bottomSlot] ?? -1,
        ];
        final state = _pNavigationState.getValue();
        for (var i = state.index; i >= 0; i--) {
          final r = state.routes[i];
          if (r != topSlot && r != bottomSlot) {
            final idx = indexMap[r];
            if (idx != null) indices.add(idx);
          }
        }

        return PrioritizedIndexedStack(
          indices: indices,
          layerEffects: layerEffects,
          children: children,
        );
      },
    );
  }

  // ─── Tentative navigation ─────────────────────────────────────────────────
  //
  // Driving the route animation directly from a user gesture (drag, swipe,
  // edge-pull). The flow:
  //   1. `beginTentativeNavigation(target, effect: ...)` — wires the target
  //      route into the cache, configures the animation effect, and parks
  //      the animation controller at value=0 without forwarding.
  //   2. `updateTentativeProgress(value)` — called repeatedly from the
  //      gesture handler. Maps drag distance → controller value [0..1].
  //   3. `commitTentative()` — at release-past-threshold; mutates
  //      `pNavigationState` to make the target the new current route,
  //      flushes the browser URL, and forwards the animation from the
  //      current value to 1. The visual transition is continuous with the
  //      drag — no snap.
  //   4. `abortTentative()` — at release-below-threshold; reverses the
  //      animation back to 0, awaits it, then clears the tentative slot
  //      and (if the target wasn't already in the stack) drops it from
  //      the cache.

  /// Start a tentative navigation toward [target] using [effect] as the
  /// transition animation. The controller's animation parks at value=0
  /// and waits for `updateTentativeProgress` calls to drive it forward.
  ///
  /// Calling this while another tentative is active aborts the previous
  /// one synchronously (without animation) so the gesture can take over.
  /// Returns `true` if the tentative was successfully started, `false` if
  /// [target] is unregistered or fails a guard condition.
  bool beginTentativeNavigation(
    RouteState target, {
    required AnimationEffect effect,
  }) {
    if (target == currentRouteState) return false;
    if (_getBuilderByPath(target.uri) == null) return false;
    if (!(target.condition?.call() ?? true)) return false;
    final builder = _getBuilderByPath(target.uri);
    if (!(builder?.condition?.call() ?? true)) return false;

    // Take over from any prior tentative without animating.
    _tentativeTarget = target;
    _nextAnimationEffect = effect;

    addToCache([target]);

    _globalKey.currentState
      ?..setEffects([effect])
      ..setControllerValues(0.0);
    return true;
  }

  /// Set the tentative animation's progress (clamped to `[0, 1]`). Called
  /// from a gesture handler; ignored if no tentative is active.
  void updateTentativeProgress(double value) {
    if (!isTentativeActive) return;
    _globalKey.currentState?.setControllerValues(value.clamp(0.0, 1.0));
  }

  /// Commit the tentative as a real navigation: mutate `pNavigationState`,
  /// flush the URL, and forward the animation from the current value to 1.
  /// Safe no-op if no tentative is active.
  void commitTentative() {
    if (!isTentativeActive) return;
    final target = _tentativeTarget!;
    _tentativeTarget = null;

    final state = _pNavigationState.getValue();
    final indexInHistory = state.routes.indexWhere(
      (r) => _urisMatch(r.uri, target.uri),
    );

    _previousRouteForTransition = currentRouteState;

    if (indexInHistory != -1) {
      _pNavigationState.set(
        _NavigationState(routes: state.routes, index: indexInHistory),
      );
    } else {
      final newRoutes = state.routes.sublist(0, state.index + 1)..add(target);
      _clearStaleRoutesFromCache(
        newRouteTimeline: newRoutes,
        existingCacheKeys: _widgetCache.keys.toList(),
      );
      addToCache([target]);
      _pNavigationState.set(
        _NavigationState(routes: newRoutes, index: newRoutes.length - 1),
      );
    }

    _maybePushBrowserState(target.uri);
    // Continue the animation from wherever the gesture left it — no
    // restart() here, that would snap value back to 0 first.
    _globalKey.currentState?.forward();
  }

  /// Abort the tentative navigation: reverse the animation back to 0,
  /// wait for it to settle, then drop the tentative target. The committed
  /// `pNavigationState` is unchanged — the user ends up where they started.
  Future<void> abortTentative() async {
    if (!isTentativeActive) return;
    final target = _tentativeTarget!;
    final keyState = _globalKey.currentState;
    if (keyState != null) {
      await keyState.reverseAndAwait();
    }
    // Tentative may have been replaced/cleared by another call during the
    // reverse; only clear if it still points at our target.
    if (_tentativeTarget == target) {
      _tentativeTarget = null;
    }
    // If the target was added to cache solely to support the tentative
    // (i.e. it isn't part of the live navigation timeline), let stale-
    // route cleanup reclaim it.
    final state = _pNavigationState.getValue();
    final inTimeline = state.routes.any((r) => _urisMatch(r.uri, target.uri));
    if (!inTimeline) {
      _maybeRemoveStaleRoute(target);
    }
  }

  static RouteController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }

  void dispose() {
    platformNavigator.removeStateCallback(_handlePopState);
    _pNavigationState.dispose();
    _widgetCache.clear();
    _invalidateCachedViews();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _NavigationState {
  final List<RouteState> routes;
  final int index;

  const _NavigationState({required this.routes, required this.index});
}

typedef _TPreservationStrategy = bool Function(RouteBuilder routeBuider);
