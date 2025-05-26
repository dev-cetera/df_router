import 'package:flutter/material.dart';

import 'screen_transition_mixin.dart';

class ReanimateController {
  VoidCallback? _reanimate;

  void reanimate() {
    _reanimate?.call();
  }

  // Internal method to set the reanimate callback
  void _setReanimate(VoidCallback callback) {
    _reanimate = callback;
  }
}

class MaterialScreenTransition extends StatefulWidget with ScreenTransitionMixin {
  @override
  final Widget prev;
  @override
  final Widget current;
  @override
  final Duration duration;
  final ReanimateController? controller;

  const MaterialScreenTransition({
    super.key,
    required this.prev,
    required this.current,
    required this.duration,
    this.controller,
  });

  static Widget transition(
    Widget current, {
    Widget? prev,
    Duration duration = const Duration(milliseconds: 300),
    ReanimateController? controller,
  }) {
    if (prev == null) {
      return current;
    }
    return MaterialScreenTransition(
      prev: prev,
      current: current,
      duration: duration,
      controller: controller,
    );
  }

  @override
  State<MaterialScreenTransition> createState() => _MaterialScreenTransitionState();
}

class _MaterialScreenTransitionState extends State<MaterialScreenTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _currentSlide;
  late Animation<double> _prevSlide;
  late Animation<double> _prevOpacity;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    // Current widget slides from bottom (1.0) to center (0.0)
    _currentSlide = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Previous widget slides from center (0.0) to top (-0.33)
    _prevSlide = Tween<double>(
      begin: 0.0,
      end: -0.33,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Previous widget fades slightly
    _prevOpacity = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Mark completion and trigger rebuild when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCompleted = true;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isCompleted = false;
        });
      }
    });

    // Set up reanimate callback
    widget.controller?._setReanimate(() {
      if (_controller.status != AnimationStatus.forward) {
        _controller.forward(from: 0.0);
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // After completion, return only the current widget
    if (_isCompleted) {
      return widget.current;
    }

    // During transition, show the animated stack
    return Stack(
      children: [
        // Previous screen
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _prevSlide.value * MediaQuery.of(context).size.height),
              child: Opacity(opacity: _prevOpacity.value, child: widget.prev),
            );
          },
        ),
        // Current screen
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _currentSlide.value * MediaQuery.of(context).size.height),
              child: child,
            );
          },
          child: widget.current, // Pass current as child to prevent rebuild
        ),
      ],
    );
  }
}
