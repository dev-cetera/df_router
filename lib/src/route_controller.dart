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

import 'package:df_log/df_log.dart';
import 'package:flutter/widgets.dart';

import 'package:df_pod/df_pod.dart';
import 'package:df_pwa_utils/df_pwa_utils.dart';

import '_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteController {
  //
  //
  //

  final _pRouteState = Pod(RouteState.parse('/'));
  GenericPod<RouteState> get pRouteState => _pRouteState;
  RouteState get routeState => _pRouteState.value;

  final _widgetCache = <RouteState, Widget>{};

  /// Internal map for O(1) lookup of RouteBuilders by their path string.
  /// This is now the single source of truth for builder definitions after construction.
  late final Map<String, RouteBuilder> _builderMap;

  late RouteState _prevRouteState = _pRouteState.value;
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;

  RouteState? _requested;
  RouteState? get requested => _requested;

  AnimationEffect _nextEffect = const NoEffect();

  //
  //
  //

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required List<RouteBuilder> builders, // Changed: parameter name, not assigned to a field
  }) {
    // Initialize the _builderMap from the `builders` parameter
    _builderMap = {for (var builder in builders) builder.routeState.path: builder};

    platformNavigator.addStateCallback(pushUri);
    // Set all the builder output to SizedBox.shrink.
    resetState();
    _requested = current;
    final routeState = initialRouteState?.call() ?? _requested ?? fallbackRouteState();
    push(routeState);
  }

  //
  //
  //

  RouteState getNavigatorOrFallbackRouteState() => _requested ?? fallbackRouteState();

  //
  //
  //

  RouteState? get current {
    final url = platformNavigator.getCurrentUrl();
    if (url == null) {
      return null;
    }
    // Uses the optimized _getBuilderByPath
    return _getBuilderByPath(url)?.routeState.copyWith(queryParameters: url.queryParameters);
  }

  //
  //
  //

  void addToCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      // Uses the optimized _getBuilderByPath
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

  void removeFromCache(Iterable<RouteState> routeStates) {
    for (final routeState in routeStates) {
      // Uses the optimized _getBuilderByPath
      final builder = _getBuilderByPath(routeState.uri);
      if (builder == null) continue;
      if (_widgetCache[routeState] is SizedBox) continue;
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
      _pRouteState.notifyListeners();
    }
  }

  //
  //
  //

  void clearCache() {
    // Now iterates over _builderMap.values. Order might differ from original list,
    // but for clearing cache, order of individual items usually doesn't matter.
    for (final builder in _builderMap.values) {
      _widgetCache[builder.routeState] = SizedBox.shrink(key: builder.routeState.key);
    }
  }

  //
  //
  //

  void resetState() {
    clearCache();
    // Now iterates over _builderMap.values.
    final routeStates = _builderMap.values
        .where((builder) => builder.shouldPrebuild)
        .map((e) => e.routeState);
    addToCache(routeStates);
  }

  //
  //
  //

  void _maybeRemoveStaleRoute(RouteState routeState) {
    // Uses the optimized _getBuilderByPath
    final builder = _getBuilderByPath(routeState.uri);
    if (builder == null) return;
    if (!builder.shouldPreserve) {
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
    }
  }

  //
  //
  //

  void pushUri(Uri uri, {AnimationEffect? animationEffect}) {
    push(RouteState(uri), animationEffect: animationEffect);
  }

  //
  //
  //

  void pushBack1({
    RouteState? fallback,
    AnimationEffect? animationEffect = const QuickBackwardEffect(),
  }) {
    pushBack(fallback: fallback, animationEffect: animationEffect);
  }

  //
  //
  //

  void pushBack({RouteState? fallback, AnimationEffect? animationEffect = const NoEffect()}) {
    if (_prevRouteState.path == '/') {
      push(fallback ?? fallbackRouteState(), animationEffect: animationEffect);
    } else {
      push(_prevRouteState, animationEffect: animationEffect);
    }
  }

  //
  //
  //

  void push1<TExtra extends Object?>(
    RouteState<TExtra> routeState, {
    RouteState? errorFallback,
    RouteState? fallback,
    AnimationEffect? animationEffect = const QuickForwardEffect(),
  }) {
    push<TExtra>(
      routeState,
      errorFallback: errorFallback,
      fallback: fallback,
      animationEffect: animationEffect,
    );
  }

  //
  //
  //

  void push<TExtra extends Object?>(
    RouteState<TExtra> routeState, {
    RouteState? errorFallback,
    RouteState? fallback,
    AnimationEffect? animationEffect,
  }) {
    _nextEffect = animationEffect ?? routeState.animationEffect;
    final uri = routeState.uri;
    final skipCurrent = routeState.skipCurrent;
    if (skipCurrent && _pRouteState.value.uri == uri) {
      return;
    }

    // Uses the optimized _checkExtraTypeMismatch
    if (_checkExtraTypeMismatch<TExtra>(uri) == false) {
      Log.err('Expected extra type $TExtra for route: $uri!');
      final errorFallback1 = errorFallback ?? errorRouteState?.call();
      if (errorFallback1 != null) {
        push(errorFallback1);
      }
      return;
    }

    // Uses the optimized pathExists
    if (!pathExists(uri)) {
      Log.err('The path $uri does not exist!');
      final errorFallback1 = errorFallback ?? errorRouteState?.call();
      if (errorFallback1 != null) {
        push(errorFallback1);
      }
      return;
    }

    final condition = routeState.condition;
    final a = condition == null || condition();
    if (!a) {
      Log.err('Route condition not met for $uri!');
      push(fallback ?? fallbackRouteState());
      return;
    }

    // Uses the optimized _getBuilderByPath
    final condition2 = _getBuilderByPath(uri)?.condition;
    final b = condition2 == null || condition2.call();
    if (!b) {
      Log.err('Builder condition not met for $uri!');
      push(fallback ?? fallbackRouteState());
      return;
    }

    platformNavigator.pushState(uri);
    _prevRouteState = _pRouteState.value;
    _pRouteState.set(routeState, notifyImmediately: true);
    addToCache([routeState]);
    _globalKey.currentState?.setEffects([_nextEffect]);
    _globalKey.currentState?.restart();
  }

  //
  // OPTIMIZED: Now O(1)
  //
  bool pathExists(Uri path) {
    return _builderMap.containsKey(path.path);
  }

  //
  // OPTIMIZED: Now O(1) for the map lookup part.
  //
  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    final builder = _builderMap[path.path];
    // The `is` check works correctly with generics if TExtra is known at compile time
    // where this method is called. This replicates the original logic.
    return builder != null && builder is RouteBuilder<TExtra>;
  }

  //
  // OPTIMIZED: Now O(1)
  //
  RouteBuilder? _getBuilderByPath(Uri path) {
    return _builderMap[path.path];
  }

  //
  //
  //

  final _globalKey = GlobalKey<AnimationEffectBuilderState>();

  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: _globalKey,
      onComplete: () {
        _maybeRemoveStaleRoute(_prevRouteState);
      },
      builder: (context, results) {
        final layerEffects = results.map((e) => e.data).toList()[0];
        return PrioritizedIndexedStack(
          indices: [_indexOfRouteState(routeState), _indexOfRouteState(_prevRouteState)],
          layerEffects: layerEffects,
          children: _widgetCache.values.toList(),
        );
      },
    );
  }

  //
  //
  //

  int _indexOfRouteState(RouteState routeState) {
    var n = -1;
    for (final key in _widgetCache.keys) {
      n++;
      if (key == routeState) {
        break;
      }
    }
    return n;
  }

  //
  //
  //

  void dispose() {
    platformNavigator.removeStateCallback(pushUri);
    _pRouteState.dispose();
    _widgetCache.clear();
  }

  //
  //
  //

  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw Log.err('No RouteStateControllerProvider found in context');
    }
    return provider.controller;
  }
}

// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// // source code is governed by an MIT-style license described in the LICENSE
// // file located in this project's root directory.
// //
// // See: https://opensource.org/license/mit
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import 'package:df_log/df_log.dart';
// import 'package:flutter/widgets.dart';

// import 'package:df_pod/df_pod.dart';
// import 'package:df_pwa_utils/df_pwa_utils.dart';

// import '_src.g.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class RouteController {
//   //
//   //
//   //

//   final _pRouteState = Pod(RouteState.parse('/'));
//   GenericPod<RouteState> get pRouteState => _pRouteState;
//   RouteState get routeState => _pRouteState.value;

//   final _widgetCache = <RouteState, Widget>{};

//   late final List<RouteBuilder> builders;

//   late RouteState _prevRouteState = _pRouteState.value;
//   final RouteState Function()? errorRouteState;
//   final RouteState Function() fallbackRouteState;

//   RouteState? _requested;
//   RouteState? get requested => _requested;

//   AnimationEffect _nextEffect = const NoEffect();

//   //
//   //
//   //

//   RouteController({
//     RouteState Function()? initialRouteState,
//     this.errorRouteState,
//     required this.fallbackRouteState,
//     required this.builders,
//   }) {
//     platformNavigator.addStateCallback(pushUri);
//     // Set all the builder output to SizedBox.shrink.
//     resetState();
//     _requested = current;
//     final routeState = initialRouteState?.call() ?? _requested ?? fallbackRouteState();
//     push(routeState);
//   }

