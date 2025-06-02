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

import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class AnimationEffectBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, List<LayerEffectResult> results)
  builder;
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
    final animationsToMerge = _bundles
        .map((bundle) => bundle.animation)
        .toList();

    return AnimatedBuilder(
      animation: Listenable.merge(animationsToMerge),
      builder: (context, child) {
        final results = _bundles.map((bundle) {
          final data = bundle.effect.data(context, bundle.animation.value);
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

// class AnimationEffectBuilder extends StatefulWidget {
//   final Widget Function(BuildContext context, List<LayerEffectResult> results) builder;
//   final VoidCallback? onComplete;

//   const AnimationEffectBuilder({super.key, required this.builder, this.onComplete});

//   @override
//   State<AnimationEffectBuilder> createState() => AnimationEffectBuilderState();
// }

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// class AnimationEffectBuilderState extends State<AnimationEffectBuilder>
//     with TickerProviderStateMixin {
//   var _controllers = <AnimationController>[];
//   var _animations = <Animation<double>>[];
//   var _effects = <AnimationEffect>[NoEffect()];

//   bool _hasTriggeredCompletion = false;

//   void setEffects(List<AnimationEffect> effects) {
//     if (!mounted || _controllers.isEmpty) return;
//     _effects = effects;
//     _initializeAnimations();
//   }

//   void setControllerValues(double value) {
//     if (!mounted || _controllers.isEmpty) return;
//     for (final controller in _controllers) {
//       controller.value = value;
//     }
//     _hasTriggeredCompletion = false;
//   }

//   void forward() {
//     if (!mounted || _controllers.isEmpty) return;
//     for (final controller in _controllers) {
//       controller.forward();
//     }
//     _hasTriggeredCompletion = false;
//   }

//   void restart() {
//     setControllerValues(0.0);
//     forward();
//   }

//   void reverse() {
//     if (!mounted || _controllers.isEmpty) return;
//     for (final controller in _controllers) {
//       controller.reverse();
//     }
//     _hasTriggeredCompletion = false;
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//   }

//   void _initializeAnimations() {
//     _disposeControllers();
//     _controllers =
//         _effects.map((config) {
//           final controller = AnimationController(
//             vsync: this,
//             duration: config.duration,
//             value: 1.0,
//           );
//           // Add status listener to track completion
//           controller.addStatusListener(_handleAnimationStatus);
//           return controller;
//         }).toList();
//     _animations =
//         _effects.asMap().entries.map((entry) {
//           final index = entry.key;
//           final config = entry.value;
//           return CurvedAnimation(parent: _controllers[index], curve: config.curve);
//         }).toList();
//   }

//   void _handleAnimationStatus(AnimationStatus status) {
//     if (status == AnimationStatus.completed && !_hasTriggeredCompletion) {
//       final allCompleted = _controllers.every(
//         (controller) => controller.status == AnimationStatus.completed,
//       );
//       if (allCompleted) {
//         widget.onComplete?.call();
//         _hasTriggeredCompletion = true;
//       }
//     }
//   }

//   void _disposeControllers() {
//     for (final controller in _controllers) {
//       controller.removeStatusListener(_handleAnimationStatus);
//       controller.dispose();
//     }
//   }

//   @override
//   void dispose() {
//     _disposeControllers();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: Listenable.merge(_animations),
//       builder: (context, child) {
//         final results =
//             _animations.asMap().entries.map((entry) {
//               final index = entry.key;
//               final animation = entry.value;
//               final data = _effects[index].data(context, animation.value);
//               final value = animation.value;
//               return LayerEffectResult(data: data, value: value);
//             }).toList();
//         return widget.builder(context, results);
//       },
//     );
//   }
// }
