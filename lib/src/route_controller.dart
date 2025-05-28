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

  late final ValueNotifier<Uri> _pState;
  ValueListenable<Uri> get pState => _pState;
  Uri get state => _pState.value;

  var _widgetCache = <Uri, Widget>{};
  late final List<RouteBuilder> routeBuilders;
  final bool enablePrevsCapturing;
  final TTransitionBuilder transitionBuilder;

  Picture? _picture;
  BuildContext? _captureContext;
  Uri? _prevState;
  final _controller = TransitionController();
  final Uri? errorStte;

  //
  //
  //

  RouteController({
    Uri? initialState,
    this.errorStte,
    required Uri fallbackState,
    required this.routeBuilders,
    this.enablePrevsCapturing = true,
    required this.transitionBuilder,
  }) {
    final state = initialState ?? _navigatorState ?? fallbackState;
    _pState = ValueNotifier<Uri>(state);
    platformNavigator.addStateCallback(_onStateChange);
    print(state);
    platformNavigator.pushState(state);
    _widgetCache = Map.fromEntries(
      routeBuilders.where((route) => route.shouldPrebuild).map((e) {
        final state = Uri.parse(e.path);
        return MapEntry(
          state,
          Builder(
            builder: (context) {
              return e.builder(context, _pictureWidget(context), state);
            },
          ),
        );
      }),
    );
  }

  //
  //
  //

  Uri? get _navigatorState {
    final pathQuery = platformNavigator.getCurrentUrl()?.pathQuery;
    if (pathQuery == null || pathQuery == '/' || pathQuery.isEmpty) {
      return null;
    }
    return Uri.tryParse(pathQuery);
  }

  //
  //
  //

  void _onStateChange(Uri state) {
    _pState.value = state;
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
    if (enablePrevsCapturing) {
      _picture = captureWidgetPicture(_captureContext!);
    }
  }

  //
  //
  //

  void pushAgain(Uri state, {bool shouldAnimate = false}) {
    disposeState(state);
    push(state, shouldAnimate: shouldAnimate);
  }

  //
  //
  //

  void pushBack() {
    if (_prevState != null) {
      push(_prevState!, shouldAnimate: false);
    }
  }

  //
  //
  //

  void push(
    Uri route, {
    bool skipCurrent = true,
    bool shouldAnimate = false,
    Map<String, String>? queryParams,
  }) {
    if (skipCurrent && _pState.value == route) {
      return;
    }
    if (!pathExists(route) || !(_getBuilderByPath(route)?.condition?.call() != false)) {
      if (errorStte != null) {
        push(errorStte!);
      }
      return;
    }
    _maybeCapture();
    platformNavigator.pushState(route);
    _prevState = _pState.value;
    _pState.value = route;
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
    return routeBuilders.any((e) => e.path == path.path);
  }

  //
  //
  //

  RouteBuilder? _getBuilderByPath(Uri path) {
    return routeBuilders.where((route) => route.path == path.path).firstOrNull;
  }

  //
  //
  //

  void disposeState(Uri state) {
    _widgetCache.remove(state);
  }

  //
  //
  //

  void disposePath(Uri path) {
    _widgetCache.removeWhere((key, _) => key.path == path.path);
  }

  //
  //
  //

  void clear() {
    _widgetCache.clear();
  }

  //
  //
  //

  void _cleanUpState(Uri? state) {
    if (state == null) return;
    final a = routeBuilders.where((e) => e.path == state.path).firstOrNull;
    if (a == null) return;
    if (a.shouldPrebuild && !a.shouldPreserve) {
      // Replace with empty widget instead of removing it to avoid rebuilds.
      _widgetCache[state] = const SizedBox.shrink();
    }
  }

  //
  //
  //

  Widget buildScreen(BuildContext context, Uri state) {
    var config = routeBuilders.where((e) => e.path == state.path).firstOrNull;
    if (config == null) {
      return const SizedBox.shrink();
    }
    if (errorStte != null) {
      config = routeBuilders.where((e) => e.path == errorStte?.path).firstOrNull;
    }
    if (config == null) {
      return const SizedBox.shrink();
    }
    _widgetCache[state] = Builder(
      builder: (context) => config!.builder(context, _pictureWidget(context), state),
    );
    return transitionBuilder(
      context,
      TransitionBuilderParams(
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
                          final fullRoute = entry.key;
                          final widget = entry.value;
                          return KeyedSubtree(key: ValueKey(fullRoute), child: widget);
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
      throw FlutterError('No RouteControllerProvider found in context');
    }
    return provider.controller;
  }
}
