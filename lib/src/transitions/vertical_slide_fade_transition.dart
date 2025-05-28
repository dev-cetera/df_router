import 'transition_controller.dart';
import 'package:flutter/material.dart';

import 'transition_mixin.dart';

class VerticalSlideFadeTransition extends StatefulWidget with TransitionMixin {
  @override
  final Duration duration;
  @override
  final TransitionController controller;
  @override
  final Widget? prev;
  @override
  final Widget child;

  const VerticalSlideFadeTransition({
    super.key,
    this.duration = Durations.medium3,
    required this.controller,
    required this.prev,
    required this.child,
  });

  @override
  State<VerticalSlideFadeTransition> createState() =>
      _VerticalSlideFadeTransitionState();
}

class _VerticalSlideFadeTransitionState
    extends State<VerticalSlideFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slide;
  late Animation<Offset> _prevSlide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );

    _slide =
        Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: const Offset(0.0, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _prevSlide =
        Tween<Offset>(
          begin: const Offset(0.0, 0.0),
          end: const Offset(0.0, -0.33),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _fade = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // ignore: invalid_use_of_protected_member
    widget.controller.resetAnimation = () {
      _animationController.reset();
      _animationController.forward();
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.controller.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.prev != null)
          SlideTransition(
            position: _prevSlide,
            child: FadeTransition(opacity: _fade, child: widget.prev),
          ),
        SlideTransition(
          position: _slide,
          child: KeyedSubtree(key: const ValueKey(1), child: widget.child),
        ),
      ],
    );
  }
}
