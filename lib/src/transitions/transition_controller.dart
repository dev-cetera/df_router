import 'dart:ui' show VoidCallback;

import 'package:flutter/widgets.dart' show protected;

class TransitionController {
  @protected
  VoidCallback? resetAnimation;

  void reset() {
    resetAnimation?.call();
  }

  void clear() {
    resetAnimation = null;
  }
}
