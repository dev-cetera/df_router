import 'package:df_widgets/_common.dart';
import 'package:flutter/material.dart';

import 'src/router.dart';

void main() {
  print(Uri.parse('https://dude.com/hello?name=123').query);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = [
      RouteBuilder(path: '/home', preserve: false, builder: (context, uri) => HomeScreen(uri: uri)),

      RouteBuilder(
        path: '/messages',
        preserve: true,
        builder: (context, uri) => MessagesScreen(uri: uri),
      ),
      RouteBuilder(path: '/chat', preserve: false, builder: (context, uri) => ChatScreen(uri: uri)),
      RouteBuilder(
        path: '/home/1',
        preserve: false,
        builder: (context, uri) => HomeDetailScreen(uri: uri),
      ),
    ];

    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => CustomRouter(initialRoute: '/home', routes: routes),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  final Uri uri;

  const MessagesScreen({Key? key, required this.uri}) : super(key: key);

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
        '/messages' +
        (widget.uri.queryParameters.isEmpty
            ? ''
            : '?${Uri(queryParameters: widget.uri.queryParameters).query}');
    return Container(
      color: Colors.lightGreen,
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Messages Screen - Counter: $counter'),
            Text('Query Params: ${widget.uri.toString()}'),
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

  const HomeScreen({Key? key, required this.uri}) : super(key: key);

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

  const ChatScreen({Key? key, required this.uri}) : super(key: key);

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
        '/chat' +
        (widget.uri.queryParameters.isEmpty
            ? ''
            : '?${Uri(queryParameters: widget.uri.queryParameters).query}');
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

  const HomeDetailScreen({Key? key, required this.uri}) : super(key: key);

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
