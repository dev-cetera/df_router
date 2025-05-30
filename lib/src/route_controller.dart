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

import 'package:df_pwa_utils/df_pwa_utils.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RouteController {
  //
  //
  //

  late final ValueNotifier<RouteState> _pRouteState;
  ValueListenable<RouteState> get pRouteState => _pRouteState;
  RouteState get routeState => _pRouteState.value;

  var _widgetCache = <RouteState, Widget>{};
  late final List<RouteBuilder> builders;
  final bool shouldCapture;
  final TRouteTransitionBuilder transitionBuilder;

  Picture? _prevSnapshotPicture;
  BuildContext? _captureContext;
  RouteState? _prevRouteState;
  final _controller = TransitionController();
  final RouteState<Enum> Function()? errorRouteState;

  //
  //
  //

  RouteController({
    RouteState? initialRouteState,
    this.errorRouteState,
    required RouteState fallbackRouteState,
    required this.builders,
    this.shouldCapture = true,
    required this.transitionBuilder,
  }) {
    final routeState = initialRouteState ?? _navigatorState ?? fallbackRouteState;
    _pRouteState = ValueNotifier<RouteState>(routeState);
    platformNavigator.addStateCallback(_onStateChange);
    platformNavigator.pushState(routeState.uri);
    _widgetCache = Map.fromEntries(
      builders.where((routeState) => routeState.shouldPrebuild).map((e) {
        final uri = e.routeState.uri;
        final routeState = RouteState(uri);
        return MapEntry(
          RouteState(uri),
          Builder(
            builder: (context) {
              return e.builder(context, routeState);
            },
          ),
        );
      }),
    );
  }

  //
  //
  //

  RouteState? get _navigatorState {
    final pathQuery = platformNavigator.getCurrentUrl()?.pathAndQuery;
    if (pathQuery == null || pathQuery == '/' || pathQuery.isEmpty) {
      return null;
    }
    return RouteState(Uri.parse(pathQuery));
  }

  //
  //
  //

  void _onStateChange(Uri uri) {
    _pRouteState.value = RouteState(uri);
  }

  //
  //
  //

  Widget _pictureWidget(BuildContext context) {
    if (_prevSnapshotPicture == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return PictureWidget(picture: _prevSnapshotPicture, size: size);
      },
    );
  }

  //
  //
  //

  void _maybeCapture() {
    if (shouldCapture) {
      _prevSnapshotPicture = captureWidgetPicture(_captureContext!);
    }
  }

  //
  //
  //

  void pushBack() {
    if (_prevRouteState != null) {
      final uri = _prevRouteState!.uri;
      push(uri.path, queryParameters: uri.queryParameters, shouldAnimate: false);
    }
  }

  //
  //
  //

  void setState<TExtra extends Object?>(RouteState<TExtra> routeState) {
    clearCache();
    pushState(routeState);
  }

  //
  //
  //

  void pushState<TExtra extends Object?>(RouteState<TExtra> routeState) {
    push<TExtra>(
      routeState.uri.path,
      queryParameters: routeState.uri.queryParameters,
      extra: routeState.extra,
      skipCurrent: routeState.skipCurrent,
      shouldAnimate: routeState.shouldAnimate,
      condition: routeState.condition,
    );
  }

  //
  //
  //

  void push<TExtra extends Object?>(
    String path, {
    Map<String, String>? queryParameters,
    TExtra? extra,
    bool skipCurrent = true,
    bool shouldAnimate = false,
    TRouteConditionFn? condition,
  }) {
    var uri = Uri.parse(path);
    final qp = {...uri.queryParameters, ...?queryParameters};
    uri = uri.replace(queryParameters: qp.isNotEmpty ? qp : null);
    if (skipCurrent && _pRouteState.value.uri == uri) {
      return;
    }
    if (_checkExtraTypeMismatch<TExtra>(uri) == false) {
      if (errorRouteState != null) {
        push(
          errorRouteState!().uri.path,
          queryParameters: RouteStateControllerErrorType.EXTRA_TYPE_MISMATCH.toQueryParameters(),
          extra: RouteStateControllerErrorType.EXTRA_TYPE_MISMATCH,
        );
      }
      throw ExtraTypeMismatchError<TExtra>(uri: uri);
    }
    if (!pathExists(uri)) {
      if (errorRouteState != null) {
        push(
          errorRouteState!().uri.path,
          queryParameters: RouteStateControllerErrorType.RouteState_NOT_FOUND.toQueryParameters(),
          extra: RouteStateControllerErrorType.RouteState_NOT_FOUND,
        );
      }
      throw RouteStateNotFoundError(uri: uri);
    }
    // Condition 1.
    final a = condition == null || condition();
    if (!a) {
      if (errorRouteState != null) {
        push(
          errorRouteState!().uri.path,
          queryParameters: RouteStateControllerErrorType.CONDITION_NOT_MET.toQueryParameters(),
          extra: RouteStateControllerErrorType.CONDITION_NOT_MET,
        );
      }
      throw CondtionNotMetError(uri: uri);
    }
    // Ccndition 2.
    final condition2 = _getBuilderByPath(uri)?.condition;
    final b = condition2 == null || condition2.call();
    if (!b) {
      if (errorRouteState != null) {
        push(
          errorRouteState!().uri.path,
          queryParameters: RouteStateControllerErrorType.CONDITION_NOT_MET.toQueryParameters(),
          extra: RouteStateControllerErrorType.CONDITION_NOT_MET,
        );
      }
      throw CondtionNotMetError(uri: uri);
    }
    _maybeCapture();
    platformNavigator.pushState(uri);
    _prevRouteState = _pRouteState.value;
    _pRouteState.value = RouteState(uri, extra: extra);
    _cleanUpState(_prevRouteState);
    if (shouldAnimate) {
      Future.microtask(() {
        _controller.reset();
      });
    }
  }

  //
  //
  //

  bool pathExists(Uri path) {
    return builders.any((e) => e.routeState.path == path.path);
  }

  //
  //
  //

  bool _checkExtraTypeMismatch<TExtra extends Object?>(Uri path) {
    return builders.any((e) {
      return e.routeState.path == path.path && e is RouteBuilder<TExtra>;
    });
  }

  //
  //
  //

  RouteBuilder? _getBuilderByPath(Uri path) {
    return builders.where((routeState) => routeState.routeState.path == path.path).firstOrNull;
  }

  //
  //
  //

  Widget? disposeState(RouteState routeState) {
    return _widgetCache.remove(routeState);
  }

  //
  //
  //

  void disposePath(Uri path) {
    _widgetCache.removeWhere((routeState, widget) => routeState.uri.path == path.path);
  }

  //
  //
  //

  void clearCache() {
    _widgetCache.clear();
  }

  //
  //
  //

  void _cleanUpState(RouteState? routeState) {
    if (routeState == null) return;
    final a = builders.where((e) => e.routeState.path == routeState.uri.path).firstOrNull;
    if (a == null) return;
    if (a.shouldPrebuild && !a.shouldPreserve) {
      // Replace with empty widget instead of removing it to avoid rebuilds.
      _widgetCache[routeState] = const SizedBox.shrink();
    }
  }

  //
  //
  //

  Widget buildScreen(BuildContext context, RouteState routeState) {
    var config = builders.where((e) => e.routeState.path == routeState.uri.path).firstOrNull;
    if (config == null) {
      return const SizedBox.shrink();
    }
    if (errorRouteState != null) {
      config =
          builders.where((e) => e.routeState.path == errorRouteState?.call().uri.path).firstOrNull;
    }
    if (config == null) {
      return const SizedBox.shrink();
    }
    _widgetCache[routeState] = Builder(builder: (context) => config!.builder(context, routeState));
    return transitionBuilder(
      context,
      RouteTransitionBuilderParams(
        controller: _controller,
        prevRouteState: _prevRouteState,
        routeState: routeState,
        prevSnapshot: _pictureWidget(context),
        child: Builder(
          builder: (context) {
            _captureContext = context;
            return RepaintBoundary(
              child: Builder(
                builder: (context) {
                  return IndexedStack(
                    index: _widgetCache.keys.toList().indexOf(routeState),
                    children:
                        _widgetCache.entries.map((entry) {
                          final fullRouteState = entry.key;
                          final widget = entry.value;
                          return KeyedSubtree(key: ValueKey(fullRouteState), child: widget);
                        }).toList(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  //
  //
  //

  void dispose() {
    platformNavigator.removeStateCallback(_onStateChange);
    _pRouteState.dispose();
    _widgetCache.clear();
    _controller.clear();
  }

  //
  //
  //

  static RouteController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<RouteControllerProvider>();
    if (provider == null) {
      throw FlutterError('No RouteStateControllerProvider found in context');
    }
    return provider.controller;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

enum RouteStateControllerErrorType {
  CONDITION_NOT_MET,
  RouteState_NOT_FOUND,
  EXTRA_TYPE_MISMATCH;

  const RouteStateControllerErrorType();

  Map<String, String> toQueryParameters() {
    return {'error': name};
  }
}

abstract class RouteStateControllerError {
  const RouteStateControllerError();
}

class CondtionNotMetError extends RouteStateControllerError {
  final Uri uri;
  const CondtionNotMetError({required this.uri});

  @override
  String toString() {
    return '[CondtionNotMetError] "condition" not met for RouteState $uri!';
  }
}

class RouteStateNotFoundError extends RouteStateControllerError {
  final Uri uri;
  const RouteStateNotFoundError({required this.uri});

  @override
  String toString() {
    return '[RouteStateNotFoundError] RouteState not found: "$uri".';
  }
}

class ExtraTypeMismatchError<TExtra extends Object?> extends RouteStateControllerError {
  final Uri uri;
  const ExtraTypeMismatchError({required this.uri});

  @override
  String toString() {
    return '[ExtraTypeMismatchError] "extra" is not of expected type "$TExtra" for RouteState $uri.';
  }
}
