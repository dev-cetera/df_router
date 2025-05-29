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

  late final ValueNotifier<RouteState> _pState;
  ValueListenable<RouteState> get pState => _pState;
  RouteState get state => _pState.value;

  var _widgetCache = <RouteState, Widget>{};
  late final List<RouteBuilder> builders;
  final bool shouldCapture;
  final TRouteTransitionBuilder transitionBuilder;

  Picture? _picture;
  BuildContext? _captureContext;
  RouteState? _prevState;
  final _controller = TransitionController();
  final RouteState<Enum> Function()? errorState;

  //
  //
  //

  RouteController({
    RouteState? initialState,
    this.errorState,
    required RouteState fallbackState,
    required this.builders,
    this.shouldCapture = true,
    required this.transitionBuilder,
  }) {
    final state = initialState ?? _navigatorState ?? fallbackState;
    _pState = ValueNotifier<RouteState>(state);
    platformNavigator.addStateCallback(_onStateChange);
    platformNavigator.pushState(state.uri);
    _widgetCache = Map.fromEntries(
      builders.where((state) => state.shouldPrebuild).map((e) {
        final uri = e.routeState.uri;
        final state = RouteState(uri);
        return MapEntry(
          RouteState(uri),
          Builder(
            builder: (context) {
              return e.builder(context, state);
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
    _pState.value = RouteState(uri);
  }

  //
  //
  //

  Widget _pictureWidget(BuildContext context) {
    if (_picture == null) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return PictureWidget(picture: _picture, size: size);
      },
    );
  }

  //
  //
  //

  void _maybeCapture() {
    if (shouldCapture) {
      _picture = captureWidgetPicture(_captureContext!);
    }
  }

  //
  //
  //

  void pushBack() {
    if (_prevState != null) {
      final uri = _prevState!.uri;
      push(uri.path, queryParameters: uri.queryParameters, shouldAnimate: false);
    }
  }

  //
  //
  //

  void setState<TExtra extends Object?>(RouteState<TExtra> state) {
    clearCache();
    pushState(state);
  }

  //
  //
  //

  void pushState<TExtra extends Object?>(RouteState<TExtra> state) {
    push<TExtra>(
      state.uri.path,
      queryParameters: state.uri.queryParameters,
      extra: state.extra,
      skipCurrent: state.skipCurrent,
      shouldAnimate: state.shouldAnimate,
      condition: state.condition,
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
    if (skipCurrent && _pState.value.uri == uri) {
      return;
    }
    if (_checkExtraTypeMismatch<TExtra>(uri) == false) {
      if (errorState != null) {
        push(
          errorState!().uri.path,
          queryParameters: RouteStateControllerErrorType.EXTRA_TYPE_MISMATCH.toQueryParameters(),
          extra: RouteStateControllerErrorType.EXTRA_TYPE_MISMATCH,
        );
      }
      throw ExtraTypeMismatchError<TExtra>(uri: uri);
    }
    if (!pathExists(uri)) {
      if (errorState != null) {
        push(
          errorState!().uri.path,
          queryParameters: RouteStateControllerErrorType.RouteState_NOT_FOUND.toQueryParameters(),
          extra: RouteStateControllerErrorType.RouteState_NOT_FOUND,
        );
      }
      throw RouteStateNotFoundError(uri: uri);
    }
    // Condition 1.
    final a = condition == null || condition();
    if (!a) {
      if (errorState != null) {
        push(
          errorState!().uri.path,
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
      if (errorState != null) {
        push(
          errorState!().uri.path,
          queryParameters: RouteStateControllerErrorType.CONDITION_NOT_MET.toQueryParameters(),
          extra: RouteStateControllerErrorType.CONDITION_NOT_MET,
        );
      }
      throw CondtionNotMetError(uri: uri);
    }
    _maybeCapture();
    platformNavigator.pushState(uri);
    _prevState = _pState.value;
    _pState.value = RouteState(uri, extra: extra);
    _cleanUpState(_prevState);
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
    return builders.any(
      (e) => e.routeState.path == path.path && e.runtimeType == RouteBuilder<TExtra>,
    );
  }

  //
  //
  //

  RouteBuilder? _getBuilderByPath(Uri path) {
    return builders.where((state) => state.routeState.path == path.path).firstOrNull;
  }

  //
  //
  //

  Widget? disposeState(RouteState state) {
    return _widgetCache.remove(state);
  }

  //
  //
  //

  void disposePath(Uri path) {
    _widgetCache.removeWhere((state, widget) => state.uri.path == path.path);
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

  void _cleanUpState(RouteState? state) {
    if (state == null) return;
    final a = builders.where((e) => e.routeState.path == state.uri.path).firstOrNull;
    if (a == null) return;
    if (a.shouldPrebuild && !a.shouldPreserve) {
      // Replace with empty widget instead of removing it to avoid rebuilds.
      _widgetCache[state] = const SizedBox.shrink();
    }
  }

  //
  //
  //

  Widget buildScreen(BuildContext context, RouteState state) {
    var config = builders.where((e) => e.routeState.path == state.uri.path).firstOrNull;
    if (config == null) {
      return const SizedBox.shrink();
    }
    if (errorState != null) {
      config = builders.where((e) => e.routeState.path == errorState?.call().uri.path).firstOrNull;
    }
    if (config == null) {
      return const SizedBox.shrink();
    }
    _widgetCache[state] = Builder(builder: (context) => config!.builder(context, state));
    return transitionBuilder(
      context,
      RouteTransitionBuilderParams(
        controller: _controller,
        prevState: _prevState,
        state: state,
        prev: _pictureWidget(context),
        child: Builder(
          builder: (context) {
            _captureContext = context;
            return RepaintBoundary(
              child: Builder(
                builder: (context) {
                  return IndexedStack(
                    index: _widgetCache.keys.toList().indexOf(state),
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
    _pState.dispose();
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
