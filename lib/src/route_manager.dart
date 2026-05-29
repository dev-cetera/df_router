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
  // When true (default), wraps the rendered tree in an `Overlay`. Widgets like
  // `TextField`, `Slider`, `Tooltip`, `PopupMenuButton`, and `SnackBar` look
  // up an `Overlay` ancestor and assert if none is found. The recommended
  // mount point for `RouteManager` is `MaterialApp.builder`, which bypasses
  // the `Navigator` (and therefore the `Overlay`) that `home`/`routes` would
  // otherwise create — without this, those widgets crash on first interaction.
  // Set to `false` if you supply your own `Navigator`/`Overlay` higher up.
  final bool provideOverlay;

  const RouteManager({
    super.key,
    this.initialRouteState,
    required this.fallbackRouteState,
    this.errorState,
    this.onControllerCreated,
    required this.builders,
    this.clipToBounds = false,
    this.wrapper,
    this.provideOverlay = true,
  });

  @override
  State<RouteManager> createState() => _RouteManagerState();
}

class _RouteManagerState extends State<RouteManager> {
  late final RouteController _controller;
  // Kept as a field so we can call `markNeedsBuild()` when `widget.wrapper`,
  // `widget.clipToBounds`, or any other field that the entry's subtree reads
  // changes via parent rebuild. `Overlay.initialEntries` is consumed once at
  // `initState` and ignored on later widget updates, so we cannot rely on a
  // fresh widget instance to push prop changes through.
  late final OverlayEntry _entry;

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
    _entry = OverlayEntry(builder: _buildBody);
  }

  @override
  void didUpdateWidget(RouteManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wrapper != widget.wrapper ||
        oldWidget.clipToBounds != widget.clipToBounds) {
      _entry.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    return SyncPodBuilder(
      pod: Sync.okValue(_controller.pCurrentRouteState),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.provideOverlay
        ? Overlay(initialEntries: [_entry])
        : _buildBody(context);
    return RouteControllerProvider(controller: _controller, child: child);
  }
}
