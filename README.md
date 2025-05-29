<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![pub package](https://img.shields.io/pub/v/df_router.svg)](https://pub.dev/packages/df_router)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_router/main/LICENSE)

## Summary

A lightweight router designed for ease of use and efficient state management.

## Features

- **Declarative Routing:** Define your routes and their corresponding widgets in a clean, list-based manner.
- **Stateful Routes:** `RouteState` objects represent unique routes, including paths, query parameters, and strongly-typed `extra` data.
- **Widget Caching & Preservation:** Control whether route widgets are preserved in memory (`shouldPreserve`) or pre-built (`shouldPrebuild`) for performance.
- **Customizable Transitions:** Easily define custom page transitions or use the provided `HorizontalSlideFadeTransition` and `VerticalSlideFadeTransition`.
- **Persistent UI Wrapper:** Add common UI elements like headers, footers, or navigation bars that persist across route changes.
- **Easy Navigation:** Navigate using `RouteState` objects or simple path strings.
- **Typed `extra` Data:** Pass strongly-typed data between routes.

## Usage

### 1. Define Your RouteStates

Create classes that extend `RouteState` for each distinct route in your application. These classes encapsulate the path and can manage query parameters.

```dart
// Define specific route states for type safety and clarity
final class HomeRouteState extends RouteState {
  HomeRouteState() : super.parse('/home');
}

final class MessagesRouteState extends RouteState {
  MessagesRouteState() : super.parse('/messages');
}

// Route state with specific query parameters
final class MessagesWithQueryRouteState extends RouteState {
  MessagesWithQueryRouteState({String? key1Value})
      : super.parse('/messages', queryParameters: key1Value != null ? {'key1': key1Value} : null);
}

// Route state expecting typed 'extra' data
final class ChatRouteState extends RouteState<String> { // Expects a String as extra data
  ChatRouteState({String? chatId})
      : super.parse(chatId != null ? '/chat?id=$chatId' : '/chat');
}
```

### 2. Configure RouteStateManager

In your MaterialApp (or CupertinoApp), use the RouteStateManager widget to define your application's routing configuration.

```dart
import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

// Your screen widgets (HomeScreen, MessagesScreen, ChatScreen)
// ... (defined below or in separate files)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      // RouteStateManager handles the routing logic
      builder: (context, child) { // child here is the Navigator from MaterialApp
        return Material( // Or any root widget
          child: RouteStateManager(
            // The route to show if no other route matches or if the initial route is invalid
            fallbackState: HomeRouteState(),
            // Optional: Define an initial state for the app
            // initialState: HomeRouteState(),

            // A wrapper for persistent UI elements (e.g., AppBar, BottomNavigationBar)
            wrapper: (context, child) { // child here is the current screen
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: Colors.blueGrey,
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      'df_router Example', // Example app title
                      style: TextStyle(color: Colors.white, fontSize: 24.0),
                    ),
                  ),
                  Expanded(child: child), // Main content area for the current route
                  Container( /* Your persistent footer/navbar */ ),
                ],
              );
            },

            // Define custom transitions between routes
            transitionBuilder: (context, params) {
              return VerticalSlideFadeTransition(
                prev: params.prev, // Captured image of the previous screen
                controller: params.controller,
                duration: const Duration(milliseconds: 300),
                child: params.child, // The incoming screen widget
              );
            },

            // List of all available routes and their builders
            states: [
              RouteBuilder(
                state: HomeRouteState(), // The base state for this route
                builder: (context, prev, state) {
                  return HomeScreen(state: state); // Your screen widget
                },
              ),
              RouteBuilder(
                state: MessagesRouteState(),
                shouldPreserve: true, // Keep this widget's state when navigating away
                builder: (context, prev, state) {
                  return MessagesScreen(state: state);
                },
              ),
              RouteBuilder<String>( // Specify the type for 'extra' if used
                state: RouteState<String>.parse('/chat'), // Generic RouteState for paths
                shouldPrebuild: true, // Build this widget proactively
                builder: (context, prev, state) {
                  // state is RouteState<String?> here
                  return ChatScreen(state: state);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 3. Create Your Screen Widgets

Your screen widgets should use the RouteWidgetMixin to easily access the current RouteState.

```dart
// Stateless widget example.
class HomeScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState state; // The current RouteState for this screen

  const HomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController.of(context);
    return Container(
      color: Colors.yellow,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen - Path: ${state.path}'),
            FilledButton(
              onPressed: () => controller.pushState(MessagesRouteState()),
              child: const Text('Go to Messages (No Query)'),
            ),
            FilledButton(
              onPressed: () => controller.push(
                '/messages?key1=value1', // Navigate by path string
                extra: "Some data for messages",
              ),
              child: const Text('Go to Messages (with query & extra)'),
            ),
            FilledButton(
              onPressed: () => controller.pushState(
                ChatRouteState().copyWith(extra: "Hello from Home!"),
              ),
              child: const Text('Go to Chat with extra data'),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful widget example.
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
    debugPrint('MessagesScreen INIT - State: ${widget.state}');
    debugPrint('MessagesScreen Extra: ${widget.state.extra}'); // Access extra data
    debugPrint('MessagesScreen Query: ${widget.state.uri.queryParameters}');
  }

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController.of(context);
    return Container(
      color: Colors.lightGreen,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Messages Screen - Path: ${widget.state.path}'),
            Text('Query Params: ${widget.state.uri.queryParameters}'),
            Text('Extra: ${widget.state.extra}'),
            Text('Counter: $counter'),
            FilledButton(
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
            FilledButton(
              onPressed: () => controller.pushState(HomeRouteState()),
              child: const Text('Go to Home'),
            ),
            FilledButton(
              onPressed: () => controller.disposeState(widget.state),
              child: const Text('Dispose This RouteState (if preserved)'),
            ),
          ],
        ),
      ),
    );
  }
}

