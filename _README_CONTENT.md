## Summary

A lightweight router designed for ease of use and efficient state management. Explore it in action with this live web app: https://dev-cetera.github.io/df_router/chat?chatId=123456.

## Features

- **Declarative Routing:** Define your routes and their corresponding widgets in a clean, list-based manner.
- **Stateful Routes:** `RouteState` objects represent unique routes, including paths, query parameters, and strongly-typed `extra` data.
- **Widget Caching & Preservation:** Control whether route widgets are preserved in memory (`shouldPreserve`) or pre-built (`shouldPrebuild`) for performance.
- **Customizable Transitions:** Easily define custom page transitions called "effects" or use the provided `MaterialEffect` and `CupertinoEffect`.
- **Persistent UI Wrapper:** Add common UI elements like headers, footers, or navigation bars that persist across route changes.
- **Easy Navigation:** Navigate using `RouteState` objects or simple path strings.
- **Typed `extra` Data:** Pass strongly-typed data between routes.

## Usage

### 1. Define Your RouteStates

Create classes that extend `RouteState` for each distinct route in your application. These classes encapsulate the path and can manage query parameters.

```dart
final class HomeRouteState extends RouteState {
  HomeRouteState()
    : super.parse(
        '/home',
        // Use QuickForwardtEffect() as the default transtion effect for this
        // route. This can be overridden when pushing this route.
        animationEffect: const QuickForwardEffect(),
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

  ChatRouteState({required this.chatId}) : super(queryParameters: {'chatId': chatId});

  ChatRouteState.from(super.other)
    : chatId = other.uri.queryParameters['chatId'] ?? '',
      super.from();
}
```

### 2. Configure RouteStateManager

In your MaterialApp (or CupertinoApp), use the RouteStateManager widget to define your application's routing configuration.

```dart
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
              builder: (context, routeState) => HomeScreen(routeState: HomeRouteState()),
            ),
            RouteBuilder(
              // Use the BaseChatRouteState instead of the ChatRouteState
              // since it does not require a chatId to be pushed.
              routeState: BaseChatRouteState(),
              builder:
                  (context, routeState) => ChatScreen(routeState: ChatRouteState.from(routeState)),
            ),
          ],
        );
      },
    );
  }
}
```

### 3. Create Your Screen Widgets

Your screen widgets should use the `RouteWidgetMixin` to easily access the current `RouteState`.

```dart
class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final HomeRouteState? routeState;
  const HomeScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
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
                controller.pushBack();
              },
              child: const Text('Go Back - Default Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.pushBack(animationEffect: const QuickBackEffect());
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
                controller.push(HomeRouteState().copyWith(animationEffect: const MaterialEffect()));
              },
              child: const Text('Go Home - Material Effect'),
            ),
            ElevatedButton(
              onPressed: () {
                final controller = RouteController.of(context);
                controller.push(HomeRouteState(), animationEffect: const PageFlapDown());
              },
              child: const Text('Go Home - Page Flap Down Effect'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 4. Navigation

Access the RouteStateController to navigate:

```dart
final controller = RouteStateController.of(context);

// Push the home screen with a material effect.
controller.push(HomeRouteState(), animationEffect: const CupertinoEffect());
controller.push(HomeRouteState().copyWith(animationEffect: const MaterialEffect()));

// Go back.
controller.pushBack();

// Remove a specific route to free up resources.
controller.removeStatesFromCache([HomeRouteState()]);

// Clear the entire widget cache.
controller.clearCache([HomeRouteState()]);

// Add a route to the cache without navigating. This will preload it.
controller.addToCache([HomeRouteState()]);

// Reset the cache to its initial state. This honours the shouldPrebuild property.
controller.resetState();

// Get the current state, e.g. HomeRouteState();
final current = controller.current;

// Get the requested state, which is what was typed in the URL bar, e.g. "/home?query=123" may return an instance of HomeRouteState(). This will return nul if the URL does not match any defined route.
final requested = controller.requested;
```