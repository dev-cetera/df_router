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

  late RouteState _prevRouteState = _pRouteState.value;
  final RouteState Function()? errorRouteState;
  final RouteState Function() fallbackRouteState;
  RouteState? _requestedRouteState;

  AnimationEffect nextEffect = NoEffect();

  //
  //
  //

  RouteController({
    RouteState Function()? initialRouteState,
    this.errorRouteState,
    required this.fallbackRouteState,
    required this.builders,
  }) {
    platformNavigator.addStateCallback(pushUri);
    // Set all the builder output to SizedBox.shrink.
    resetState();
    _requestedRouteState = getNavigatorRouteState();
    final routeState = initialRouteState?.call() ?? _requestedRouteState ?? fallbackRouteState();
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
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
      _pRouteState.notifyListeners();
    }
  }

  //
  //
  //

  void clearCache() {
    for (final builder in builders) {
      _widgetCache[builder.routeState] = SizedBox.shrink(key: builder.routeState.key);
    }
  }

  //
  //
  //

  void resetState() {
    clearCache();
    final routeStates = builders
        .where((builder) => builder.shouldPrebuild)
        .map((e) => e.routeState);
    addStatesToCache(routeStates);
  }

  //
  //
  //

  void _maybeRemoveStaleRoute(RouteState routeState) {
    final builder = _getBuilderByPath(routeState.uri);
    if (builder == null) return;
    if (!builder.shouldPreserve) {
      _widgetCache[routeState] = SizedBox.shrink(key: routeState.key);
    }
  }

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
    AnimationEffect? animationEffect,
  }) {
    nextEffect = animationEffect ?? routeState.animationEffect ?? NoEffect();
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

    // Remove the previous route state from the cache if it is stale.

    _pRouteState.value = routeState;
    addStatesToCache([routeState]);

    globalKey.currentState?.setControllerValues(0.0);
    globalKey.currentState?.forward();
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

  final globalKey = GlobalKey<AnimationEffectBuilderState>();

  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: globalKey,
      effects: [nextEffect],
      onComplete: () {
        _maybeRemoveStaleRoute(_prevRouteState);
      },
      builder: (context, results) {
        final layerEffects = results.map((e) => e.data).toList()[0];

        return PrioritizedIndexedStack(
          indices: [
            _widgetCache.keys.toList().indexOf(routeState),
            _widgetCache.keys.toList().indexOf(_prevRouteState),
          ],
          layerEffects: layerEffects,
          children: _widgetCache.values.toList(),
        );
      },
    );
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
      throw FlutterError('No RouteStateControllerProvider found in context');
    }
    return provider.controller;
  }
}

// Assuming AnimationEffect and AnimationLayerEffect are defined as in the provided code
abstract class AnimationEffect {
  final Duration duration;
  final Curve curve;
  final List<AnimationLayerEffect> Function(BuildContext context, double value) data;

  const AnimationEffect({required this.duration, required this.curve, required this.data});
}

class LayerEffectResult {
  final List<AnimationLayerEffect> data;
  final double value;

  LayerEffectResult({required this.data, required this.value});
}

class AnimationEffectBuilder extends StatefulWidget {
  final List<AnimationEffect> effects;
  final Widget Function(BuildContext context, List<LayerEffectResult> results) builder;
  final VoidCallback? onComplete;

  const AnimationEffectBuilder({
    super.key,
    required this.effects,
    required this.builder,
    this.onComplete,
  });

  @override
  State<AnimationEffectBuilder> createState() => AnimationEffectBuilderState();
}

class AnimationEffectBuilderState extends State<AnimationEffectBuilder>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> animations;
  bool _hasTriggeredCompletion = false; // Track if callback has been triggered

  void setControllerValues(double value) {
    for (final controller in controllers) {
      controller.value = value;
    }
    _hasTriggeredCompletion = false; // Reset completion state
  }

  void forwardControllers() {
    for (final controller in controllers) {
      controller.forward();
    }
    _hasTriggeredCompletion = false; // Reset completion state
  }

  void reverseControllers() {
    for (final controller in controllers) {
      controller.reverse();
    }
    _hasTriggeredCompletion = false; // Reset completion state
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    controllers =
        widget.effects.map((config) {
          final controller = AnimationController(
            vsync: this,
            duration: config.duration,
            value: 1.0,
          );
          // Add status listener to track completion
          controller.addStatusListener(_handleAnimationStatus);
          return controller;
        }).toList();
    animations =
        widget.effects.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          return CurvedAnimation(parent: controllers[index], curve: config.curve);
        }).toList();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    // Check if all controllers are completed
    if (status == AnimationStatus.completed && !_hasTriggeredCompletion) {
      final allCompleted = controllers.every(
        (controller) => controller.status == AnimationStatus.completed,
      );
      if (allCompleted) {
        widget.onComplete?.call();
        _hasTriggeredCompletion = true; // Prevent multiple triggers
      }
    }
  }

  @override
  void didUpdateWidget(AnimationEffectBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effects.length != oldWidget.effects.length) {
      for (var controller in controllers) {
        controller.removeStatusListener(_handleAnimationStatus);
        controller.dispose();
      }
      _initializeAnimations();
    } else {
      for (var i = 0; i < widget.effects.length; i++) {
        if (widget.effects[i].duration != oldWidget.effects[i].duration) {
          controllers[i].duration = widget.effects[i].duration;
        }
        if (widget.effects[i].curve != oldWidget.effects[i].curve) {
          animations[i] = CurvedAnimation(parent: controllers[i], curve: widget.effects[i].curve);
        }
      }
    }
    _hasTriggeredCompletion = false; // Reset completion state on widget update
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.removeStatusListener(_handleAnimationStatus);
      controller.dispose();
    }
    super.dispose();
  }

  void reset() {
    for (final controller in controllers) {
      controller.value = 0.0;
    }
    _hasTriggeredCompletion = false; // Reset completion state
  }

  void forward() {
    for (final controller in controllers) {
      controller.forward();
    }
    _hasTriggeredCompletion = false; // Reset completion state
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(animations),
      builder: (context, child) {
        final results =
            animations.asMap().entries.map((entry) {
              final index = entry.key;
              final animation = entry.value;
              final data = widget.effects[index].data(context, animation.value);
              final value = animation.value;
              return LayerEffectResult(data: data, value: value);
            }).toList();
        return widget.builder(context, results);
      },
    );
  }
}
