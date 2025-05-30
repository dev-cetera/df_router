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
  final RouteState Function()? initialRouteState;
  final RouteState Function() fallbackRouteState;
  final RouteState<Enum> Function()? errorState;
  final void Function(RouteController controller)? onControllerCreated;
  final List<RouteBuilder> builders;

  final TRouteTransitionBuilder? transitionBuilder;

  /// Use this builder for wrapping the main content of the app. This is useful
  /// to add common widgets like a navigation bar, drawer, or any other
  /// widget that should be present on all screens.
  final TRouteWrapperFn? wrapper;

  const RouteManager({
    super.key,
    this.initialRouteState,
    required this.fallbackRouteState,
    this.errorState,
    this.onControllerCreated,
    required this.builders,
    this.transitionBuilder,

    this.wrapper,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteController(
      initialRouteState: initialRouteState,
      fallbackRouteState: fallbackRouteState,
      errorRouteState: errorState,
      builders: builders,
      shouldCapture: true,
      transitionBuilder: (context, params) {
        return transitionBuilder?.call(context, params) ??
            HorizontalSlideFadeTransition(
              prev: params.prevSnapshot,
              controller: params.controller,
              duration: const Duration(milliseconds: 275),
              child: params.child,
            );
      },
    );

    onControllerCreated?.call(controller);
    return RouteControllerProvider(
      controller: controller,
      child: ValueListenableBuilder(
        valueListenable: controller.pRouteState,
        builder: (context, value, snapshot) {
          final child = ClipRect(child: controller.buildScreen(context, value));
          return wrapper?.call(context, child) ?? child;
        },
      ),
    );
  }
}

typedef TRouteWrapperFn = Widget Function(BuildContext context, Widget child);
