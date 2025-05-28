import 'package:flutter/material.dart';

import 'df_router.dart';

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
      builder: (context, child) {
        return Material(
          child: RouteManager(
            fallbackState: Uri.parse('/home'),
            wrapper: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Persistent app header.
                  Container(
                    color: Colors.blueGrey,
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      'df_router Example',
                      style: TextStyle(color: Colors.white, fontSize: 24.0),
                    ),
                  ),
                  // Main content area.
                  Expanded(child: child),
                  // Persistent app footer with navigation buttons.
                  Container(
                    color: Colors.indigo,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            final controller = RouteController.of(context);
                            controller.push(Uri.parse('/home'));
                          },
                          icon: Text(
                            'HOME',
                            style: TextStyle(
                              color:
                                  RouteController.of(context).state.path == '/home'
                                      ? Colors.grey
                                      : Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final controller = RouteController.of(context);
                            controller.push(Uri.parse('/chat'));
                          },
                          icon: Text(
                            'CHAT',
                            style: TextStyle(
                              color:
                                  RouteController.of(context).state.path == '/chat'
                                      ? Colors.grey
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            transitionBuilder: (context, params) {
              // For iOS.
              // return Expanded(
              //   child: HorizontalSlideFadeTransition(
              //     // Prev is a capture of the previous page.
              //     prev: params.prev,
              //     controller: params.controller,
              //     duration: const Duration(milliseconds: 300),
              //     child: params.child,
              //   ),
              // );
              // For Android.
              return VerticalSlideFadeTransition(
                prev: params.prev,
                controller: params.controller,
                duration: const Duration(milliseconds: 300),
                child: params.child,
              );
            },
            routes: [
              RouteBuilder(
                path: '/home',
                builder: (context, prev, state) {
                  return HomeScreen(state: state);
                },
              ),
              RouteBuilder(
                path: '/messages',
                // Preserves the route when navigating away. This means it will
                // be kept in memory and not disposed until manually disposed.
                shouldPreserve: true,
                builder: (context, prev, state) {
                  return MessagesScreen(state: state);
                },
              ),
              RouteBuilder(
                path: '/chat',
                // Pre-builds the widget even if the route is not at the top of
                // the stack. This is useful for routes that are frequently
                // navigated to or that takes some time to build.
                shouldPrebuild: true,
                builder: (context, prev, state) {
                  return ChatScreen(state: state);
                },
              ),
              RouteBuilder(
                path: '/detail',
                builder: (context, prev, state) {
                  return HomeDetailScreen(state: state);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MessagesScreen extends StatefulWidget {
  final Uri state;

  const MessagesScreen({super.key, required this.state});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE MESSAGES - Params: ${widget.state}');
  }

  @override
  void dispose() {
    debugPrint('MessagesScreen disposed - Params: ${widget.state}');
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
              onPressed: () => controller.push(Uri.parse('/home')),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/messages'), shouldAnimate: true),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed:
                  () => controller.push(Uri.parse('/messages?key1=value1'), shouldAnimate: true),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(Uri.parse('/messages?key1=value1')),
              child: const Text('DISPOSE Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed:
                  () => controller.push(Uri.parse('/messages?key2=value2'), shouldAnimate: true),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(widget.state),
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
  final Uri state;

  const HomeScreen({super.key, required this.state});

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
              onPressed: () => controller.push(Uri.parse('/messages')),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/messages?key1=value1')),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/messages?key2=value2')),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/detail')),
              child: const Text('Go to Home Detail'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/chat')),
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
  final Uri state;

  const ChatScreen({super.key, required this.state});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE CHAT - Params: ${widget.state}');
  }

  @override
  void dispose() {
    debugPrint('ChatScreen disposed - Params: ${widget.state}');
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
              onPressed: () => controller.push(Uri.parse('/home')),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/chat')),
              child: const Text('Go to Chat (No ID)'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/chat?id=123')),
              child: const Text('Go to Chat (ID=123)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(widget.state),
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
  final Uri state;

  const HomeDetailScreen({super.key, required this.state});

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
              onPressed: () => controller.push(Uri.parse('/home')),
              child: const Text('Back to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(Uri.parse('/messages')),
              child: const Text('Go to Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
