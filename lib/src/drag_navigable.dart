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

/// Wraps a route's content in a horizontal-pan gesture that drives the
/// router's tentative-navigation API. Drag right-to-left to go forward
/// (commit a push toward [forwardTarget]); drag left-to-right to go
/// backward (commit toward [backwardTarget]). Release past the threshold
/// commits the navigation; release short of it cancels.
///
/// Both [forwardTarget] and [backwardTarget] are *callbacks* so the
/// destination can depend on app state at gesture-start time (e.g., the
/// kindle example computes "next book" relative to the current book). A
/// callback returning `null` disables drag in that direction.
///
/// The widget assumes the wrapped [child] doesn't have its own horizontal
/// scroll surface — otherwise both gestures fight for the pan. The kindle
/// example wraps its book contents (a vertical `SingleChildScrollView`)
/// so there's no conflict.
class DragNavigable extends StatefulWidget {
  /// Subtree that receives the drag and continues to handle taps,
  /// vertical scroll, etc.
  final Widget child;

  /// Called at gesture-start to pick the route the user should land on
  /// after a forward (right-to-left) drag completes. Return `null` to
  /// disable forward drags from here.
  final RouteState? Function() forwardTarget;

  /// Called at gesture-start to pick the route the user should land on
  /// after a backward (left-to-right) drag completes. Return `null` to
  /// disable backward drags.
  final RouteState? Function() backwardTarget;

  /// Animation effect for forward commits.
  final AnimationEffect forwardEffect;

  /// Animation effect for backward commits.
  final AnimationEffect backwardEffect;

  /// Drag distance (as fraction of screen width, 0..1) at or above which
  /// release commits the navigation. Below this, the release reverts.
  final double distanceThreshold;

  /// Horizontal release velocity (logical px/sec) at or above which
  /// release commits regardless of how far the user actually dragged.
  /// Lets a quick flick navigate even without crossing the distance
  /// threshold.
  final double velocityThreshold;

  /// Minimum drag distance (in logical pixels) before a tentative
  /// navigation is started. Filters out accidental jitter from a tap.
  final double startSlop;

  const DragNavigable({
    super.key,
    required this.child,
    required this.forwardTarget,
    required this.backwardTarget,
    this.forwardEffect = const ForwardEffect(),
    this.backwardEffect = const BackwardEffect(),
    this.distanceThreshold = 0.35,
    this.velocityThreshold = 700.0,
    this.startSlop = 8.0,
  });

  @override
  State<DragNavigable> createState() => _DragNavigableState();
}

class _DragNavigableState extends State<DragNavigable> {
  // True between the gesture's startSlop crossing and the gesture end.
  bool _tentativeStarted = false;
  // Cached at drag start. We can't query MediaQuery during onUpdate cheaply.
  double _width = 1.0;
  // Direction picked when we crossed startSlop. true = forward (R→L).
  bool _forward = true;
  // Accumulated horizontal delta since drag start. We track it ourselves so
  // we can decide direction at slop time and not flip mid-gesture.
  double _accumDx = 0.0;

  void _onPanStart(DragStartDetails details) {
    _tentativeStarted = false;
    _accumDx = 0.0;
    _width = MediaQuery.sizeOf(context).width;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _accumDx += details.delta.dx;

    final controller = RouteController.of(context);

    if (!_tentativeStarted) {
      if (_accumDx.abs() < widget.startSlop) return;
      _forward = _accumDx < 0;
      final target =
          _forward ? widget.forwardTarget() : widget.backwardTarget();
      if (target == null) return;
      final effect = _forward ? widget.forwardEffect : widget.backwardEffect;
      final ok = controller.beginTentativeNavigation(target, effect: effect);
      if (!ok) return;
      _tentativeStarted = true;
    }

    if (!_tentativeStarted) return;

    // Distance dragged in the active direction, expressed as 0..1.
    final progress = (_forward ? -_accumDx : _accumDx) / _width;
    controller.updateTentativeProgress(progress.clamp(0.0, 1.0));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_tentativeStarted) return;
    final controller = RouteController.of(context);
    _tentativeStarted = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final velocityInDirection = _forward ? -velocity : velocity;
    final progress = (_forward ? -_accumDx : _accumDx) / _width;

    final shouldCommit = velocityInDirection >= widget.velocityThreshold ||
        progress >= widget.distanceThreshold;

    if (shouldCommit) {
      controller.commitTentative();
    } else {
      // Fire-and-forget — the controller's reverse animation runs to
      // completion without us needing to wait.
      controller.abortTentative();
    }
  }

  void _onPanCancel() {
    if (!_tentativeStarted) return;
    _tentativeStarted = false;
    RouteController.of(context).abortTentative();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onPanStart,
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      onHorizontalDragCancel: _onPanCancel,
      child: widget.child,
    );
  }
}