//   //
//   //
//   //

//   RouteState getNavigatorOrFallbackRouteState() => _requested ?? fallbackRouteState();

//   //
//   //
//   //

//   RouteState? get current {
//     final url = platformNavigator.getCurrentUrl();
//     if (url == null) {
//       return null;
//     }
//     return _getBuilderByPath(url)?.routeState.copyWith(queryParameters: url.queryParameters);
//   }

//   //
//   //
//   //

//   void addToCache(Iterable<RouteState> routeStates) {
//     for (final routeState in routeStates) {
//       final builder = _getBuilderByPath(routeState.uri);
//       if (builder == null) continue;
//       if (_widgetCache[routeState] is Builder) continue;
//       _widgetCache[routeState] = Builder(
//         key: routeState.key,
//         builder: (context) {
//           return builder.builder(context, routeState);
//         },
//       );

//       _pRouteState.notifyListeners();
//     }
//   }

//   //
//   //
//   //

//   void removeFromCache(Iterable<RouteState> routeStates) {
//     for (final routeState in routeStates) {
//       final builder = _getBuilderByPath(routeState.uri);
//       if (builder == null) continue;
//       if (_widgetCache[routeState] is SizedBox) continue;
//       _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
//       _pRouteState.notifyListeners();
//     }
//   }

//   //
//   //
//   //

//   void clearCache() {
//     for (final builder in builders) {
//       _widgetCache[builder.routeState] = SizedBox.shrink(key: builder.routeState.key);
//     }
//   }

//   //
//   //
//   //

//   void resetState() {
//     clearCache();
//     final routeStates = builders
//         .where((builder) => builder.shouldPrebuild)
//         .map((e) => e.routeState);
//     addToCache(routeStates);
//   }

//   //
//   //
//   //

//   void _maybeRemoveStaleRoute(RouteState routeState) {
//     final builder = _getBuilderByPath(routeState.uri);
//     if (builder == null) return;
//     if (!builder.shouldPreserve) {
//       _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
//     }
//   }

//   //
//   //
//   //

//   void pushUri(Uri uri, {AnimationEffect? animationEffect}) {
//     push(RouteState(uri), animationEffect: animationEffect);
//   }

//   //
//   //
//   //

//   void pushBack1({
//     RouteState? fallback,
//     AnimationEffect? animationEffect = const QuickBackwardEffect(),
//   }) {
//     pushBack(fallback: fallback, animationEffect: animationEffect);
//   }

//   //
//   //
//   //

//   void pushBack({RouteState? fallback, AnimationEffect? animationEffect = const NoEffect()}) {
//     if (_prevRouteState.path == '/') {
//       push(fallback ?? fallbackRouteState(), animationEffect: animationEffect);
//     } else {
//       push(_prevRouteState, animationEffect: animationEffect);
//     }
//   }

