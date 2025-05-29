import 'package:flutter/material.dart';

import '../lib/df_router.dart';

void main() {
  runApp(const MyApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HomeRouteState extends RouteState {
  HomeRouteState() : super.parse('/home');
}

final class MessagesRouteState extends RouteState {
  MessagesRouteState() : super.parse('/messages');
}

final class MessagesRouteState1 extends RouteState {
  MessagesRouteState1() : super.parse('/messages?key1=value1');
}

final class MessagesRouteState2 extends RouteState {
  MessagesRouteState2() : super.parse('/messages?key1=value1', queryParameters: {'key2': 'value2'});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      builder: (context, child) {
        return Material(
          child: RouteStateManager(
            fallbackState: HomeRouteState(),
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
                            final controller = RouteStateController.of(context);
                            controller.pushState(HomeRouteState());
                          },
                          icon: Text(
                            'HOME',
                            style: TextStyle(
                              color:
                                  RouteStateController.of(context).state.matchPath(HomeRouteState())
                                      ? Colors.grey
                                      : Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final controller = RouteStateController.of(context);
                            controller.push('/chat');
                          },
                          icon: Text(
                            'CHAT',
                            style: TextStyle(
                              color:
                                  RouteStateController.of(context).state.path == '/chat'
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
            states: [
              RouteBuilder(
                state: HomeRouteState(),
                builder: (context, prev, state) {
                  return HomeScreen(state: state);
                },
              ),
              RouteBuilder(
                state: MessagesRouteState(),
                // Preserves the RouteState when navigating away. This means it will
                // be kept in memory and not disposed until manually disposed.
                shouldPreserve: true,
                builder: (context, prev, state) {
                  return MessagesScreen(state: state);
                },
              ),
              RouteBuilder<String>(
                state: RouteState<String>.parse('/chat'),
                // Pre-builds the widget even if the RouteState is not at the top of
                // the stack. This is useful for RouteStates that are frequently
                // navigated to or that takes some time to build.
                shouldPrebuild: true,
                builder: (context, prev, state) {
                  return ChatScreen(state: state);
                },
              ),
              RouteBuilder(
                state: RouteState.parse('/detail'),
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

class MessagesScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState state;

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
    final controller = RouteStateController.of(context);
    return Container(
      color: Colors.lightGreen,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Extra: ${widget.state.extra}'),
            Text(counter.toString()),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.pushState(HomeRouteState()),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.pushState(MessagesRouteState()),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push('/messages?key1=value1', shouldAnimate: true),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(MessagesRouteState1()),
              child: const Text('DISPOSE Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed:
                  () => controller.pushState(
                    MessagesRouteState2().copyWith(
                      extra: 'HELLO THERE HOW ARE YOU?',
                      shouldAnimate: true,
                    ),
                  ),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(widget.state),
              child: const Text('Dispose This RouteState'),
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState state;

  const HomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController.of(context);
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
              onPressed: () => controller.push('/chat', extra: 'Hello from Home!'),
              child: const Text('Go to Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ChatScreen extends StatefulWidget with RouteWidgetMixin<String> {
  @override
  final RouteState<String?> state;

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
    final controller = RouteStateController.of(context);
    return Container(
      color: Colors.blue,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.state.extra.toString()),
            FilledButton(
              onPressed: () => controller.push('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push('/chat', extra: 'Hello from Chat!'),
              child: const Text('Go to Chat (No ID)'),
            ),
            FilledButton(
              onPressed:
                  () => controller.push(
                    '/chat?id=123',
                    queryParameters: {'dude': '22'},
                    extra: 'Hello from Chat!',
                  ),
              child: const Text('Go to Chat (ID=123)'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(widget.state),
              child: const Text('Dispose This RouteState'),
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HomeDetailScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState state;

  const HomeDetailScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController.of(context);
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
