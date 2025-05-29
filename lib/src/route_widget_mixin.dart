import 'package:flutter/widgets.dart';

import '_src.g.dart';

mixin RouteWidgetMixin<TExtra extends Object?> on Widget {
  RouteState<TExtra?>? get routeState;
}

class RouteWidgetBuilder<TExtra extends Object?> extends StatelessWidget
    with RouteWidgetMixin<TExtra> {
  @override
  final RouteState<TExtra?>? routeState;
  final Widget Function(BuildContext context, RouteState<TExtra?>? state) builder;

  const RouteWidgetBuilder({super.key, this.routeState, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, routeState);
  }
}
