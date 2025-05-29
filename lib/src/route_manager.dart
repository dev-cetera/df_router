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

class RouteStateManager extends StatelessWidget {
  final RouteState? initialState;
  final RouteState fallbackState;
  final List<RouteBuilder> states;
  final TTransitionBuilder? transitionBuilder;

  /// Use this builder for wrapping the main content of the app. This is useful
  /// to add common widgets like a navigation bar, drawer, or any other
  /// widget that should be present on all screens.
  final Widget Function(BuildContext context, Widget child)? wrapper;

  const RouteStateManager({
    super.key,
    this.initialState,
    required this.fallbackState,
    required this.states,
    this.transitionBuilder,
    this.wrapper,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteStateController(
      initialState: initialState,
      fallbackState: fallbackState,
      RouteStateBuilders: states,
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

    return RouteStateControllerProvider(
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