//   //
//   //
//   //

//   void push1<TExtra extends Object?>(
//     RouteState<TExtra> routeState, {
//     RouteState? errorFallback,
//     RouteState? fallback,
//     AnimationEffect? animationEffect = const QuickForwardEffect(),
//   }) {
//     push<TExtra>(
//       routeState,
//       errorFallback: errorFallback,
//       fallback: fallback,
//       animationEffect: animationEffect,
//     );
//   }

//   //
//   //
//   //

//   void push<TExtra extends Object?>(
//     RouteState<TExtra> routeState, {
//     RouteState? errorFallback,
//     RouteState? fallback,
//     AnimationEffect? animationEffect,
//   }) {
//     _nextEffect = animationEffect ?? routeState.animationEffect;
//     final uri = routeState.uri;
//     final skipCurrent = routeState.skipCurrent;
//     if (skipCurrent && _pRouteState.value.uri == uri) {
//       return;
//     }
//     if (_checkExtraTypeMismatch<TExtra>(uri) == false) {
//       Log.err('Expected extra type $TExtra for route: $uri!');
//       final errorFallback1 = errorFallback ?? errorRouteState?.call();
//       if (errorFallback1 != null) {
//         push(errorFallback1);
//       }
//       return;
//     }
//     if (!pathExists(uri)) {
//       Log.err('The path $uri does not exist!');
//       final errorFallback1 = errorFallback ?? errorRouteState?.call();
//       if (errorFallback1 != null) {
//         push(errorFallback1);
//       }
//       return;
//     }
//     final condition = routeState.condition;
//     final a = condition == null || condition();
//     if (!a) {
//       Log.err('Route condition not met for $uri!');
//       push(fallback ?? fallbackRouteState());
//       return;
//     }
//     final condition2 = _getBuilderByPath(uri)?.condition;
//     final b = condition2 == null || condition2.call();
//     if (!b) {
//       Log.err('Builder condition not met for $uri!');
//       push(fallback ?? fallbackRouteState());
//       return;
//     }
//     platformNavigator.pushState(uri);
//     _prevRouteState = _pRouteState.value;
//     _pRouteState.set(routeState, notifyImmediately: true);
//     addToCache([routeState]);
//     _globalKey.currentState?.setEffects([_nextEffect]);
//     _globalKey.currentState?.restart();
//   }

//   //
//   //
//   //

//   bool pathExists(Uri path) {
//     return builders.any((e) => e.routeState.path == path.path);
//   }

//   //
//   //
//   //

//   bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
//     return builders.any((e) {
//       return e.routeState.path == path.path && e is RouteBuilder<TExtra>;
//     });
//   }

//   //
//   //
//   //

//   RouteBuilder? _getBuilderByPath(Uri path) {
//     return builders.where((routeState) => routeState.routeState.path == path.path).firstOrNull;
//   }

//   //
//   //
//   //

//   final _globalKey = GlobalKey<AnimationEffectBuilderState>();

//   Widget buildScreen(BuildContext context, RouteState routeState) {
//     return AnimationEffectBuilder(
//       key: _globalKey,
//       onComplete: () {
//         _maybeRemoveStaleRoute(_prevRouteState);
//       },
//       builder: (context, results) {
//         final layerEffects = results.map((e) => e.data).toList()[0];
//         return PrioritizedIndexedStack(
//           indices: [
//             _widgetCache.keys.toList().indexOf(routeState),
//             _widgetCache.keys.toList().indexOf(_prevRouteState),
//           ],
//           layerEffects: layerEffects,
//           children: _widgetCache.values.toList(),
//         );
//       },
//     );
//   }

//   //
//   //
//   //

//   void dispose() {
//     platformNavigator.removeStateCallback(pushUri);
//     _pRouteState.dispose();
//     _widgetCache.clear();
//   }

//   //
//   //
//   //

//   static RouteController of(BuildContext context) {
//     final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
//     if (provider == null) {
//       throw FlutterError('No RouteStateControllerProvider found in context');
//     }
//     return provider.controller;
//   }
// }
