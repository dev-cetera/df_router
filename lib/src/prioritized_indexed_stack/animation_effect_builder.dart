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
  // The Listenable that AnimatedBuilder subscribes to. Built once per
  // `_initializeAnimations` call instead of allocating a new merged Listenable
  // on every build (which fires 60–120 times per second during transitions).
  Listenable _mergedAnimations = const _NoopListenable();

  void _rebuildMergedAnimations() {
    if (_bundles.length == 1) {
      // Avoid the overhead of Listenable.merge when there is only one
      // animation, which is the common case for route transitions.
      _mergedAnimations = _bundles.first.animation;
    } else if (_bundles.isEmpty) {
      _mergedAnimations = const _NoopListenable();
    } else {
      _mergedAnimations = Listenable.merge([
        for (final b in _bundles) b.animation,
      ]);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations([const NoEffect()]);
  }

  void _initializeAnimations(List<AnimationEffect> effects) {
    // Setting `controller.value = 1.0` on a controller that is already at 1.0
    // still fires a `completed` status notification (Flutter quirk). Without
    // this guard, the spurious notification would fire `onComplete` at the
    // start of every transition, which in turn would remove the outgoing
    // route from the cache BEFORE the animation begins. The flag is reset to
    // false at the bottom of this method so a real completion still fires.
    _hasTriggeredCompletion = true;
    final reusing = _bundles.length == effects.length;
    if (reusing) {
      // Reuse existing controllers AND CurvedAnimations — mutate config in
      // place. `CurvedAnimation.curve` is a mutable field, so we can update
      // the curve without allocating a new CurvedAnimation. Allocating a new
      // one would leak: its constructor calls `parent.addStatusListener`,
      // and that listener back-references the old CurvedAnimation, so the
      // old instance stays pinned alive by the controller's listener list
      // for the controller's lifetime (one extra entry per navigation).
      for (var i = 0; i < effects.length; i++) {
        final config = effects[i];
        final bundle = _bundles[i];
        bundle.controller.duration = config.duration;
        bundle.controller.value = 1.0;
        bundle.animation.curve = config.curve;
        bundle.effect = config;
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
    // Reusing keeps the same bundle instances, so the merged listenable still
    // points at the right animations — skip the rebuild. Rebuilding would
    // allocate a fresh `Listenable.merge(...)` for the length-2+ case and
    // force AnimatedBuilder to unsubscribe and resubscribe.
    if (!reusing) {
      _rebuildMergedAnimations();
    }
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
      // Dispose the CurvedAnimation before its parent controller so it
      // deregisters its own status listener while the parent is still alive
      // (child-before-parent lifecycle). The controller's `dispose()` would
      // clear listeners anyway, but explicit disposal also flips the
      // CurvedAnimation's `isDisposed` flag, which Flutter's debug tooling
      // tracks via `debugMaybeDispatchDisposed`.
      bundle.animation.dispose();
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
    return AnimatedBuilder(
      animation: _mergedAnimations,
      builder: (context, child) {
        final results = <LayerEffectResult>[
          for (final bundle in _bundles)
            LayerEffectResult(
              data: bundle.effect.data(context, size, bundle.animation.value),
              value: bundle.animation.value,
            ),
        ];
        return widget.builder(context, results);
      },
    );
  }
}

// Pure stand-in for an empty bundle list. AnimatedBuilder requires a non-null
// Listenable, and creating an empty `Listenable.merge([])` would still allocate
// a new object on every rebuild.
class _NoopListenable extends Listenable {
  const _NoopListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _AnimationBundle {
  // Mutable so `_initializeAnimations` can update the effect in place when
  // reusing a bundle (same length list of effects) without reallocating.
  AnimationEffect effect;
  final AnimationController controller;
  // Typed as `CurvedAnimation` (not `Animation<double>`) so callers can mutate
  // `.curve` and call `.dispose()` without a downcast.
  final CurvedAnimation animation;

  _AnimationBundle({
    required this.effect,
    required this.controller,
    required this.animation,
  });
}
