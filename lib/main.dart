/*
import 'package:df_router/src/capture_widget_picture.dart';
import 'package:df_widgets/_common.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: CaptureTest()));
}

class CaptureTest extends StatefulWidget {
  const CaptureTest({super.key});

  @override
  _CaptureTestState createState() => _CaptureTestState();
}

class _CaptureTestState extends State<CaptureTest> with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  WidgetPicture? _capturedPicture;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureAndTransition() async {
    final picture = captureWidgetPicture(context: context, repaintKey: _repaintKey);
    if (picture != null) {
      setState(() {
        _capturedPicture = picture;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Test')),
      body: Column(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: 200,
              height: 200,
              color: Colors.blue,
              child: Center(
                child: BreatheAnimator(
                  child: Text('Capture this', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          ElevatedButton(onPressed: _captureAndTransition, child: const Text('Capture')),
          if (_capturedPicture != null)
            PictureWidget(picture: _capturedPicture, size: const Size(200, 200)),
        ],
      ),
    );
  }
}*/

// void main() {
//   runApp(const MaterialApp(home: CaptureTest()));
// }

// class CaptureTest extends StatefulWidget {
//   const CaptureTest({super.key});

//   @override
//   _CaptureTestState createState() => _CaptureTestState();
// }

// class _CaptureTestState extends State<CaptureTest> {
//   final GlobalKey _repaintKey = GlobalKey();
//   ui.Picture? _capturedPicture;

//   void _captureRendering() {
//     final renderObject = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//     if (renderObject != null && renderObject.debugLayer != null) {
//       final pictureLayer = findPictureLayer(renderObject.debugLayer);
//       if (pictureLayer != null) {
//         final picture = pictureLayer.picture;
//         if (picture != null) {
//           setState(() {
//             _capturedPicture = picture;
//           });
//           print('Picture captured successfully');
//         } else {
//           print('Picture is null');
//         }
//       } else {
//         print('No PictureLayer found');
//       }
//     } else {
//       print('RenderObject or debugLayer is null');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Capture Test')),
//       body: Column(
//         children: [
//           RepaintBoundary(
//             key: _repaintKey,
//             child: Container(
//               width: 200,
//               height: 200,
//               color: Colors.blue,
//               child: SizedBox(
//                 child: const Center(
//                   child: Text('Capture this', style: TextStyle(color: Colors.white)),
//                 ),
//               ),
//             ),
//           ),
//           ElevatedButton(onPressed: _captureRendering, child: const Text('Capture')),
//           if (_capturedPicture != null)
//             CustomPaint(painter: PicturePainter(_capturedPicture!), size: Size(200, 200)), //
//         ],
//       ),
//     );
//   }
// }

// PictureLayer? findPictureLayer(Layer? layer) {
//   if (layer == null) return null;
//   if (layer is PictureLayer && layer.picture != null) return layer;
//   if (layer is ContainerLayer) {
//     var child = layer.firstChild;
//     while (child != null) {
//       final pictureLayer = findPictureLayer(child);
//       if (pictureLayer != null) return pictureLayer;
//       child = child.nextSibling;
//     }
//   }
//   return null;
// }

// // Custom painter to draw the captured Picture
// class PicturePainter extends CustomPainter {
//   final ui.Picture picture;

//   PicturePainter(this.picture);

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawPicture(picture);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'package:df_router/src/platform_navigator.dart';
import 'package:df_router/src/slides/cupertino_screen_transition.dart';
import 'package:df_router/src/slides/material_screen_transition.dart';
import 'package:df_widgets/_common.dart';
import 'package:flutter/material.dart';

import 'src/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = [
      RouteBuilder(
        basePath: '/home',
        preserveWidget: false,
        enableTransition: false,
        builder: (context, prev, pathQuery) {
          return HomeScreen(uri: Uri.parse(pathQuery));
        },
      ),

      RouteBuilder(
        basePath: '/messages',
        preserveWidget: true,
        builder: (context, prev, pathQuery) {
          return MessagesScreen(uri: Uri.parse(pathQuery));
        },
      ),
      RouteBuilder(
        basePath: '/chat',
        preserveWidget: false,
        prebuildWidget: true,
        builder: (context, prev, pathQuery) {
          return ChatScreen(uri: Uri.parse(pathQuery));
        },
      ),
      RouteBuilder(
        basePath: '/home/1',
        preserveWidget: false,
        builder: (context, prev, pathQuery) => HomeDetailScreen(uri: Uri.parse(pathQuery)),
      ),
    ];

    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => RouteManager(routes: routes),
    );
  }
}

