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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteState<TExtra extends Object?> extends Equatable {
  late final Uri uri;
  final TExtra? extra;
  final bool skipCurrent;
  final bool shouldAnimate;

  RouteState(
    Uri uri, {
    Map<String, String>? queryParameters,
    this.extra,
    this.skipCurrent = true,
    this.shouldAnimate = false,
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
  }) {
    return RouteState<TExtra>(
      uri ?? this.uri,
      queryParameters: queryParameters,
      extra: extra ?? this.extra,
      skipCurrent: skipCurrent ?? this.skipCurrent,
      shouldAnimate: shouldAnimate ?? this.shouldAnimate,
    );
  }

  RouteState<TExtra> copyWithout({
    bool uri = false,
    bool queryParameters = false,
    bool extra = false,
    bool skipCurrent = false,
    bool shouldAnimate = false,
  }) {
    return RouteState<TExtra>(
      uri ? Uri() : this.uri,
      queryParameters: queryParameters ? null : this.uri.queryParameters,
      extra: extra ? null : this.extra,
      skipCurrent: skipCurrent ? true : this.skipCurrent,
      shouldAnimate: shouldAnimate ? false : this.shouldAnimate,
    );
  }

  RouteState<X?> cast<X extends Object?>() =>
      RouteState<X?>(uri, extra: extra as X?);

  bool matchPath(RouteState other) => uri.path == other.uri.path;

  String get path => uri.path;

  @override
  List<Object?> get props => [uri]; // extra is not included in equality check.
}
