## Summary

A lightweight Flutter router with state management. [Live demo](https://dev-cetera.github.io/df_router/).

## Quick Start

```dart
import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// 1. Define routes.
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

// 2. Setup RouteManager.
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
              builder: (context, state) => ChatScreen(route: ChatRoute.from(state)),
            ),
          ],
        );
      },
    );
  }
}

// 3. Navigate.
RouteController.of(context).push(ChatRoute(chatId: '123'));
RouteController.of(context).goBackward();
```

## Features

- Declarative route definitions
- Query parameter support
- Typed route data via `extra`
- Widget caching with `shouldPreserve` and `shouldPrebuild`
- Custom transitions (`MaterialEffect`, `CupertinoEffect`, etc.)
