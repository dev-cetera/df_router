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
  final String? initialRoute;
  final String fallbackRoute;
  final List<RouteBuilder> routes;
  final TTransitionBuilder? transitionBuilder;

  const RouteManager({
    super.key,
    this.initialRoute,
    required this.fallbackRoute,
    required this.routes,
    this.transitionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteController(
      initialRoute: initialRoute,
      fallbackRoute: fallbackRoute,
      routes: routes,
      transitionBuilder: (context, params) {
        return transitionBuilder?.call(context, params) ??
            HorizontalSlideFadeTransition(
              prev: params.prev ?? const SizedBox.shrink(),
              controller: params.controller,
              duration: const Duration(milliseconds: 300),
              child: params.child,
            );
      },
    );
    return RouteControllerProvider(
      controller: controller,
      child: ValueListenableBuilder<String>(
        valueListenable: controller.pCurrentPathQuery,
        builder: (context, value, snapshot) {
          return controller.buildScreen(context, value);
        },
      ),
    );
  }
}
