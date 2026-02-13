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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Owns the AnimationControllers that drive route transitions. Reuses
// controllers across navigations (setEffects) rather than disposing and
// recreating them, avoiding the overhead of ticker registration and
// listener setup on every route change.
class AnimationEffectBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, List<LayerEffectResult> results)
      builder;
  // Called when ALL animation controllers complete. The RouteController uses
  // this to dispose the previous screen's widget only after the transition
  // finishes, preventing a visual flash.
  final VoidCallback? onComplete;

  const AnimationEffectBuilder({
    super.key,
    required this.builder,
    this.onComplete,
  });

  @override
  State<AnimationEffectBuilder> createState() => AnimationEffectBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class AnimationEffectBuilderState extends State<AnimationEffectBuilder>
    with TickerProviderStateMixin {
  List<_AnimationBundle> _bundles = [];
  bool _hasTriggeredCompletion = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations([const NoEffect()]);
  }

  void _initializeAnimations(List<AnimationEffect> effects) {
    if (_bundles.length == effects.length) {
      // Reuse existing controllers — just update duration and curve.
      // This avoids the overhead of disposing and recreating controllers,
      // tickers, and status listeners on every navigation.
      for (var i = 0; i < effects.length; i++) {
        final config = effects[i];
        final controller = _bundles[i].controller;
        controller.duration = config.duration;
        controller.value = 1.0;
        _bundles[i] = _AnimationBundle(
          effect: config,
          controller: controller,
          animation: CurvedAnimation(parent: controller, curve: config.curve),
        );
      }
    } else {
      _disposeBundles();
      _bundles = effects.map((config) {
        final controller = AnimationController(
          vsync: this,
          duration: config.duration,
          value: 1.0,
        );
        controller.addStatusListener(_handleAnimationStatus);
        final animation = CurvedAnimation(
          parent: controller,
          curve: config.curve,
        );
        return _AnimationBundle(
          effect: config,
          controller: controller,
          animation: animation,
        );
      }).toList();
    }
    _hasTriggeredCompletion = false;
  }

  void setEffects(List<AnimationEffect> effects) {
    if (!mounted) return;
    _initializeAnimations(effects);
  }

  void setControllerValues(double value) {
    if (!mounted || _bundles.isEmpty) return;
    for (final bundle in _bundles) {
      bundle.controller.value = value;
    }
    _hasTriggeredCompletion = false;
  }

  void forward() {
    if (!mounted || _bundles.isEmpty) return;
    for (final bundle in _bundles) {
      bundle.controller.forward();
    }
    _hasTriggeredCompletion = false;
  }

  void restart() {
    setControllerValues(0.0);
    forward();
  }

  void reverse() {
    if (!mounted || _bundles.isEmpty) return;
    for (final bundle in _bundles) {
      bundle.controller.reverse();
    }
    _hasTriggeredCompletion = false;
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasTriggeredCompletion) {
      final allCompleted = _bundles.every(
        (bundle) => bundle.controller.status == AnimationStatus.completed,
      );
      if (allCompleted) {
        widget.onComplete?.call();
        _hasTriggeredCompletion = true;
      }
    }
  }

  void _disposeBundles() {
    for (final bundle in _bundles) {
      bundle.controller.removeStatusListener(_handleAnimationStatus);
      bundle.controller.dispose();
    }
    _bundles = [];
  }

  @override
  void dispose() {
    _disposeBundles();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final animationsToMerge =
        _bundles.map((bundle) => bundle.animation).toList();

    return AnimatedBuilder(
      animation: Listenable.merge(animationsToMerge),
      builder: (context, child) {
        final results = _bundles.map((bundle) {
          final data = bundle.effect.data(
            context,
            size,
            bundle.animation.value,
          );
          final value = bundle.animation.value;
          return LayerEffectResult(data: data, value: value);
        }).toList();
        return widget.builder(context, results);
      },
    );
  }
}

class _AnimationBundle {
  final AnimationEffect effect;
  final AnimationController controller;
  final Animation<double> animation;

  _AnimationBundle({
    required this.effect,
    required this.controller,
    required this.animation,
  });
}
