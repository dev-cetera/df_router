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

import 'package:equatable/equatable.dart';

import '../df_router.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteState<TExtra extends Object?> extends Equatable {
  late final Uri uri;
  final TExtra? extra;
  final bool skipCurrent;
  final bool shouldAnimate;
  final TRouteConditionFn? condition;

  RouteState(
    Uri uri, {
    Map<String, String>? queryParameters,
    this.extra,
    this.skipCurrent = true,
    this.shouldAnimate = false,
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
    this.shouldAnimate = false,
    this.condition,
  }) {
    final uri0 = Uri.parse(pathAndQuery);
    final qp = {...uri0.queryParameters, ...?queryParameters};
    this.uri = uri0.replace(queryParameters: qp.isNotEmpty ? qp : null);
  }

  RouteState<TExtra> copyWith({
    Uri? uri,
    Map<String, String>? queryParameters,
    TExtra? extra,
    bool? skipCurrent,
    bool? shouldAnimate,
    TRouteConditionFn? condiiton,
  }) {
    return RouteState<TExtra>(
      uri ?? this.uri,
      queryParameters: queryParameters,
      extra: extra ?? this.extra,
      skipCurrent: skipCurrent ?? this.skipCurrent,
      shouldAnimate: shouldAnimate ?? this.shouldAnimate,
      condition: condition ?? this.condition,
    );
  }

  RouteState<TExtra> copyWithout({
    bool uri = true,
    bool queryParameters = true,
    bool extra = true,
    bool skipCurrent = true,
    bool shouldAnimate = true,
    bool condition = true,
  }) {
    return RouteState<TExtra>(
      uri ? this.uri : Uri(),
      queryParameters: queryParameters ? this.uri.queryParameters : null,
      extra: extra ? this.extra : null,
      skipCurrent: skipCurrent ? this.skipCurrent : true,
      shouldAnimate: shouldAnimate ? false : this.shouldAnimate,
      condition: condition ? this.condition : null,
    );
  }

  RouteState<X?> cast<X extends Object?>() => RouteState<X?>(uri, extra: extra as X?);

  bool matchPath(RouteState other) => uri.path == other.uri.path;

  String get path => uri.path;

  @override
  List<Object?> get props => [uri]; // extra is not included in equality check.
}
