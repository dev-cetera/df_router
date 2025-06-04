import 'package:df_router/df_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/rendering.dart' show debugRepaintRainbowEnabled;

void main() {
  debugRepaintRainbowEnabled = kDebugMode;
  runApp(const MyApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HomeRouteState extends RouteState {
  HomeRouteState()
    : super.parse('/home', animationEffect: const CupertinoEffect());
}

final class MessagesRouteState extends RouteState {
  MessagesRouteState()
    : super.parse('/messages', animationEffect: const CupertinoEffect());
}

final class ChatRouteState extends RouteState<String> {
  ChatRouteState()
    : super.parse('/chat', animationEffect: const CupertinoEffect());
}

final class MessagesRouteState1 extends RouteState {
  MessagesRouteState1()
    : super.parse(
        '/messages?key1=value1',
        queryParameters: {'key1': 'value1'},
        animationEffect: const CupertinoEffect(),
      );
}

final class MessagesRouteState2 extends RouteState {
  MessagesRouteState2()
    : super.parse(
        '/messages?key1=value1',
        queryParameters: {'key2': 'value2'},
        animationEffect: const CupertinoEffect(),
      );
}

final class HomeDetailRouteState extends RouteState {
  HomeDetailRouteState()
    : super.parse('/home_detail', animationEffect: const CupertinoEffect());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      builder: (context, child) {
        return Material(
          child: RouteManager(
            fallbackRouteState: () => HomeRouteState(),
            // wrapper: (context, child) {
            //   return Column(
            //     crossAxisAlignment: CrossAxisAlignment.stretch,
            //     children: [
            //       // Persistent app header.
            //       Container(
            //         color: Colors.blueGrey,
            //         padding: const EdgeInsets.all(16.0),
            //         child: const Text(
            //           'df_router Example',
            //           style: TextStyle(color: Colors.white, fontSize: 24.0),
            //         ),
            //       ),
            //       // Main content area.
            //       Expanded(child: child),
            //       // Persistent app footer with navigation buttons.
            //       Container(
            //         color: Colors.indigo,
            //         padding: const EdgeInsets.all(16.0),
            //         child: Row(
            //           children: [
            //             IconButton(
            //               onPressed: () {
            //                 final controller = RouteController.of(context);
            //                 controller.push(HomeRouteState());
            //               },
            //               icon: Text(
            //                 'HOME',
            //                 style: TextStyle(
            //                   color:
            //                       RouteController.of(context).routeState.matchPath(HomeRouteState())
            //                           ? Colors.grey
            //                           : Colors.white,
            //                 ),
            //               ),
            //             ),
            //             IconButton(
            //               onPressed: () {
            //                 final controller = RouteController.of(context);
            //                 controller.push(RouteState.parse('/chat'));
            //               },
            //               icon: Text(
            //                 'CHAT',
            //                 style: TextStyle(
            //                   color:
            //                       RouteController.of(context).routeState.path == '/chat'
            //                           ? Colors.grey
            //                           : Colors.white,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   );
            // },
            builders: [
              RouteBuilder(
                routeState: HomeRouteState(),
                builder: (context, state) {
                  return HomeScreen(key: state.key, routeState: state);
                },
              ),
              RouteBuilder(
                routeState: MessagesRouteState(),
                // Preserves the RouteState when navigating away. This means it will
                // be kept in memory and not disposed until manually disposed.
                //shouldPreserve: true,
                builder: (context, state) {
                  return MessagesScreen(routeState: state);
                },
              ),
              RouteBuilder<String>(
                routeState: ChatRouteState(),
                // Pre-builds the widget even if the RouteState is not at the top of
                // the stack. This is useful for RouteStates that are frequently
                // navigated to or that takes some time to build.
                shouldPrebuild: true,
                builder: (context, state) {
                  return ChatScreen(routeState: state);
                },
              ),
              RouteBuilder(
                routeState: HomeDetailRouteState(),
                shouldPreserve: true,
                builder: (context, state) {
                  return HomeDetailScreen(routeState: state);
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
  final RouteState routeState;

  const MessagesScreen({super.key, required this.routeState});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE MESSAGES - Params: ${widget.routeState.uri}');
  }

  @override
  void dispose() {
    debugPrint('MessagesScreen disposed - Params: ${widget.routeState.uri}');
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
            Text('Extra: ${widget.routeState.extra}'),
            Text(counter.toString()),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.push(HomeRouteState()),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(MessagesRouteState()),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push(MessagesRouteState1()),
              child: const Text('Go to Messages (key1=value1)'),
            ),

            FilledButton(
              onPressed: () => controller.push(
                MessagesRouteState2().copyWith(
                  extra: 'HELLO THERE HOW ARE YOU?',
                ),
              ),
              child: const Text('Go to Messages (key2=value2)'),
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
  final RouteState routeState;

  const HomeScreen({super.key, required this.routeState});

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
              onPressed: () => controller.push(MessagesRouteState()),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push(MessagesRouteState1()),
              child: const Text('Go to Messages (key1=value1)'),
            ),
            FilledButton(
              onPressed: () => controller.push(MessagesRouteState2()),
              child: const Text('Go to Messages (key2=value2)'),
            ),
            FilledButton(
              onPressed: () => controller.push(HomeDetailRouteState()),
              child: const Text('Go to Home Detail'),
            ),
            FilledButton(
              onPressed: () => controller.push(
                ChatRouteState().copyWith(extra: 'Hello from Home!'),
              ),
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
  final RouteState<String?> routeState;

  const ChatScreen({super.key, required this.routeState});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('INIT STATE CHAT - Params: ${widget.routeState}');
  }

  @override
  void dispose() {
    debugPrint('ChatScreen disposed - Params: ${widget.routeState}');
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
            Text(widget.routeState.extra.toString()),
            FilledButton(
              onPressed: () => controller.push(HomeRouteState()),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(
                ChatRouteState().copyWith(extra: 'Hello from Chat!'),
              ),
              child: const Text('Go to Chat (No ID)'),
            ),
            FilledButton(
              onPressed: () => controller.push(
                ChatRouteState().copyWith(
                  queryParameters: {'dude': '22'},
                  extra: 'Hello from Chat!',
                ),
              ),
              child: const Text('Go to Chat (ID=123)'),
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
  final RouteState? routeState;

  const HomeDetailScreen({super.key, this.routeState});

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
              onPressed: () => controller.push(HomeRouteState()),
              child: const Text('Back to Home'),
            ),
            FilledButton(
              onPressed: () => controller.push(MessagesRouteState()),
              child: const Text('Go to Messages'),
            ),
          ],
        ),
      ),
    );
  }
}
