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
      RouteConfig(
        path: '/home',
        maintainState: false,
        builder: (context, queryParams) => HomeScreen(queryParams: queryParams),
      ),
      RouteConfig(
        path: '/messages',
        maintainState: true,
        builder: (context, queryParams) => MessagesScreen(queryParams: queryParams),
      ),
      RouteConfig(
        path: '/chat',
        maintainState: false,
        builder: (context, queryParams) => ChatScreen(queryParams: queryParams),
      ),
      RouteConfig(
        path: '/home/1',
        maintainState: false,
        builder: (context, queryParams) => HomeDetailScreen(queryParams: queryParams),
      ),
    ];

    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => CustomRouter(initialRoute: '/home', routes: routes),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const MessagesScreen({Key? key, this.queryParams = const {}}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    print('INIT STATE MESSAGES - Params: ${widget.queryParams}');
  }

  @override
  void dispose() {
    print('MessagesScreen disposed - Params: ${widget.queryParams}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    final fullRoute =
        '/messages' +
        (widget.queryParams.isEmpty ? '' : '?${Uri(queryParameters: widget.queryParams).query}');
    return Container(
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Messages Screen - Counter: $counter'),
            Text('Query Params: ${widget.queryParams.toString()}'),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.goToNew('/home'),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.goTo('/messages'),
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
  final Map<String, String> queryParams;

  const HomeScreen({Key? key, required this.queryParams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    print('INIT STATE HOME');
    return Container(
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen - Params: ${queryParams.toString()}'),
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
  final Map<String, String> queryParams;

  const ChatScreen({Key? key, this.queryParams = const {}}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    print('INIT STATE CHAT - Params: ${widget.queryParams}');
  }

  @override
  void dispose() {
    print('ChatScreen disposed - Params: ${widget.queryParams}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    final fullRoute =
        '/chat' +
        (widget.queryParams.isEmpty ? '' : '?${Uri(queryParameters: widget.queryParams).query}');
    return Container(
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chat Screen - ID: ${widget.queryParams['id'] ?? 'None'}'),
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
  final Map<String, String> queryParams;

  const HomeDetailScreen({Key? key, required this.queryParams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    print('INIT STATE HOME DETAIL');
    return Container(
      child: Center(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Detail Screen - Params: ${queryParams.toString()}'),
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
