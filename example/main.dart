import 'package:flutter/material.dart';
import 'package:df_router/df_router.dart';

void main() {
  runApp(const MyApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      builder:
          (context, child) => RouteManager(
            fallbackRoute: '/home',
            transitionBuilder: (context, params) {
              // For iOS.
              return HorizontalSlideFadeTransition(
                // Prev is a capture of the previous page.
                prev: params.prev,
                controller: params.controller,
                duration: const Duration(milliseconds: 300),
                child: params.child,
              );
              // For Android.
              // return VerticalSlideFadeTransition(
              //   prev: params.prev,
              //   controller: params.controller,
              //   duration: const Duration(milliseconds: 300),
              //   child: params.child,
              // );
            },
            routes: [
              RouteBuilder(
                basePath: '/home',
                // Does not dispose the route when navigating away.
                shouldPreserve: false,
                builder: (context, prev, pathQuery) {
                  return HomeScreen(pathQuery: pathQuery);
                },
              ),

              RouteBuilder(
                basePath: '/messages',
                shouldPreserve: true,
                builder: (context, prev, pathQuery) {
                  return MessagesScreen(pathQuery: pathQuery);
                },
              ),
              RouteBuilder(
                basePath: '/chat',
                shouldPreserve: false,
                // Builds the widget even if the route is not on the stack.
                shouldPrebuild: true,
                builder: (context, prev, pathQuery) {
                  return ChatScreen(pathQuery: pathQuery);
                },
              ),
              RouteBuilder(
                basePath: '/detail',
                shouldPreserve: false,
                builder: (context, prev, pathQuery) {
                  return HomeDetailScreen(pathQuery: pathQuery);
                },
              ),
            ],
          ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MessagesScreen extends StatefulWidget {
  final String pathQuery;

  const MessagesScreen({super.key, required this.pathQuery});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE MESSAGES - Params: ${widget.pathQuery}');
  }

  @override
  void dispose() {
    debugPrint('MessagesScreen disposed - Params: ${widget.pathQuery}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    return Container(
      color: Colors.lightGreen,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(counter.toString()),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.push('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages', shouldAnimate: true),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key1=value1', shouldAnimate: true),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeExactRoute('/messages?key1=value1'),
              child: const Text('DISPOSE Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key2=value2', shouldAnimate: true),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeExactRoute(widget.pathQuery),
              child: const Text('Dispose This Route'),
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HomeScreen extends StatelessWidget {
  final String pathQuery;

  const HomeScreen({super.key, required this.pathQuery});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    debugPrint('INIT STATE HOME');
    return Container(
      color: Colors.yellow,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onPressed: () => controller.push('/detail'),
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ChatScreen extends StatefulWidget {
  final String pathQuery;

  const ChatScreen({super.key, required this.pathQuery});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE CHAT - Params: ${widget.pathQuery}');
  }

  @override
  void dispose() {
    debugPrint('ChatScreen disposed - Params: ${widget.pathQuery}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    return Container(
      color: Colors.blue,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onPressed: () => controller.disposeExactRoute(widget.pathQuery),
              child: const Text('Dispose This Route'),
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HomeDetailScreen extends StatelessWidget {
  final String pathQuery;

  const HomeDetailScreen({super.key, required this.pathQuery});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    debugPrint('INIT STATE HOME DETAIL');
    return Container(
      color: Colors.green,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
