import 'package:flutter/widgets.dart';

import '_src.g.dart';

mixin RouteWidgetMixin<TExtra extends Object?> on Widget {
  RouteState<TExtra?>? get state;
}
