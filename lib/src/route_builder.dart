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

import '_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteBuilder<TExtra extends Object?> {
  final RouteState<TExtra> routeState;
  final bool shouldPreserve;
  final bool shouldPrebuild;
  late final TRouteWidgetBuilder builder;
  final TRouteConditionFn? condition;

  RouteBuilder({
    required this.routeState,
    this.shouldPreserve = false,
    this.shouldPrebuild = false,
    required TRouteWidgetBuilder<TExtra> builder,
    this.condition,
  }) {
    this.builder = (context, state) => builder(context, state.cast<TExtra>());
  }

  RouteBuilder<TExtra> copyWith({
    RouteState<TExtra>? routeState,
    bool? shouldPreserve,
    bool? shouldPrebuild,
    TRouteWidgetBuilder<TExtra>? builder,
    TRouteConditionFn? condition,
  }) {
    return RouteBuilder<TExtra>(
      routeState: routeState ?? this.routeState,
      shouldPreserve: shouldPreserve ?? this.shouldPreserve,
      shouldPrebuild: shouldPrebuild ?? this.shouldPrebuild,
      builder: builder ?? this.builder as TRouteWidgetBuilder<TExtra>,
      condition: condition ?? this.condition,
    );
  }

  RouteBuilder<TExtra> copyWithout({
    bool shouldPreserve = true,
    bool shouldPrebuild = true,
    bool condition = true,
  }) {
    return RouteBuilder<TExtra>(
      routeState: this.routeState,
      shouldPreserve: shouldPreserve ? false : this.shouldPreserve,
      shouldPrebuild: shouldPrebuild ? false : this.shouldPrebuild,
      builder: (context, state) => this.builder(context, state) as RouteWidgetMixin<TExtra>,
      condition: condition ? null : this.condition,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TRouteConditionFn = bool Function();

typedef TRouteWidgetBuilder<TExtra extends Object?> =
    RouteWidgetMixin<TExtra> Function(BuildContext context, RouteState<TExtra?> routeState);
