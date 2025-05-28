//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import '_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteManager extends StatelessWidget {
  final Uri? initialState;
  final Uri fallbackState;
  final List<RouteBuilder> routes;
  final TTransitionBuilder? transitionBuilder;

  /// Use this builder for wrapping the main content of the app. This is useful
  /// to add common widgets like a navigation bar, drawer, or any other
  /// widget that should be present on all screens.
  final Widget Function(BuildContext context, Widget child)? wrapper;

  const RouteManager({
    super.key,
    this.initialState,
    required this.fallbackState,
    required this.routes,
    this.transitionBuilder,
    this.wrapper,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteController(
      initialState: initialState,
      fallbackState: fallbackState,
      routeBuilders: routes,
      transitionBuilder: (context, params) {
        return transitionBuilder?.call(context, params) ??
            HorizontalSlideFadeTransition(
              prev: params.prev,
              controller: params.controller,
              duration: const Duration(milliseconds: 300),
              child: params.child,
            );
      },
    );

    return RouteControllerProvider(
      controller: controller,
      child: ValueListenableBuilder(
        valueListenable: controller.pState,
        builder: (context, value, snapshot) {
          final child = ClipRect(child: controller.buildScreen(context, value));
          return wrapper?.call(context, child) ?? child;
        },
      ),
    );
  }
}
