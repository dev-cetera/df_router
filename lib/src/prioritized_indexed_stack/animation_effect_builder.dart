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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

  void _disposeControllers() {
    for (final controller in controllers) {
      controller.removeStatusListener(_handleAnimationStatus);
      controller.dispose();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disposeControllers();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _disposeControllers();
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
