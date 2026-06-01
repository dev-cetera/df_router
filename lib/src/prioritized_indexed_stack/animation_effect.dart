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

// Abstract contract for route transition animations. Each effect produces
// a list of AnimationLayerEffects (one per layer in PrioritizedIndexedStack)
// given the current interpolation value. This separation lets the animation
// system drive the controller while effects are pure functions of (context,
// size, value) → visual transforms — easy to test and compose.
abstract class AnimationEffect {
  final Duration duration;
  final Curve curve;

  const AnimationEffect({required this.duration, required this.curve});

  // Called every animation frame during a transition (60–120 Hz). Implementors
  // should return a fresh list each call — the framework does not require
  // identity, only correct values.
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  );

  /// When `true`, the router renders the OUTGOING route in the top slot
  /// (slot 0) and the INCOMING route underneath (slot 1). Use this for
  /// effects where the previous page does the visible movement — e.g. a
  /// physical page peeling off the surface and flying away to reveal what
  /// was behind it. Default `false`: incoming on top, previous behind.
  ///
  /// Regardless of this flag, the effect's `data()` should always describe
  /// layers in slot order (`data[0]` for the top slot, `data[1]` for the
  /// bottom slot), so the same list shape works for both conventions — the
  /// flag only changes which route occupies each slot.
  bool get previousOnTop => false;
}
