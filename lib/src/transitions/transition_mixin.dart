import 'package:flutter/material.dart';

import 'transition_controller.dart';

mixin TransitionMixin on StatefulWidget {
  Widget? get prev;
  Widget get child;
  Duration get duration;
  TransitionController get controller;
}
