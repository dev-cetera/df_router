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

/// Bottom-sheet wrapper for routes flagged `RouteBuilder(isOverlay: true)`.
///
/// Animates its [child] up from the bottom on mount, follows vertical drags
/// so the user can drag it down, and pops the current route (via the parent
/// [RouteController]) once the user releases past the configured threshold.
/// A scrim fades in behind the sheet and absorbs taps; tapping the scrim
/// also dismisses by default.
///
/// Because this widget owns its own slide-in / slide-out animation, register
/// the route with `animationEffect: const NoEffect()` — otherwise the route
/// system's transition runs simultaneously with the widget's animation and
/// the two compete.
///
/// Programmatic dismissal from a descendant (e.g. a close button) can call
/// [DraggableModalSheet.dismiss] which animates the sheet out before popping.
class DraggableModalSheet extends StatefulWidget {
  /// Content rendered inside the sheet.
  final Widget child;

  /// Sheet height as a fraction of the available height. 1.0 fills the
  /// surface the route paints into.
  final double maxHeightFraction;

  /// Scrim color painted between the base route and the sheet. Set to `null`
  /// for a fully transparent backdrop (lets taps fall through to the base).
  final Color? scrimColor;

  /// When true, tapping the scrim runs the same dismissal flow as dragging.
  final bool dismissOnScrimTap;

  /// Downward fling velocity (logical px/sec) at or above which release
  /// dismisses regardless of distance dragged.
  final double dismissVelocityThreshold;

  /// Fractional drag distance (relative to sheet height, 0..1) past which a
  /// slow release dismisses the sheet. 0.3 = release at or beyond 30% down.
  final double dismissDistanceFraction;

  /// Duration of the initial slide-in and of snap-back-to-rest after a
  /// cancelled drag.
  final Duration slideInDuration;

  /// Duration of the dismissal slide-out.
  final Duration slideOutDuration;

  /// Curve for the slide-in / snap-back animation.
  final Curve slideInCurve;

  /// Curve for the dismissal slide-out animation.
  final Curve slideOutCurve;

  /// Whether to render a small drag-handle pill at the top of the sheet.
  final bool showDragHandle;

  /// Clip radius for the sheet's container.
  final BorderRadiusGeometry borderRadius;

  /// Background color of the sheet itself.
  final Color backgroundColor;

  /// Color of the drag-handle pill.
  final Color dragHandleColor;

  /// Called BETWEEN the slide-out animation and the route pop. Return `false`
  /// to cancel the pop (the sheet animates back to its resting position).
  /// Useful for confirmation prompts ("Discard unsaved changes?").
  final Future<bool> Function()? onDismiss;

  const DraggableModalSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 1.0,
    this.scrimColor = const Color(0x80000000),
    this.dismissOnScrimTap = true,
    this.dismissVelocityThreshold = 700.0,
    this.dismissDistanceFraction = 0.3,
    this.slideInDuration = const Duration(milliseconds: 350),
    this.slideOutDuration = const Duration(milliseconds: 250),
    this.slideInCurve = Curves.easeOutCubic,
    this.slideOutCurve = Curves.easeInCubic,
    this.showDragHandle = true,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(16.0),
    ),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.dragHandleColor = const Color(0x4D000000),
    this.onDismiss,
  });

  /// Dismiss the nearest enclosing [DraggableModalSheet] (animates out, then
  /// calls `controller.goBackward()`). Returns `true` if a sheet was found
  /// and dismissed.
  static bool dismiss(BuildContext context) {
    final state = context.findAncestorStateOfType<DraggableModalSheetState>();
    if (state == null) return false;
    state._dismiss();
    return true;
  }

  @override
  State<DraggableModalSheet> createState() => DraggableModalSheetState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class DraggableModalSheetState extends State<DraggableModalSheet>
    with SingleTickerProviderStateMixin {
  // 0 = sheet fully off-screen below, 1 = sheet at rest.
  late final AnimationController _progress;
  // Captured each frame by the LayoutBuilder so the drag handler can convert
  // pointer deltas into progress without re-measuring on every event.
  double _sheetHeight = 0.0;
  // Latches once dismissal starts so a second drag-end or scrim tap mid-exit
  // can't re-enter the flow and double-pop the route.
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: widget.slideInDuration,
      value: 0.0,
    );
    // Defer to the first frame so the LayoutBuilder has measured before the
    // slide-in starts — otherwise the sheet briefly paints at its final
    // position before the controller advances away from 0.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progress.animateTo(1.0, curve: widget.slideInCurve);
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _progress.duration = widget.slideOutDuration;
    await _progress.animateTo(0.0, curve: widget.slideOutCurve);
    if (!mounted) return;
    final shouldPop = await (widget.onDismiss?.call() ?? Future.value(true));
    if (!mounted) return;
    if (!shouldPop) {
      // The caller veto'd the pop; restore the sheet to its resting position
      // so the user is back to where they were before the drag.
      _dismissing = false;
      _progress.duration = widget.slideInDuration;
      await _progress.animateTo(1.0, curve: widget.slideInCurve);
      return;
    }
    final controller = RouteController.of(context);
    if (controller.canGoBackward) {
      controller.goBackward();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissing || _sheetHeight <= 0.0) return;
    final delta = (details.primaryDelta ?? 0.0) / _sheetHeight;
    _progress.value = (_progress.value - delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final distanceFraction = 1.0 - _progress.value;
    final shouldDismiss = velocity > widget.dismissVelocityThreshold ||
        distanceFraction >= widget.dismissDistanceFraction;
    if (shouldDismiss) {
      _dismiss();
    } else {
      _progress.duration = widget.slideInDuration;
      _progress.animateTo(1.0, curve: widget.slideInCurve);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _sheetHeight = constraints.maxHeight * widget.maxHeightFraction;
        return AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final progress = _progress.value;
            return Stack(
              children: [
                // Scrim — absorbs hits (so the base route can't receive them
                // while the sheet is up) and fades in with the sheet.
                if (widget.scrimColor != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      // Below ~1% the scrim is effectively invisible; let
                      // tests-of-life pass through so the briefly-mounted
                      // base isn't blocked at progress=0.
                      ignoring: progress < 0.01,
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.dismissOnScrimTap ? _dismiss : null,
                          child: ColoredBox(color: widget.scrimColor!),
                        ),
                      ),
                    ),
                  ),
                // Sheet — anchored to the bottom and translated off-screen by
                // `(1 - progress) * sheetHeight` so progress=0 is fully hidden
                // below the surface and progress=1 sits flush at the bottom.
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: -_sheetHeight * (1.0 - progress),
                  height: _sheetHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: ClipRRect(
                      borderRadius: widget.borderRadius,
                      child: ColoredBox(
                        color: widget.backgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showDragHandle) ...[
                              const SizedBox(height: 8.0),
                              Container(
                                width: 40.0,
                                height: 4.0,
                                decoration: BoxDecoration(
                                  color: widget.dragHandleColor,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                            ],
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
