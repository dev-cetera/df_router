import 'package:df_router/main.dart';
import 'package:flutter/material.dart';

import 'screen_transition_mixin.dart';

class CupertinoScreenTransition extends StatefulWidget with ScreenTransitionMixin {
  @override
  final Widget prev;
  @override
  final Widget child;
  @override
  final Duration duration;

  final SlideWidgetController controller;

  const CupertinoScreenTransition({
    super.key,
    required this.prev,
    required this.child,
    required this.duration,
    required this.controller,
  });

  // static Widget transition(
  //   Widget child, {
  //   Widget? prev,
  //   Duration duration = const Duration(milliseconds: 300),
  // }) {
  //   if (prev == null) {
  //     return child;
  //   }
  //   return CupertinoScreenTransition(prev: prev, duration: duration, child: child);
  // }

  @override
  State<CupertinoScreenTransition> createState() => _CupertinoScreenTransitionState();
}

class _CupertinoScreenTransitionState extends State<CupertinoScreenTransition>
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

    // Current widget slides from right (1.0) to center (0.0)
    _currentSlide = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Previous widget slides from center (0.0) to left (-0.33)
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
      }
    });

    widget.controller.$reanimate = () {
      _controller.reset();
      _controller.forward();
    };

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.controller.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // After completion, return only the current widget
    if (_isCompleted) {
      return widget.child;
    }

    // During transition, show the animated stack
    return Stack(
      children: [
        // Previous screen
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_prevSlide.value * MediaQuery.of(context).size.width, 0),
              child: Opacity(opacity: _prevOpacity.value, child: widget.prev),
            );
          },
        ),
        // Current screen
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_currentSlide.value * MediaQuery.of(context).size.width, 0),
              child: KeyedSubtree(key: const ValueKey('slide_child'), child: widget.child),
            );
          },
        ),
      ],
    );
  }
}
