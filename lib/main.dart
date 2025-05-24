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
        path: '/home',
        preserve: false,
        transition: false,
        builder: (context, prev, uri) {
          return HomeScreen(uri: uri);
        },
      ),

      RouteBuilder(
        path: '/messages',
        preserve: true,
        builder: (context, prev, uri) {
          return MessagesScreen(uri: uri);
        },
      ),
      RouteBuilder(
        path: '/chat',
        preserve: false,
        builder: (context, prev, uri) {
          return ChatScreen(uri: uri);
        },
      ),
      RouteBuilder(
        path: '/home/1',
        preserve: false,
        builder: (context, _, uri) => HomeDetailScreen(uri: uri),
      ),
    ];

    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => RouteManager(routes: routes),
    );
  }
}

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
              onPressed: () => controller.goToNew('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages'),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages?key1=value1'),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeFullRoute('/messages?key1=value1'),
              child: const Text('DISPOSE Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages?key2=value2'),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeFullRoute(fullRoute),
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
              onPressed: () => controller.goToNew('/messages'),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages?key1=value1'),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages?key2=value2'),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/home/1?detail=true'),
              child: const Text('Go to Home Detail'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/chat'),
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
              onPressed: () => controller.goToNew('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/chat'),
              child: const Text('Go to Chat (No ID)'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/chat?id=123'),
              child: const Text('Go to Chat (ID=123)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeFullRoute(fullRoute),
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
              onPressed: () => controller.goToNew('/home'),
              child: const Text('Back to Home'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/messages'),
              child: const Text('Go to Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
