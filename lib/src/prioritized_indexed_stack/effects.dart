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

import 'dart:math' as math;
import 'dart:ui' as ui;

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Shared perspective matrix for the 3D page-turn effects (PageFlapLeft,
// PageFlapRight, PaperTurnEffect). Cached as a top-level `final` because the
// value is constant — allocating an identical Matrix4 every animation frame
// (60–120 Hz) is wasted work. DO NOT MUTATE; it is shared across all callers.
final _kPagePerspective = Matrix4.identity()..setEntry(3, 2, 0.003);

class NoEffect extends AnimationEffect {
  const NoEffect() : super(duration: Duration.zero, curve: Curves.linear);

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    return const [AnimationLayerEffect(), AnimationLayerEffect()];
  }
}

class FadeEffectWeb extends AnimationEffect {
  const FadeEffectWeb()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeOutSine,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    return [
      AnimationLayerEffect(opacity: value),
      // Web version is simple for performance reasons.
      if (kIsWeb)
        const AnimationLayerEffect(ignorePointer: true)
      else
        AnimationLayerEffect(opacity: 1.0 - value * 0.5, ignorePointer: true),
    ];
  }
}

class FadeEffect extends AnimationEffect {
  const FadeEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeOutSine,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    return [
      AnimationLayerEffect(opacity: value),
      AnimationLayerEffect(opacity: 1.0 - value * 0.5, ignorePointer: true),
    ];
  }
}

class BackwardEffectWeb extends AnimationEffect {
  const BackwardEffectWeb()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuint,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(-size.width + w, 0.0, 0.0),
      ),
      // Web version is simple for performance reasons.
      if (kIsWeb)
        const AnimationLayerEffect(ignorePointer: true)
      else
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(w * 0.5, 0.0, 0.0),
          ignorePointer: true,
        ),
    ];
  }
}

class BackwardEffect extends AnimationEffect {
  const BackwardEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuint,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(-size.width + w, 0.0, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(w * 0.5, 0.0, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

class ForwardEffectWeb extends AnimationEffect {
  const ForwardEffectWeb()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuint,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(size.width - w, 0.0, 0.0),
      ),
      // Web version is simple for performance reasons.
      if (kIsWeb)
        const AnimationLayerEffect(ignorePointer: true)
      else
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(-w * 0.5, 0.0, 0.0),
          ignorePointer: true,
        ),
    ];
  }
}

