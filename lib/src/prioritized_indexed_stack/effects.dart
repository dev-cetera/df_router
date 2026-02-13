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

class NoEffect extends AnimationEffect {
  const NoEffect() : super(duration: Duration.zero, curve: Curves.linear);

  @override
  get data {
    return (context, size, value) {
      return const [AnimationLayerEffect(), AnimationLayerEffect()];
    };
  }
}

class FadeEffectWeb extends AnimationEffect {
  const FadeEffectWeb()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeOutSine,
      );

  @override
  get data {
    return (context, size, value) {
      return [
        AnimationLayerEffect(opacity: value),
        // Web version is simple for performance reasons.
        if (kIsWeb)
          const AnimationLayerEffect(ignorePointer: true)
        else
          AnimationLayerEffect(opacity: 1.0 - value * 0.5, ignorePointer: true),
      ];
    };
  }
}

class FadeEffect extends AnimationEffect {
  const FadeEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeOutSine,
      );

  @override
  get data {
    return (context, size, value) {
      return [
        AnimationLayerEffect(opacity: value),
        AnimationLayerEffect(opacity: 1.0 - value * 0.5, ignorePointer: true),
      ];
    };
  }
}

class BackwardEffectWeb extends AnimationEffect {
  const BackwardEffectWeb()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuint,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class BackwardEffect extends AnimationEffect {
  const BackwardEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuint,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class ForwardEffectWeb extends AnimationEffect {
  const ForwardEffectWeb()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuint,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class ForwardEffect extends AnimationEffect {
  const ForwardEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuint,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class SlideUpEffect extends AnimationEffect {
  const SlideUpEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuart,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class SlideDownEffect extends AnimationEffect {
  const SlideDownEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.easeInOutQuart,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class CupertinoEffect extends AnimationEffect {
  const CupertinoEffect()
    : super(
        duration: const Duration(milliseconds: 410),
        curve: Curves.easeInOut,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
  }
}

class MaterialEffect extends AnimationEffect {
  const MaterialEffect()
    : super(
        duration: const Duration(milliseconds: 275),
        curve: Curves.fastOutSlowIn,
      );

  @override
  get data {
    return (context, size, value) {
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
    };
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
  get data {
    return (context, size, value) {
      // value goes 0 → 1. At 0 the page is fully "closed" (rotated -90° around
      // the left hinge). At 1 the page is fully "open" (flat, facing the user).
      final angle = (1.0 - value) * (-3.14159 / 2.0);

      // Perspective distortion makes the far edge appear smaller, selling the
      // 3D illusion of a page turning. The 0.003 entry approximates a camera
      // distance that looks natural for typical screen widths.
      final perspective = Matrix4.identity()..setEntry(3, 2, 0.003);
      final rotation = Matrix4.identity()..rotateY(angle);

      // The rotation is around the Y-axis at x=0, so the page naturally hinges
      // on its left edge. We combine perspective + rotation into one transform.
      final transform = perspective * rotation;

      return [
        AnimationLayerEffect(
          transform: transform as Matrix4,
          opacity: 0.3 + 0.7 * value,
        ),
        // The outgoing (background) page dims slightly to create depth.
        AnimationLayerEffect(opacity: 1.0 - value * 0.3, ignorePointer: true),
      ];
    };
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
  get data {
    return (context, size, value) {
      // value goes 0 → 1. At 0 the page is rotated 90° around the right hinge.
      // At 1 the page is fully open (flat, facing the user).
      final angle = (1.0 - value) * (3.14159 / 2.0);

      final perspective = Matrix4.identity()..setEntry(3, 2, 0.003);
      final rotation = Matrix4.identity()..rotateY(angle);

      // Translate to right edge, rotate, then translate back — this makes the
      // page hinge on its right edge instead of the left.
      final hinge =
          Matrix4.translationValues(size.width, 0.0, 0.0) *
          rotation *
          Matrix4.translationValues(-size.width, 0.0, 0.0);

      final transform = perspective * hinge;

      return [
        AnimationLayerEffect(
          transform: transform as Matrix4,
          opacity: 0.3 + 0.7 * value,
        ),
        AnimationLayerEffect(opacity: 1.0 - value * 0.3, ignorePointer: true),
      ];
    };
  }
}
