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

  const RouteManager({
    super.key,
    this.initialRoute,
    required this.fallbackRoute,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteController(
      initialRoute: initialRoute,
      fallbackRoute: fallbackRoute,
      routes: routes,
      transitionBuilder: (context, controller, shouldAnimate, prev, child) {
        if (!shouldAnimate) {
          controller.end();
        }
        return HorizontalSlideFadeTransition(
          prev: prev ?? const SizedBox.shrink(),
          controller: controller,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
    return RouteControllerProvider(
      controller: controller,
      child: ValueListenableBuilder<String>(
        valueListenable: controller.pCurrentPathQuery,
        builder: (context, currentRoute, child) {
          return controller.buildScreen(context, currentRoute);
        },
      ),
    );
  }
}
