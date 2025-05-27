import 'package:flutter/material.dart';

import 'src/_src.g.dart';

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
        shouldPreserve: false,
        shouldAnimate: false,
        builder: (context, prev, pathQuery) {
          return HomeScreen(pathQuery: pathQuery);
        },
      ),

      RouteBuilder(
        basePath: '/messages',
        shouldPreserve: true,
        shouldAnimate: true,
        builder: (context, prev, pathQuery) {
          return MessagesScreen(pathQuery: pathQuery);
        },
      ),
      RouteBuilder(
        basePath: '/chat',
        shouldPreserve: false,
        shouldPrebuild: true,
        builder: (context, prev, pathQuery) {
          return ChatScreen(pathQuery: pathQuery);
        },
      ),
      RouteBuilder(
        basePath: '/detail',
        shouldPreserve: false,
        builder: (context, prev, pathQuery) => HomeDetailScreen(pathQuery: pathQuery),
      ),
    ];

    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => RouteManager(routes: routes, fallbackRoute: '/home'),
    );
  }
}

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
    print('INIT STATE MESSAGES - Params: ${widget.pathQuery}');
  }

  @override
  void dispose() {
    print('MessagesScreen disposed - Params: ${widget.pathQuery}');
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
              onPressed: () => controller.disposeExactRoute(widget.pathQuery),
              child: const Text('Dispose This Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String pathQuery;

  const HomeScreen({super.key, required this.pathQuery});

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
    print('INIT STATE CHAT - Params: ${widget.pathQuery}');
  }

  @override
  void dispose() {
    print('ChatScreen disposed - Params: ${widget.pathQuery}');
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

class HomeDetailScreen extends StatelessWidget {
  final String pathQuery;

  const HomeDetailScreen({super.key, required this.pathQuery});

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
