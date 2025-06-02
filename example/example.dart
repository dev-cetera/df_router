import 'package:flutter/material.dart';
import 'package:df_router/df_router.dart';

void main() {
  runApp(const MyApp());
}

final class HomeRouteState extends RouteState {
  HomeRouteState()
    : super.parse(
        '/home',
        // Use QuickForwardtEffect() as the default transtion effect for this
        // route. This can be overridden when pushing this route.
        animationEffect: QuickForwardtEffect(),
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
        animationEffect: SlideDownEffect(),
      );
}

final class ChatRouteState extends BaseChatRouteState {
  // Required chatId before pushing this route.
  ChatRouteState({required String chatId}) : super(queryParameters: {'chatId': chatId});
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
              builder: (context, routeState) => HomeScreen(routeState: routeState),
            ),
            RouteBuilder(
              // Use the BaseChatRouteState instead of the ChatRouteState
              // since it does not require a chatId to be pushed.
              routeState: BaseChatRouteState(),
              builder: (context, routeState) => SettingsScreen(routeState: routeState),
            ),
          ],
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState<Object?>? routeState;
  const HomeScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final controller = RouteController.of(context);
            controller.push(
              ChatRouteState(chatId: '123456'),
              // Override the default animation effect for this push.
              animationEffect: CupertinoEffect(),
            );
          },
          child: const Text('Go to Chat'),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState<Object?>? routeState;

  const SettingsScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.pushBack(animationEffect: QuickBackEffect());
              },
              child: const Text('Go Back'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.push(HomeRouteState());
              },
              child: const Text('Go Home (Same as Back)'),
            ),
          ),
        ],
      ),
    );
  }
}
