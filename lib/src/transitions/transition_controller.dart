import 'dart:ui' show VoidCallback;

import 'package:flutter/widgets.dart' show protected;

class TransitionController {
  @protected
  VoidCallback? resetAnimation;

  @protected
  VoidCallback? endAnimation;

  void reset() {
    resetAnimation?.call();
  }

  void end() {
    endAnimation?.call();
  }

  void clear() {
    resetAnimation = null;
    endAnimation = null;
  }
}
