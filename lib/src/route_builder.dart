//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Configuration for a single route. Decoupled from the widget so the
// RouteController can inspect metadata (preservation, conditions) without
// needing to build the actual widget.
class RouteBuilder<TExtra extends Object?> {
  final RouteState<TExtra> routeState;
  // When true, the widget stays in the cache even after navigating away.
  // Use for screens with expensive state you want to preserve (e.g. scroll
  // position, form data, active streams).
  final bool shouldPreserve;
  // When true, the widget is built at controller construction time rather
  // than on first visit. Use for screens that need instant display without
  // a build delay (e.g. the home screen).
  final bool shouldPrebuild;
  // Stored as the type-erased TRouteWidgetBuilder so the RouteController can
  // invoke it without knowing TExtra at call sites.
  late final TRouteWidgetBuilder builder;
  // Optional guard — when it returns false, navigation to this route is
  // blocked. Useful for auth checks or feature flags.
  final TRouteConditionFn? condition;

  RouteBuilder({
    required this.routeState,
    this.shouldPreserve = false,
    this.shouldPrebuild = false,
    required TRouteWidgetBuilder<TExtra> builder,
    this.condition,
  }) {
    // Type-erase the builder so RouteController can call it generically.
    // The cast inside recovers the TExtra type at invocation time.
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
      builder:
          builder ??
          (context, state) =>
              this.builder(context, state) as RouteWidgetMixin<TExtra>,
      condition: condition ?? this.condition,
    );
  }

  RouteBuilder<TExtra> copyWithout({
    bool shouldPreserve = true,
    bool shouldPrebuild = true,
    bool condition = true,
  }) {
    return RouteBuilder<TExtra>(
      routeState: routeState,
      shouldPreserve: shouldPreserve ? false : this.shouldPreserve,
      shouldPrebuild: shouldPrebuild ? false : this.shouldPrebuild,
      builder: (context, state) =>
          builder(context, state) as RouteWidgetMixin<TExtra>,
      condition: condition ? null : this.condition,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TRouteConditionFn = bool Function();

typedef TRouteWidgetBuilder<TExtra extends Object?> =
    RouteWidgetMixin<TExtra> Function(
      BuildContext context,
      RouteState<TExtra?> routeState,
    );
