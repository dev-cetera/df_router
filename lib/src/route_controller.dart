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

import 'dart:math' as math;
import 'dart:ui';

import 'package:df_pwa_utils/df_pwa_utils.dart';
import 'package:df_widgets/_common.dart';
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

  late RouteState _prevRouteState = _pRouteState.value;
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
  }) {
    _requestedRouteState = getNavigatorRouteState();
    final routeState = initialRouteState?.call() ?? _requestedRouteState ?? fallbackRouteState();
    for (final builder in builders) {
      _widgetCache[builder.routeState] = SizedBox.shrink(key: builder.routeState.key);
    }
    platformNavigator.addStateCallback(pushUri);
    push(routeState, shouldAnimate: false);
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
    bool shouldAnimate = true,
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

    globalKey.currentState?.setControllerValues(shouldAnimate ? 0.0 : 1.0);
    globalKey.currentState?.forward();

    //controller.startAnimation();
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

  final globalKey = GlobalKey<AnimationEffectBuilderState>();

  Widget buildScreen(BuildContext context, RouteState routeState) {
    return AnimationEffectBuilder(
      key: globalKey,
      effects: [FadeEffect()],
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

  const AnimationEffectBuilder({super.key, required this.effects, required this.builder});

  @override
  AnimationEffectBuilderState createState() => AnimationEffectBuilderState();
}

class AnimationEffectBuilderState extends State<AnimationEffectBuilder>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> animations;

  void setControllerValues(double value) {
    for (final controller in controllers) {
      controller.value = value;
    }
  }

  void forwardControllers() {
    for (final controller in controllers) {
      controller.forward();
    }
  }

  void reverseControllers() {
    for (final controller in controllers) {
      controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    controllers =
        widget.effects.map((config) {
          return AnimationController(vsync: this, duration: config.duration, value: 1.0);
        }).toList();
    animations =
        widget.effects.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          return CurvedAnimation(parent: controllers[index], curve: config.curve);
        }).toList();
  }

  @override
  void didUpdateWidget(AnimationEffectBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effects.length != oldWidget.effects.length) {
      for (var controller in controllers) {
        controller.dispose();
      }
      _initializeAnimations();
    } else {
      for (int i = 0; i < widget.effects.length; i++) {
        if (widget.effects[i].duration != oldWidget.effects[i].duration) {
          controllers[i].duration = widget.effects[i].duration;
        }
        if (widget.effects[i].curve != oldWidget.effects[i].curve) {
          animations[i] = CurvedAnimation(parent: controllers[i], curve: widget.effects[i].curve);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void reset() {
    for (final controller in controllers) {
      controller.value = 0.0;
    }
  }

  void forward() {
    for (final controller in controllers) {
      controller.forward();
    }
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
