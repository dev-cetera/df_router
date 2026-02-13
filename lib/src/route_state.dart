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

import 'package:df_safer_dart/_common.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Immutable description of a navigation destination. Extends Equatable so
// two RouteStates with the same URI and extra data are considered equal —
// this is critical for the widget cache lookup in RouteController.
class RouteState<TExtra extends Object?> extends Equatable {
  late final Uri uri;
  // Type-safe payload for passing data between routes without serialization.
  // Not included in URL — only lives in memory.
  final TExtra? extra;
  // Prevents accidental double-navigation when the user taps rapidly.
  // Defaults to true because double-pushing the same route is almost never
  // intentional.
  final bool skipCurrent;
  // Default animation when this route is pushed. Can be overridden per-push
  // via the animationEffect parameter on push().
  final AnimationEffect animationEffect;
  // Per-route guard. When it returns false, push() silently rejects the
  // navigation. Separate from RouteBuilder.condition because this one
  // travels with the RouteState instance and can vary per-push.
  final TRouteConditionFn? condition;
  // When true, the route's widget survives navigation (kept in cache).
  // This duplicates RouteBuilder.shouldPreserve intentionally — the builder
  // flag is a static config, while this flag can be set per-push for dynamic
  // preservation decisions.
  final bool shouldPreserve;

  // Uses URI string as the ValueKey so Flutter can reconcile widgets across
  // cache rebuilds without creating duplicate Elements.
  Key get key => ValueKey(uri.toString());

  RouteState(
    Uri uri, {
    Map<String, String>? queryParameters,
    this.extra,
    this.skipCurrent = true,
    this.animationEffect = const NoEffect(),
    this.condition,
    this.shouldPreserve = false,
  }) {
    final qp = {...uri.queryParameters, ...?queryParameters};
    this.uri = uri.replace(queryParameters: qp.isNotEmpty ? qp : null);
  }

  RouteState.parse(
    String pathAndQuery, {
    Map<String, String>? queryParameters,
    this.extra,
    this.skipCurrent = true,
    this.animationEffect = const NoEffect(),
    this.condition,
    this.shouldPreserve = false,
  }) {
    final uri0 = Uri.parse(pathAndQuery);
    final qp = {...uri0.queryParameters, ...?queryParameters};
    uri = uri0.replace(queryParameters: qp.isNotEmpty ? qp : null);
  }

  RouteState<TExtra> copyWith({
    Uri? uri,
    Map<String, String>? queryParameters,
    TExtra? extra,
    bool? skipCurrent,
    AnimationEffect? animationEffect,
    TRouteConditionFn? condition,
    bool? shouldPreserve,
  }) {
    return RouteState<TExtra>(
      uri ?? this.uri,
      queryParameters: queryParameters,
      extra: extra ?? this.extra,
      skipCurrent: skipCurrent ?? this.skipCurrent,
      animationEffect: animationEffect ?? this.animationEffect,
      condition: condition ?? this.condition,
      shouldPreserve: shouldPreserve ?? this.shouldPreserve,
    );
  }

  RouteState<TExtra> copyWithout({
    bool uri = true,
    bool queryParameters = true,
    bool extra = true,
    bool skipCurrent = true,
    bool animationEffect = true,
    bool condition = true,
    bool shouldPreserve = true,
  }) {
    return RouteState<TExtra>(
      uri ? this.uri : Uri(),
      queryParameters: queryParameters ? this.uri.queryParameters : null,
      extra: extra ? this.extra : null,
      skipCurrent: skipCurrent ? this.skipCurrent : true,
      animationEffect: animationEffect
          ? const NoEffect()
          : this.animationEffect,
      condition: condition ? this.condition : null,
      shouldPreserve: shouldPreserve ? this.shouldPreserve : false,
    );
  }

  RouteState<X?> cast<X extends Object?>() =>
      RouteState<X?>(uri, extra: extra as X?);

  bool matchPath(RouteState other) => uri.path == other.uri.path;

  @override
  List<Object?> get props => [uri, extra];
}
