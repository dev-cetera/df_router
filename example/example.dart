import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// Define your routes.
final class HomeRoute extends RouteState {
  HomeRoute() : super.parse('/home');
}

final class ChatRoute extends RouteState {
  final String chatId;
  ChatRoute({required this.chatId})
      : super.parse('/chat', queryParameters: {'chatId': chatId});
  ChatRoute.from(RouteState other)
      : chatId = other.uri.queryParameters['chatId'] ?? '',
        super(other.uri);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return RouteManager(
          fallbackRouteState: HomeRoute.new,
          builders: [
            RouteBuilder(
              routeState: HomeRoute(),
              builder: (context, state) => const HomeScreen(),
            ),
            RouteBuilder(
              routeState: ChatRoute(chatId: ''),
              builder: (context, state) =>
                  ChatScreen(route: ChatRoute.from(state)),
            ),
          ],
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState = null;
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            RouteController.of(context).push(ChatRoute(chatId: '123'));
          },
          child: const Text('Go to Chat'),
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final ChatRoute? routeState;
  const ChatScreen({super.key, ChatRoute? route}) : routeState = route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat ${routeState?.chatId}')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => RouteController.of(context).goBackward(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
