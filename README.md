<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![pub package](https://img.shields.io/pub/v/df_router.svg)](https://pub.dev/packages/df_router)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_router/main/LICENSE)

## Summary

A lightweight router designed for ease of use and efficient state management. This package is in early development but remains simple and production-ready. It supports deep linking. For simplicity, this router does not support nested routes, which are unnecessary for most applications.

For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_router/).

## Usage Example

Define `RouteManager` somewhere in your app, typically at the root of your widget tree. This is where you will define your routes and their behaviors.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      builder:
          (context, child) => RouteManager(
            fallbackRoute: '/home',
            // Define how the pages should transition. You can use these
            // or create your own by extending `TransitionMixin`.
            transitionBuilder: (context, params) {
              // For iOS.
              return HorizontalSlideFadeTransition(
                // Prev is a capture of the previous page.
                prev: params.prev,
                controller: params.controller,
                duration: const Duration(milliseconds: 300),
                child: params.child,
              );
              // For Android.
              // return VerticalSlideFadeTransition(
              //   prev: params.prev,
              //   controller: params.controller,
              //   duration: const Duration(milliseconds: 300),
              //   child: params.child,
              // );
            },
            // Define your routes here.
            routes: [
              RouteBuilder(
                basePath: '/home',
                builder: (context, prev, pathQuery) {
                  return HomeScreen(pathQuery: pathQuery);
                },
              ),
              RouteBuilder(
                basePath: '/messages',
                // Preserves the route when navigating away. This means it will
                // be kept in memory and not disposed until manually disposed.
                shouldPreserve: true,
                builder: (context, prev, pathQuery) {
                  return MessagesScreen(pathQuery: pathQuery);
                },
              ),
              RouteBuilder(
                basePath: '/chat',
                // Pre-builds the widget even if the route is not at the top of
                // the stack. This is useful for routes that are frequently
                // navigated to or that takes some time to build.
                shouldPrebuild: true,
                builder: (context, prev, pathQuery) {
                  return ChatScreen(pathQuery: pathQuery);
                },
              ),
              RouteBuilder(
                basePath: '/detail',
                builder: (context, prev, pathQuery) {
                  return HomeDetailScreen(pathQuery: pathQuery);
                },
              ),
            ],
          ),
    );
  }
}
```

Navigate to a route or go back to the previous route:

```dart
// Push a new route with some parameters.
RouteManager.of(context).push('/messages?id=123&name=John');

// Push a new route with the defined transition animation.
RouteManager.of(context).push('/home', shouldAnimate: true);

// Push to the previous route.
RouteManager.of(context).pushBack();
```

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
