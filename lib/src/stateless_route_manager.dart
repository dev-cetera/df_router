//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class StatelessRouteManager extends StatelessWidget {
  final RouteState Function()? initialRouteState;
  final RouteState Function() fallbackRouteState;
  final RouteState<Enum> Function()? errorState;
  final void Function(RouteController controller)? onControllerCreated;
  final List<RouteBuilder> builders;
  final bool clipToBounds;
  final TRouteWrapperFn? wrapper;

  const StatelessRouteManager({
    super.key,
    this.initialRouteState,
    required this.fallbackRouteState,
    this.errorState,
    this.onControllerCreated,
    required this.builders,
    this.clipToBounds = false,
    this.wrapper,
  });

  @override
  Widget build(BuildContext context) {
    final controller = RouteController(
      initialRouteState: initialRouteState,
      fallbackRouteState: fallbackRouteState,
      errorRouteState: errorState,
      builders: builders,
    );

    onControllerCreated?.call(controller);
    return RouteControllerProvider(
      controller: controller,
      child: SyncPodBuilder(
        pod: Sync.okValue(controller.pCurrentRouteState),
        cacheDuration: null,
        builder: (context, snapshot) {
          Widget child;
          UNSAFE:
          child = RepaintBoundary(
            child: controller.buildScreen(
              context,
              snapshot.value.unwrap().unwrap(),
            ),
          );
          if (clipToBounds) {
            child = ClipRect(child: child);
          }
          return wrapper?.call(context, child) ?? child;
        },
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TRouteWrapperFn = Widget Function(BuildContext context, Widget child);
