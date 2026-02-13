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

// StatefulWidget wrapper that owns the RouteController's lifecycle. Must be
// stateful so the controller survives rebuilds — StatelessRouteManager was
// deprecated because it recreated the controller on every rebuild, leaking
// listeners and losing all navigation state.
class RouteManager extends StatefulWidget {
  final RouteState Function()? initialRouteState;
  final RouteState Function() fallbackRouteState;
  // Typed as Enum to guarantee the error route carries a categorized error
  // code rather than arbitrary data.
  final RouteState<Enum> Function()? errorState;
  final void Function(RouteController controller)? onControllerCreated;
  final List<RouteBuilder> builders;
  // When true, clips animation overflow so transitioning screens don't
  // paint outside the router's bounds.
  final bool clipToBounds;
  // Lets the host app inject a wrapper widget (e.g. for overlays, drawers)
  // without subclassing RouteManager.
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
  void dispose() {
    // ignore: invalid_use_of_visible_for_testing_member
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RouteControllerProvider makes the controller available to descendants
    // via RouteController.of(context), mirroring the InheritedWidget pattern.
    return RouteControllerProvider(
      controller: _controller,
      // SyncPodBuilder rebuilds only when the current route actually changes,
      // not on every Pod notification. cacheDuration: null disables debouncing
      // so route changes reflect immediately.
      child: SyncPodBuilder(
        pod: Sync.okValue(_controller.pCurrentRouteState),
        cacheDuration: null,
        builder: (context, snapshot) {
          Widget child;
          // UNSAFE label: unwrap() will throw if the Pod is in an error state.
          // Acceptable here because pCurrentRouteState is derived from an
          // internal Pod that should never error.
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