final _a = SlideWidgetController();

class MessagesScreen extends StatefulWidget {
  final Uri uri;

  const MessagesScreen({super.key, required this.uri});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    print('INIT STATE MESSAGES - Params: ${widget.uri}');
  }

  @override
  void dispose() {
    print('MessagesScreen disposed - Params: ${widget.uri}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    final fullRoute =
        '/messages${widget.uri.queryParameters.isEmpty ? '' : '?${Uri(queryParameters: widget.uri.queryParameters).query}'}';
    return Container(
      color: Colors.lightGreen,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Messages Screen - Counter: $counter'),
            Text('Query Params: ${widget.uri.queryParameters}'),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.push('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages'),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key1=value1'),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeExactRoute('/messages?key1=value1'),
              child: const Text('DISPOSE Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key2=value2'),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeExactRoute(fullRoute),
              child: const Text('Dispose This Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Uri uri;

  const HomeScreen({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    print('INIT STATE HOME');
    return Container(
      color: Colors.yellow,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen - Params: ${uri.toString()}'),
            FilledButton(
              onPressed: () => controller.push('/messages'),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key1=value1'),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key2=value2'),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/home/1?detail=true'),
              child: const Text('Go to Home Detail'),
            ),
            FilledButton(
              onPressed: () => controller.push('/chat'),
              child: const Text('Go to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Uri uri;

  const ChatScreen({super.key, required this.uri});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    print('INIT STATE CHAT - Params: ${widget.uri}');
  }

  @override
  void dispose() {
    print('ChatScreen disposed - Params: ${widget.uri}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    final fullRoute =
        '/chat${widget.uri.queryParameters.isEmpty ? '' : '?${Uri(queryParameters: widget.uri.queryParameters).query}'}';
    return Container(
      color: Colors.blue,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chat Screen - ID: ${widget.uri.queryParameters['id'] ?? 'None'}'),
            FilledButton(
              onPressed: () => controller.push('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push('/chat'),
              child: const Text('Go to Chat (No ID)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/chat?id=123'),
              child: const Text('Go to Chat (ID=123)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeExactRoute(fullRoute),
              child: const Text('Dispose This Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDetailScreen extends StatelessWidget {
  final Uri uri;

  const HomeDetailScreen({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    print('INIT STATE HOME DETAIL');
    return Container(
      color: Colors.green,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Detail Screen - Params: ${uri.toString()}'),
            FilledButton(
              onPressed: () => controller.push('/home'),
              child: const Text('Back to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages'),
              child: const Text('Go to Messages'),
            ),
          ],
        ),
      ),
    );
  }
}

class SlideWidgetController {
  VoidCallback? $reanimate;

  void reanimate() {
    Future.microtask(() {
      $reanimate?.call();
    });
  }

  void clear() {
    $reanimate = null;
  }
}

class SlideWidget extends StatefulWidget {
  final Widget child;
  final Widget? prev;
  final SlideWidgetController controller;
  final Duration duration;

  const SlideWidget({
    super.key,
    required this.child,
    this.prev,
    required this.controller,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SlideWidget> createState() => _SlideWidgetState();
}

class _SlideWidgetState extends State<SlideWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slide;
  late Animation<Offset> _prevSlide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: widget.duration);

    // Start not animated.
    _animationController.value = 1.0;

    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _prevSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-0.33, 0.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _fade = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    widget.controller.$reanimate = () {
      _animationController.reset();
      _animationController.forward();
    };

    // Start the animation initially
    _animationController.forward();
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
            child: FadeTransition(opacity: _fade, child: widget.prev!),
          ),
        SlideTransition(
          position: _slide,
          child: KeyedSubtree(key: const ValueKey('slide_child'), child: widget.child),
        ),
      ],
    );
  }
}