class ForwardEffect extends AnimationEffect {
  const ForwardEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuint,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(size.width - w, 0.0, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(-w * 0.5, 0.0, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

class SlideUpEffect extends AnimationEffect {
  const SlideUpEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuart,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final h = size.height * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(0.0, size.height - h, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(0.0, -h * 0.5, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

class SlideDownEffect extends AnimationEffect {
  const SlideDownEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOutQuart,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final h = size.height * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(0.0, -size.height + h, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(0.0, h * 0.5, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

class CupertinoEffect extends AnimationEffect {
  const CupertinoEffect()
      : super(
          duration: const Duration(milliseconds: 410),
          curve: Curves.easeInOut,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(size.width - w, 0.0, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(-w * 0.5, 0.0, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

class MaterialEffect extends AnimationEffect {
  const MaterialEffect()
      : super(
          duration: const Duration(milliseconds: 275),
          curve: Curves.fastOutSlowIn,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    final w = size.width * value;
    return [
      AnimationLayerEffect(
        transform: Matrix4.translationValues(size.width - w, 0.0, 0.0),
      ),
      AnimationLayerEffect(
        opacity: 1.0 - value * 0.1,
        transform: Matrix4.translationValues(-w * 0.5, 0.0, 0.0),
        ignorePointer: true,
      ),
    ];
  }
}

// Simulates a Kindle/Apple Books page turn. The incoming page pivots around
// its left edge (like a physical page hinge) using a perspective Y-rotation,
// while the outgoing page stays flat underneath with a darkening shadow overlay.
class PageFlapLeft extends AnimationEffect {
  const PageFlapLeft()
      : super(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    // value goes 0 → 1. At 0 the page is fully "closed" (rotated -90° around
    // the left hinge). At 1 the page is fully "open" (flat, facing the user).
    final angle = (1.0 - value) * (-math.pi / 2.0);

    // The rotation is around the Y-axis at x=0, so the page naturally hinges
    // on its left edge. Combine the shared perspective with this rotation.
    final rotation = Matrix4.identity()..rotateY(angle);
    final transform = _kPagePerspective * rotation;

    return [
      AnimationLayerEffect(
        transform: transform as Matrix4,
        opacity: 0.3 + 0.7 * value,
      ),
      // The outgoing (background) page dims slightly to create depth.
      AnimationLayerEffect(opacity: 1.0 - value * 0.3, ignorePointer: true),
    ];
  }
}

// Reverse page flap — the incoming page pivots around its right edge, flapping
// in from the right like turning a page backward.
class PageFlapRight extends AnimationEffect {
  const PageFlapRight()
      : super(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    // value goes 0 → 1. At 0 the page is rotated 90° around the right hinge.
    // At 1 the page is fully open (flat, facing the user).
    final angle = (1.0 - value) * (math.pi / 2.0);

    final rotation = Matrix4.identity()..rotateY(angle);

    // Translate to right edge, rotate, then translate back — this makes the
    // page hinge on its right edge instead of the left.
    final hinge = Matrix4.translationValues(size.width, 0.0, 0.0) *
        rotation *
        Matrix4.translationValues(-size.width, 0.0, 0.0);

    final transform = _kPagePerspective * hinge;

    return [
      AnimationLayerEffect(
        transform: transform as Matrix4,
        opacity: 0.3 + 0.7 * value,
      ),
      AnimationLayerEffect(opacity: 1.0 - value * 0.3, ignorePointer: true),
    ];
  }
}

// Paper-like page turn — the OUTGOING page is the visible mover. It lifts off
// the surface toward the viewer, rotates around its LEFT edge, and sweeps off
// the screen to the left. The INCOMING page just sits flat underneath and is
// progressively revealed as the outgoing page rotates away.
//
// `previousOnTop` is `true`, so the router renders the outgoing page in slot
// 0 (top) and the incoming page in slot 1 (bottom). Slot-0 layer data here
// describes the turning page; slot-1 describes the static background.
//
// Effects layered on top of the primary Y rotation:
//
//   1. MULTI-AXIS ROTATION — the primary Y rotation gets a forward X-tilt
//      sibling (the page bowing toward you mid-turn).
//   2. SHARED PERSPECTIVE (`_kPagePerspective`) — genuine 3D depth so the
//      lifted edge looms toward the viewer.
//   3. STRONG X-Y SHEAR peaking mid-turn — the closest Matrix4 can get to
//      "pixel bending". A real curl is a non-linear, per-pixel warp; a
//      fragment shader is the only correct way to do that. Shear is the best
//      linear approximation: it tilts the page surface as it rotates so the
//      "leading edge" looks like it's leaning into the turn.
//   4. -Z LIFT and a small -Y rise — the page floats up off the surface
//      mid-turn beyond what the rotation alone provides.
//   5. MOTION BLUR (`ui.ImageFilter.blur`) — dominantly horizontal, with a
//      small vertical component so the edges don't look razor-sharp at
//      mid-turn.
//   6. STRONG SCRIM on the INCOMING page (`ColorFilter.mode` + black +
//      `BlendMode.srcOver`, alpha ≤ 0.65 at peak) — darkens the background
//      so the silhouette and curl of the turning page above stand out.
//
// All mid-turn envelopes use `sin(value * π)` (peaks at value=0.5, zero at
// value=0 and value=1), so the start/end frames look like flat, undisturbed
// pages — only the *middle* of the transition shows the bend.
class PaperTurnEffect extends AnimationEffect {
  const PaperTurnEffect()
      : super(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );

  @override
  bool get previousOnTop => true;

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    // POSITIVE rotation around the left-edge Y axis: the right side of the
    // page swings TOWARD the viewer (negative Z under Flutter's perspective)
    // mid-turn, giving the "lifts off the surface and away" feel. The page
    // ends at +90° (edge-on); past that there's no second face to render.
    final angleY = value * (math.pi / 2.0);

    final midPeak = math.sin(value * math.pi);

    // -Z lift (toward viewer) — the rotation already pushes the trailing
    // edge in -Z; this is a modest additional rise so the whole page reads
    // as "lifting" before it pivots away. Tuned small (4% of width) because
    // larger values combined with the rotation pull the page noticeably
    // off-center and reveal background between the page edge and the
    // rotation hinge.
    final lift = Matrix4.translationValues(
      0.0,
      0.0,
      -midPeak * size.width * 0.04,
    );

    // Y rotation only — earlier versions stacked an X-tilt and X+Y shears
    // on top, but each of those is applied BEFORE the Y rotation in the
    // matrix product, which displaces the page's left edge AWAY from the
    // rotation hinge (X=0). The result was a visible gap between the page
    // and the left side of the screen mid-turn, especially at the
    // bottom-left corner where the X-shear (`x += shearX * y`) is largest.
    // True paper curl is a non-linear, per-pixel warp; only a fragment
    // shader can do it cleanly, so we keep the linear transform pure.
    final rotation = Matrix4.identity()..rotateY(angleY);

    // SIZE-AWARE PERSPECTIVE. `_kPagePerspective`'s entry of 0.003 (camera
    // ~333 logical-px back) works for the existing `PageFlap*` effects
    // because they rotate INTO the screen (positive Z, W = 1 + 0.003*z
    // stays > 1). The new direction rotates OUT of the screen: at full
    // ±π/2 the trailing edge sits at z = -size.width, so for any page
    // wider than ~333 px we'd get W < 0 — the GPU clips that side away,
    // and the user sees half the page disappear mid-turn. Set the camera
    // distance to 2x the longer dimension so W stays in [0.5, 1.5] for
    // every supported viewport. The `.max(1.0, ...)` guards against the
    // `Size.zero` measurement that can happen in headless/test contexts:
    // without it, `1.0 / 0.0` evaluates to infinity and propagates NaN
    // through the transform.
    final cameraDistance =
        math.max(1.0, math.max(size.width, size.height) * 2.0);
    final perspective = Matrix4.identity()
      ..setEntry(3, 2, 1.0 / cameraDistance);

    final transform = perspective * lift * rotation;

    final blurX = midPeak * 2.0;

    // At value=1 the page is rotated exactly 90° around the left edge — a
    // geometric line of pixels at x=0 that anti-aliasing renders as a thin
    // visible stripe. That stripe lingers in slot 0 of the indices between
    // transitions (until the next push reassigns them) and vanishes
    // abruptly when the next animation starts, which reads as a flicker.
    // Fade opacity to 0 over the last 20% so the page is fully gone before
    // it's edge-on.
    final endFade = value < 0.8 ? 1.0 : 1.0 - (value - 0.8) / 0.2;

    return [
      // Slot 0 = OUTGOING (top): the page peeling off and flying away.
      // `ignorePointer: true` for the entire animation — hits should pass
      // through to the incoming layer underneath. After the transition
      // completes the outgoing widget is replaced with a `SizedBox.shrink`
      // placeholder anyway, so no real surface remains to receive hits.
      AnimationLayerEffect(
        transform: transform as Matrix4,
        opacity: endFade * (1.0 - midPeak * 0.10),
        imageFilter: blurX > 0.1
            ? ui.ImageFilter.blur(sigmaX: blurX, sigmaY: 0.4)
            : null,
        ignorePointer: true,
      ),
      // Slot 1 = INCOMING (bottom): the static page underneath. Dims hard
      // mid-turn (up to 65%) so the lifting page above reads as a bright
      // silhouette against a darkened reading surface. MUST remain hittable
      // so the user can interact with the new current page the moment the
      // animation ends.
      AnimationLayerEffect(
        colorFilter: midPeak > 0.05
            ? ColorFilter.mode(
                Color.fromRGBO(0, 0, 0, midPeak * 0.65),
                BlendMode.srcOver,
              )
            : null,
      ),
    ];
  }
}

// Backward page turn = the forward [PaperTurnEffect] animation played in
// REVERSE TIME. The INCOMING page (the route we're returning to) takes on
// the role the outgoing played in forward: it starts rotated +π/2 around
// the LEFT edge (edge-on, as if it had previously been flipped away) and
// un-rotates to flat by value=1. Same hinge as forward; same arc, just
// time-reversed.
//
// Because the visible-mover here is the INCOMING (not the previous route),
// `previousOnTop` stays at the default `false` — slot 0 holds the
// transformed incoming, slot 1 holds the static-but-dimmed outgoing.
class PaperTurnBackEffect extends AnimationEffect {
  const PaperTurnBackEffect()
      : super(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    // Delegate to the forward effect at the time-reversed progress, then
    // re-tag `ignorePointer` for the swapped slot roles. PaperTurnEffect
    // returns [transform-layer, dim-layer]; in forward those map to
    // [outgoing, incoming] (previousOnTop=true). Here they map to
    // [incoming, outgoing] (previousOnTop=false), so it's the *bottom*
    // slot that must ignore pointers — the outgoing is the page being
    // covered and shouldn't steal taps from the incoming once flat.
    final src = const PaperTurnEffect().data(context, size, 1.0 - value);
    return [
      AnimationLayerEffect(
        transform: src[0].transform,
        opacity: src[0].opacity,
        imageFilter: src[0].imageFilter,
        // No `ignorePointer` — the incoming is the new current page.
      ),
      AnimationLayerEffect(
        colorFilter: src[1].colorFilter,
        ignorePointer: true,
      ),
    ];
  }
}
