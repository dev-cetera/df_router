import 'package:flutter/material.dart';

import '../_src.g.dart';

class NoEffect extends AnimationEffect {
  NoEffect()
    : super(
        duration: Duration.zero,
        curve: Curves.linear,
        data: (context, value) {
          return const [AnimationLayerEffect(), AnimationLayerEffect()];
        },
      );
}

class FadeEffect extends AnimationEffect {
  FadeEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeOutSine,
        data: (context, value) {
          return [AnimationLayerEffect(opacity: value), AnimationLayerEffect(opacity: 1.0 - value)];
        },
      );
}

class QuickLeftToRightEffect extends AnimationEffect {
  QuickLeftToRightEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuint,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          final width90 = size.width * 0.9;
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(-width90 + width90 * value, 0.0, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(width90 * value * 0.5, 0.0, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}

class QuickRightToLeftEffect extends AnimationEffect {
  QuickRightToLeftEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuint,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          final width90 = size.width * 0.9;
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(width90 - width90 * value, 0.0, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(-width90 * value * 0.5, 0.0, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}

class BottomToTopEffect extends AnimationEffect {
  BottomToTopEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuart,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(0.0, size.height - size.height * value, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(0.0, -size.height * value * 0.5, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}

class TopToBottomEffect extends AnimationEffect {
  TopToBottomEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.easeInOutQuart,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(0.0, -size.height + size.height * value, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(0.0, size.height * value * 0.5, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}

class BounceOutEffect extends AnimationEffect {
  BounceOutEffect()
    : super(
        duration: const Duration(milliseconds: 375),
        curve: Curves.bounceOut,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(0.0, -size.height + size.height * value, 0.0),
            ),
            const AnimationLayerEffect(ignorePointer: true),
          ];
        },
      );
}

class CupertinoEffect extends AnimationEffect {
  CupertinoEffect()
    : super(
        duration: const Duration(milliseconds: 410),
        curve: Curves.easeInOut,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(size.width - size.width * value, 0.0, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(-size.width * value * 0.5, 0.0, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}

class MaterialEffect extends AnimationEffect {
  MaterialEffect()
    : super(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        data: (context, value) {
          final size = MediaQuery.sizeOf(context);
          return [
            AnimationLayerEffect(
              transform: Matrix4.translationValues(size.width - size.width * value, 0.0, 0.0),
            ),
            AnimationLayerEffect(
              opacity: 1.0 - value * 0.1,
              transform: Matrix4.translationValues(-size.width * value * 0.5, 0.0, 0.0),
              ignorePointer: true,
            ),
          ];
        },
      );
}
