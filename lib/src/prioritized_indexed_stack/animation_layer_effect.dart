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

import 'dart:ui' as ui;

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@immutable
class AnimationLayerEffect {
  final Matrix4? transform;
  final double? opacity;
  final ColorFilter? colorFilter;
  final ui.ImageFilter? imageFilter;
  final bool? ignorePointer;

  const AnimationLayerEffect({
    this.transform,
    this.opacity,
    this.colorFilter,
    this.imageFilter,
    this.ignorePointer,
  });

  bool get hasVisualEffects =>
      (opacity != null && opacity! < 1.0) ||
      colorFilter != null ||
      imageFilter != null;

  bool get isIdentity =>
      transform == null &&
      (opacity == null || opacity == 1.0) &&
      colorFilter == null &&
      imageFilter == null &&
      (ignorePointer == null || ignorePointer == false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationLayerEffect &&
        other.transform == transform &&
        other.opacity == opacity &&
        other.colorFilter == colorFilter &&
        other.imageFilter == imageFilter &&
        other.ignorePointer == ignorePointer;
  }

  @override
  int get hashCode =>
      Object.hash(transform, opacity, colorFilter, imageFilter, ignorePointer);
}
