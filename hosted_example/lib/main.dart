import 'package:df_router/df_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/rendering.dart' show debugRepaintRainbowEnabled;

void main() {
  debugRepaintRainbowEnabled = kDebugMode;
  setToUrlPathStrategy();
  runApp(const MyApp());
}

final class HomeRouteState extends RouteState {
  HomeRouteState()
    : super.parse(
        '/home',
        // Use QuickForwardtEffect() as the default transtion effect for this
        // route. This can be overridden when pushing this route.
        animationEffect: const ForwardEffectWeb(),
      );
}

// This route is only used in the RouteManager, so it does not need to
// be pushed directly. It is a base route for the chat feature.
final class BaseChatRouteState extends RouteState {
  BaseChatRouteState({Map<String, String>? queryParameters})
    : super.parse(
        '/chat',
        queryParameters: queryParameters,
        // Use a different animation effect for this route.
        animationEffect: const SlideDownEffect(),
      );

  BaseChatRouteState.from(RouteState other) : super(other.uri);
}

final class ChatRouteState extends BaseChatRouteState {
  final String chatId;

  ChatRouteState({required this.chatId})
    : super(queryParameters: {'chatId': chatId});

  ChatRouteState.from(super.other)
    : chatId = other.uri.queryParameters['chatId'] ?? '',
      super.from();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //home: // Do not use "home", as it conflicts with RouteManager. Use
      // "builder" instead.
      builder: (context, child) {
        return RouteManager(
          fallbackRouteState: () => HomeRouteState(),
          builders: [
            RouteBuilder(
              routeState: HomeRouteState(),
              // Pre-build the HomeScreen even if the initial route is not
              // HomeRouteState. This is useful for performance optimization.
              shouldPrebuild: true,
              // Preserve the HomeScreen widget to avoid rebuilding it.
              shouldPreserve: true,
              builder: (context, routeState) =>
                  HomeScreen(routeState: HomeRouteState()),
            ),
            RouteBuilder(
              // Use the BaseChatRouteState instead of the ChatRouteState
              // since it does not require a chatId to be pushed.
              routeState: BaseChatRouteState(),
              builder: (context, routeState) =>
                  ChatScreen(routeState: ChatRouteState.from(routeState)),
            ),
          ],
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final HomeRouteState? routeState;
  const HomeScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomeScreen with routeState: $routeState');
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      backgroundColor: Colors.green,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final controller = RouteController.of(context);
            controller.push(
              ChatRouteState(chatId: '123456'),
              // Override the default animation effect for this push.
              animationEffect: const CupertinoEffect(),
            );
          },
          child: const Text('Go to Chat'),
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final ChatRouteState? routeState;

  const ChatScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ChatScreen with routeState: $routeState');
    return Scaffold(
      appBar: AppBar(title: Text('Chat - ${routeState?.chatId}')),
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.goBackward();
              },
              child: const Text('Go Back - Default Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.goBackward(
                  animationEffect: const BackwardEffectWeb(),
                );
              },
              child: const Text('Go Back - Quick Back Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.push(HomeRouteState());
              },
              child: const Text('Go Home - Default Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.push(
                  HomeRouteState().copyWith(
                    animationEffect: const MaterialEffect(),
                  ),
                );
              },
              child: const Text('Go Home - Material Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.push(
                  HomeRouteState(),
                  animationEffect: const PageFlapDown(),
                );
              },
              child: const Text('Go Home - Page Flap Down Effect'),
            ),
          ],
        ),
      ),
    );
  }
}
