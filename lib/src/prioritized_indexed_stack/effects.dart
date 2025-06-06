//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeOutSine);

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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeOutSine);

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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuint);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(-size.width + w, 0.0, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuint);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(-size.width + w, 0.0, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuint);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(size.width - w, 0.0, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuint);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(size.width - w, 0.0, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuart);

  @override
  get data {
    return (context, size, value) {
      final h = size.height * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(0.0, size.height - h, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInOutQuart);

  @override
  get data {
    return (context, size, value) {
      final h = size.height * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(0.0, -size.height + h, 0.0)),
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
    : super(duration: const Duration(milliseconds: 410), curve: Curves.easeInOut);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(size.width - w, 0.0, 0.0)),
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
    : super(duration: const Duration(milliseconds: 275), curve: Curves.fastOutSlowIn);

  @override
  get data {
    return (context, size, value) {
      final w = size.width * value;
      return [
        AnimationLayerEffect(transform: Matrix4.translationValues(size.width - w, 0.0, 0.0)),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(-w * 0.5, 0.0, 0.0),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class PageFlapDown extends AnimationEffect {
  const PageFlapDown()
    : super(duration: const Duration(milliseconds: 275), curve: Curves.easeInSine);

  @override
  get data {
    return (context, size, value) {
      return [
        AnimationLayerEffect(
          transform:
              Matrix4.translationValues(0.25 * (size.width - size.width * value), 0.0, 0.0) +
              Matrix4.skew((1 - value), -0.1 * (1 - value)) +
              Matrix4.rotationX((1 - value)),
        ),
        const AnimationLayerEffect(ignorePointer: true),
      ];
    };
  }
}
