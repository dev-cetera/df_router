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

class RouteManager extends StatefulWidget {
  final RouteState Function()? initialRouteState;
  final RouteState Function() fallbackRouteState;
  final RouteState<Enum> Function()? errorState;
  final void Function(RouteController controller)? onControllerCreated;
  final List<RouteBuilder> builders;
  final bool clipToBounds;
  final TRouteWrapperFn? wrapper;

  const RouteManager({
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
  State<RouteManager> createState() => _RouteManagerState();
}

class _RouteManagerState extends State<RouteManager> {
  late final RouteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RouteController(
      initialRouteState: widget.initialRouteState,
      fallbackRouteState: widget.fallbackRouteState,
      errorRouteState: widget.errorState,
      builders: widget.builders,
    );
    widget.onControllerCreated?.call(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return RouteControllerProvider(
      controller: _controller,
      child: SyncPodBuilder(
        pod: Sync.okValue(_controller.pRouteState),
        cacheDuration: null,
        builder: (context, snapshot) {
          Widget child;
          UNSAFE:
          child = RepaintBoundary(
            child: _controller.buildScreen(
              context,
              snapshot.value.unwrap().unwrap(),
            ),
          );
          if (widget.clipToBounds) {
            child = ClipRect(child: child);
          }
          return widget.wrapper?.call(context, child) ?? child;
        },
      ),
    );
  }
}
