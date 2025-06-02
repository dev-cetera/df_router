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

import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class NoEffect extends AnimationEffect {
  const NoEffect() : super(duration: Duration.zero, curve: Curves.linear);

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      return const [AnimationLayerEffect(), AnimationLayerEffect()];
    };
  }
}

class FadeEffect extends AnimationEffect {
  const FadeEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeOutSine,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      return [
        AnimationLayerEffect(opacity: value),
        AnimationLayerEffect(opacity: 1.0 - value),
      ];
    };
  }
}

class QuickBackEffect extends AnimationEffect {
  const QuickBackEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuint,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      final width90 = size.width * 0.9;
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            -width90 + width90 * value,
            0.0,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(width90 * value * 0.5, 0.0, 0.0),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class QuickForwardEffect extends AnimationEffect {
  const QuickForwardEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuint,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      final width90 = size.width * 0.9;
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            width90 - width90 * value,
            0.0,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(
            -width90 * value * 0.5,
            0.0,
            0.0,
          ),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class SlideUpEffect extends AnimationEffect {
  const SlideUpEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuart,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            0.0,
            size.height - size.height * value,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(
            0.0,
            -size.height * value * 0.5,
            0.0,
          ),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class SlideDownEffect extends AnimationEffect {
  const SlideDownEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuart,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            0.0,
            -size.height + size.height * value,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(
            0.0,
            size.height * value * 0.5,
            0.0,
          ),
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
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            size.width - size.width * value,
            0.0,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(
            -size.width * value * 0.5,
            0.0,
            0.0,
          ),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class MaterialEffect extends AnimationEffect {
  const MaterialEffect()
    : super(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);
      return [
        AnimationLayerEffect(
          transform: Matrix4.translationValues(
            size.width - size.width * value,
            0.0,
            0.0,
          ),
        ),
        AnimationLayerEffect(
          opacity: 1.0 - value * 0.1,
          transform: Matrix4.translationValues(
            -size.width * value * 0.5,
            0.0,
            0.0,
          ),
          ignorePointer: true,
        ),
      ];
    };
  }
}

class PageFlapDown extends AnimationEffect {
  const PageFlapDown()
    : super(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInSine,
      );

  @override
  List<AnimationLayerEffect> Function(BuildContext context, double value)
  get data {
    return (context, value) {
      final size = MediaQuery.sizeOf(context);

      return [
        AnimationLayerEffect(
          transform:
              Matrix4.translationValues(
                0.25 * (size.width - size.width * value),
                0.0,
                0.0,
              ) +
              Matrix4.skew((1 - value), -0.1 * (1 - value)) +
              Matrix4.rotationX((1 - value)),
        ),
        const AnimationLayerEffect(ignorePointer: true),
      ];
    };
  }
}
