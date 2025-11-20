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

class RouteState<TExtra extends Object?> {
  late final Uri uri;
  final TExtra? extra;
  final bool skipCurrent;
  final AnimationEffect animationEffect;
  final TRouteConditionFn? condition;

  Key get key => ValueKey(uri.toString());

  RouteState(
    Uri uri, {
    Map<String, String>? queryParameters,
    this.extra,
    this.skipCurrent = true,
    this.animationEffect = const NoEffect(),
    this.condition,
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
    TRouteConditionFn? condiiton,
  }) {
    return RouteState<TExtra>(
      uri ?? this.uri,
      queryParameters: queryParameters,
      extra: extra ?? this.extra,
      skipCurrent: skipCurrent ?? this.skipCurrent,
      animationEffect: animationEffect ?? this.animationEffect,
      condition: condition ?? condition,
    );
  }

  RouteState<TExtra> copyWithout({
    bool uri = true,
    bool queryParameters = true,
    bool extra = true,
    bool skipCurrent = true,
    bool animationEffect = true,
    bool condition = true,
  }) {
    return RouteState<TExtra>(
      uri ? this.uri : Uri(),
      queryParameters: queryParameters ? this.uri.queryParameters : null,
      extra: extra ? this.extra : null,
      skipCurrent: skipCurrent ? this.skipCurrent : true,
      animationEffect:
          animationEffect ? const NoEffect() : this.animationEffect,
      condition: condition ? this.condition : null,
    );
  }

  RouteState<X?> cast<X extends Object?>() =>
      RouteState<X?>(uri, extra: extra as X?);

  bool matchPath(RouteState other) => uri.path == other.uri.path;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteState) return false;
    return uri == other.uri && extra == other.extra;
  }

  String get path => uri.path;

  @override
  int get hashCode => (RouteState).hashCode ^ uri.hashCode;
}
