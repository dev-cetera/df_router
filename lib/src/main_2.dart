import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Slide Widget Demo')),
        body: const SlideDemo(),
      ),
    );
  }
}

class SlideDemo extends StatefulWidget {
  const SlideDemo({super.key});

  @override
  State<SlideDemo> createState() => _SlideDemoState();
}

class _SlideDemoState extends State<SlideDemo> {
  final SlideWidgetController _controller = SlideWidgetController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SlideWidget(
          controller: _controller,
          duration: const Duration(milliseconds: 500),
          child: const TestChild(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _controller.reanimate, child: const Text('Reanimate')),
      ],
    );
  }
}

class TestChild extends StatefulWidget {
  const TestChild({super.key});

  @override
  State<TestChild> createState() => _TestChildState();
}

class _TestChildState extends State<TestChild> {
  int initCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
    debugPrint('TestChild initState called: $initCount');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Child Widget\nInit Count: $initCount',
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}

class SlideWidgetController {
  VoidCallback? _reanimate;

  void reanimate() {
    _reanimate?.call();
  }

  void dispose() {
    _reanimate = null;
  }
}

class SlideWidget extends StatefulWidget {
  final Widget child;
  final SlideWidgetController controller;
  final Duration duration;

  const SlideWidget({
    super.key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<SlideWidget> createState() => _SlideWidgetState();
}

class _SlideWidgetState extends State<SlideWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start off-screen to the left
      end: const Offset(0.0, 0.0), // End at original position
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    widget.controller._reanimate = () {
      _animationController.reset();
      _animationController.forward();
    };

    // Start the animation initially
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: KeyedSubtree(key: const ValueKey('slide_child'), child: widget.child),
    );
  }
}
