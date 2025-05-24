import 'package:flutter/material.dart';

mixin ScreenTransitionMixin on StatefulWidget {
  Widget get prev;
  Widget get current;
  Duration get duration;
}