// Using typed data, e.g., String for chat ID.
class ChatScreen extends StatelessWidget with RouteWidgetMixin<String> {
  @override
  final RouteState<String?> state; // state.extra will be String?

  const ChatScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController.of(context);
    return Container(
      color: Colors.blue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Chat Screen - Path: ${state.path}'),
            Text('Chat ID from query: ${state.uri.queryParameters['id']}'),
            Text('Extra data from previous route: ${state.extra ?? "No extra data"}'),
            FilledButton(
              onPressed: () => controller.pushState(HomeRouteState()),
              child: const Text('Go to Home'),
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

// Navigate using a defined RouteState object
controller.pushState(HomeRouteState());
controller.pushState(MessagesWithQueryRouteState(key1Value: "example"));

// Navigate using a path string
controller.push('/messages?key1=value1&key2=value2');

// Pass extra data (can be any object)
controller.push('/chat', extra: "Some chat ID or object");
// Or with RouteState
controller.pushState(ChatRouteState().copyWith(extra: "User123"));


// Control animation
controller.push('/detail', shouldAnimate: true);
controller.pushState(HomeRouteState().copyWith(shouldAnimate: false));

// Dispose a specific preserved RouteState instance from cache
controller.disposeState(MessagesRouteState()); // If it matches a cached one
```

## Key Concepts

- `RouteState<TExtra>`: Represents a specific route. It's Equatable based on its Uri (path and query parameters). TExtra defines the type of the optional extra data payload.

- `RouteState.parse(String pathAndQuery, {Map<String, String>? queryParameters, TExtra? extra})`: Constructor to create a state from a string.

- `.copyWith()`: Useful for creating a new RouteState instance with modified properties.

- `.extra`: Accesses the data passed during navigation.

- `.uri`: The Uri object representing the path and query parameters.

- `RouteBuilder<TExtra>`: Links a RouteState definition to a widget builder function.

- `state`: The base RouteState that this builder handles (path matching).

- `builder`: A function (context, previousWidget, state) => YourWidget(state: state) that builds your screen. previousWidget is a captured image of the previous screen for transitions.

- `shouldPreserve`: If true, the widget's state is kept in memory even when navigated away from. Useful for screens with complex state or forms.

- `shouldPrebuild`: If true, the widget is built proactively, even if not currently active. Useful for frequently accessed routes or routes that are slow to build.

- `condition`: An optional function () => bool. If it returns false, navigation to this route is blocked.

- `RouteStateManager`: The main widget that initializes and manages the routing system.

- `fallbackState`: The RouteState to navigate to if the current URL doesn't match any defined RouteBuilder or if an error occurs.

- `initialState`: (Optional) The RouteState to display when the app first loads. If not provided, it tries to infer from the platform's current URL or uses fallbackState.

- `states`: A list of RouteBuilder instances defining all navigable routes.

- `wrapper`: A builder function (context, child) => Widget to wrap around the current route's widget. Ideal for persistent headers, footers, or sidebars.

- `transitionBuilder`: A function (context, TransitionBuilderParams params) => Widget that defines how transitions between routes are animated.

- `RouteStateController`: The core controller for managing route state and navigation.

- `RouteStateController.of(context)`: Accesses the controller from the widget tree.

- `state`: The current active RouteState.

- `pushState(RouteState state)`: Navigates to the given RouteState.

- `push(String path, {Map<String, String>? queryParameters, TExtra? extra, bool skipCurrent, bool shouldAnimate})`: Navigates to a route defined by a path string.

- `disposeState(RouteState state)`: Removes a specific RouteState and its associated widget from the cache (if shouldPreserve was true and it matches).

- `disposePath(Uri path)`: Removes all cached RouteState instances matching the given path.

- `clear()`: Clears the entire widget cache.

- `RouteWidgetMixin<TExtra>`: A mixin for your screen widgets to easily receive and hold the `RouteState<TExtra?>` state property.

- `HorizontalSlideFadeTransition`: A transition that slides the new screen in from the right while fading it in, and slides the previous screen out to the left.

- `VerticalSlideFadeTransition`: A transition that slides the new screen in from the bottom while fading it in, and slides the previous screen out to the top.

- Custom transitions can be built by adding the `TransitionMixin` to your custom transition widget.

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_router/main/LICENSE) for more information.
