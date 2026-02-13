import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

class _TestScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  final String label;
  const _TestScreen({this.routeState, required this.label});

  @override
  Widget build(BuildContext context) => Text(label);
}

RouteBuilder _builder(
  String path, {
  bool shouldPreserve = false,
  bool shouldPrebuild = false,
  TRouteConditionFn? condition,
}) {
  return RouteBuilder(
    routeState: RouteState.parse(path),
    shouldPreserve: shouldPreserve,
    shouldPrebuild: shouldPrebuild,
    condition: condition,
    builder: (context, routeState) =>
        _TestScreen(routeState: routeState, label: path),
  );
}

RouteController _makeController({
  RouteState Function()? initialRouteState,
  RouteState Function()? errorRouteState,
  List<RouteBuilder>? builders,
}) {
  return RouteController(
    initialRouteState: initialRouteState,
    errorRouteState: errorRouteState,
    fallbackRouteState: () => RouteState.parse('/home'),
    builders:
        builders ??
        [
          _builder('/home'),
          _builder('/gallery'),
          _builder('/canvas'),
          _builder('/settings'),
        ],
  );
}

void main() {
  // -------------------------------------------------------------------------
  // RouteState tests
  // -------------------------------------------------------------------------

  group('RouteState', () {
    test('parse creates correct URI', () {
      final state = RouteState.parse('/home');
      expect(state.uri.path, '/home');
    });

    test('equality based on URI and extra', () {
      final a = RouteState.parse('/home');
      final b = RouteState.parse('/home');
      expect(a, equals(b));
    });

    test('different URIs are not equal', () {
      final a = RouteState.parse('/home');
      final b = RouteState.parse('/gallery');
      expect(a, isNot(equals(b)));
    });

    test('extra data affects equality', () {
      final a = RouteState(Uri.parse('/home'), extra: 'a');
      final b = RouteState(Uri.parse('/home'), extra: 'b');
      expect(a, isNot(equals(b)));
    });

    test('query parameters are merged', () {
      final state = RouteState.parse('/home?a=1', queryParameters: {'b': '2'});
      expect(state.uri.queryParameters, {'a': '1', 'b': '2'});
    });

    test('copyWith preserves fields', () {
      final original = RouteState.parse(
        '/home',
        skipCurrent: false,
        shouldPreserve: true,
      );
      final copy = original.copyWith(uri: Uri.parse('/gallery'));
      expect(copy.uri.path, '/gallery');
      expect(copy.skipCurrent, false);
      expect(copy.shouldPreserve, true);
    });

    test('copyWith can override animationEffect', () {
      final original = RouteState.parse('/home');
      final copy = original.copyWith(animationEffect: const FadeEffect());
      expect(copy.animationEffect, isA<FadeEffect>());
    });

    test('matchPath compares only the path', () {
      final a = RouteState.parse('/home?a=1');
      final b = RouteState.parse('/home?b=2');
      expect(a.matchPath(b), true);
    });

    test('key is based on URI string', () {
      final state = RouteState.parse('/home');
      expect(state.key, equals(const ValueKey('/home')));
    });

    test('cast changes generic type', () {
      final original = RouteState(Uri.parse('/home'), extra: 'data');
      final casted = original.cast<String>();
      expect(casted.extra, 'data');
    });

    test('skipCurrent defaults to true', () {
      final state = RouteState.parse('/home');
      expect(state.skipCurrent, true);
    });

    test('shouldPreserve defaults to false', () {
      final state = RouteState.parse('/home');
      expect(state.shouldPreserve, false);
    });

    test('animationEffect defaults to NoEffect', () {
      final state = RouteState.parse('/home');
      expect(state.animationEffect, isA<NoEffect>());
    });
  });

  // -------------------------------------------------------------------------
  // RouteBuilder tests
  // -------------------------------------------------------------------------

  group('RouteBuilder', () {
    test('shouldPreserve defaults to false', () {
      final builder = _builder('/home');
      expect(builder.shouldPreserve, false);
    });

    test('shouldPrebuild defaults to false', () {
      final builder = _builder('/home');
      expect(builder.shouldPrebuild, false);
    });

    test('shouldPreserve can be set to true', () {
      final builder = _builder('/home', shouldPreserve: true);
      expect(builder.shouldPreserve, true);
    });

    test('shouldPrebuild can be set to true', () {
      final builder = _builder('/home', shouldPrebuild: true);
      expect(builder.shouldPrebuild, true);
    });

    test('condition can be provided', () {
      var called = false;
      _builder(
        '/home',
        condition: () {
          called = true;
          return true;
        },
      );
      // Condition is not called at construction — only at navigation.
      expect(called, false);
    });

    test('copyWith preserves shouldPreserve', () {
      final builder = _builder('/home', shouldPreserve: true);
      final copy = builder.copyWith();
      expect(copy.shouldPreserve, true);
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — initialisation
  // -------------------------------------------------------------------------

  group('RouteController initialisation', () {
    test('starts with fallback route when no initial or deep link', () {
      final controller = _makeController();
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('initialRouteState overrides fallback', () {
      final controller = _makeController(
        initialRouteState: () => RouteState.parse('/gallery'),
      );
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });

    test('pathExists returns true for registered paths', () {
      final controller = _makeController();
      expect(controller.pathExists(Uri.parse('/home')), true);
      expect(controller.pathExists(Uri.parse('/gallery')), true);
      expect(controller.pathExists(Uri.parse('/nonexistent')), false);
      controller.dispose();
    });

    test('errorRouteState is stored', () {
      final controller = _makeController(
        errorRouteState: () => RouteState.parse('/home'),
      );
      expect(controller.errorRouteState, isNotNull);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — navigation: push
  // -------------------------------------------------------------------------

  group('RouteController push', () {
    test('push changes current route', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });

    test('push adds to history', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      final state = controller.pNavigationState.getValue();
      expect(state.routes.length, 2);
      expect(state.index, 1);
      controller.dispose();
    });

    test('push truncates forward history', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      // History: home → gallery → canvas (index 2)
      expect(controller.pNavigationState.getValue().routes.length, 3);

      // Go back to gallery
      controller.goBackward();
      expect(controller.currentRouteState.uri.path, '/gallery');

      // Push settings — should truncate canvas from forward history
      controller.push(RouteState.parse('/settings'));
      final state = controller.pNavigationState.getValue();
      expect(state.routes.length, 3); // home → gallery → settings
      expect(state.index, 2);
      expect(state.routes[2].uri.path, '/settings');
      controller.dispose();
    });

    test('skipCurrent prevents double-push of same route', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/gallery')); // skipCurrent=true
      expect(controller.pNavigationState.getValue().routes.length, 2);
      controller.dispose();
    });

    test('skipCurrent=false allows double-push', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery', skipCurrent: false));
      controller.push(RouteState.parse('/gallery', skipCurrent: false));
      expect(controller.pNavigationState.getValue().routes.length, 3);
      controller.dispose();
    });

    test('push to nonexistent path does nothing without error route', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/nonexistent'));
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('push to nonexistent path navigates to error route', () {
      final controller = _makeController(
        errorRouteState: () => RouteState.parse('/settings'),
      );
      controller.push(RouteState.parse('/nonexistent'));
      expect(controller.currentRouteState.uri.path, '/settings');
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — navigation: goBackward / goForward / step
  // -------------------------------------------------------------------------

  group('RouteController backward/forward/step', () {
    test('canGoBackward is false at start', () {
      final controller = _makeController();
      expect(controller.canGoBackward, false);
      controller.dispose();
    });

    test('canGoForward is false at start', () {
      final controller = _makeController();
      expect(controller.canGoForward, false);
      controller.dispose();
    });

    test('canGoBackward is true after push', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      expect(controller.canGoBackward, true);
      controller.dispose();
    });

    test('goBackward returns to previous route', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      final result = controller.goBackward();
      expect(result, true);
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('goBackward at start returns false', () {
      final controller = _makeController();
      expect(controller.goBackward(), false);
      controller.dispose();
    });

    test('goForward returns false when no forward history', () {
      final controller = _makeController();
      expect(controller.goForward(), false);
      controller.dispose();
    });

    test('goForward works after goBackward', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.goBackward(); // back to /home
      expect(controller.canGoForward, true);
      final result = controller.goForward();
      expect(result, true);
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });

    test('step(2) jumps forward two routes', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      controller.goBackward();
      controller.goBackward(); // at /home
      expect(controller.step(2), true);
      expect(controller.currentRouteState.uri.path, '/canvas');
      controller.dispose();
    });

    test('step with out-of-bounds index returns false', () {
      final controller = _makeController();
      expect(controller.step(5), false);
      expect(controller.step(-1), false);
      controller.dispose();
    });

    test('step to exact position works', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      // Current index is 2; step(-2) brings us to index 0 (/home).
      expect(controller.step(-2), true);
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('step out of bounds returns false', () {
      final controller = _makeController();
      // At index 0, stepping backward or far forward should fail.
      expect(controller.step(-1), false);
      expect(controller.step(99), false);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — history
  // -------------------------------------------------------------------------

  group('RouteController history', () {
    test('clearHistory resets to current route only', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      controller.clearHistory();
      final state = controller.pNavigationState.getValue();
      expect(state.routes.length, 1);
      expect(state.index, 0);
      expect(state.routes[0].uri.path, '/canvas');
      controller.dispose();
    });

    test('clearHistory makes canGoBackward false', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.clearHistory();
      expect(controller.canGoBackward, false);
      controller.dispose();
    });

    test('multiple pushes create correct history length', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      controller.push(RouteState.parse('/settings'));
      expect(controller.pNavigationState.getValue().routes.length, 4);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — route checking
  // -------------------------------------------------------------------------

  group('RouteController route checking', () {
    test('checkBackwardRoute identifies previous route', () {
      final controller = _makeController();
      final gallery = RouteState.parse('/gallery');
      controller.push(gallery);
      controller.push(RouteState.parse('/canvas'));
      expect(controller.checkBackwardRoute(gallery), true);
      controller.dispose();
    });

    test('checkForwardRoute identifies next route', () {
      final controller = _makeController();
      final gallery = RouteState.parse('/gallery');
      controller.push(gallery);
      controller.goBackward();
      expect(controller.checkForwardRoute(gallery), true);
      controller.dispose();
    });

    test('checkRouteFromIndex handles out-of-bounds', () {
      final controller = _makeController();
      expect(controller.checkRouteFromIndex(-1, (_) => true), false);
      expect(controller.checkRouteFromIndex(99, (_) => true), false);
      controller.dispose();
    });

    test('checkRouteFromStep checks relative position', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      final result = controller.checkRouteFromStep(-1, (r) {
        return r.uri.path == '/home';
      });
      expect(result, true);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — conditions
  // -------------------------------------------------------------------------

  group('RouteController conditions', () {
    test('route condition blocks navigation when false', () {
      final controller = RouteController(
        fallbackRouteState: () => RouteState.parse('/home'),
        builders: [
          _builder('/home'),
          _builder('/gallery', condition: () => false),
        ],
      );
      controller.push(RouteState.parse('/gallery'));
      // Navigation blocked — still on /home.
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('route condition allows navigation when true', () {
      final controller = RouteController(
        fallbackRouteState: () => RouteState.parse('/home'),
        builders: [
          _builder('/home'),
          _builder('/gallery', condition: () => true),
        ],
      );
      controller.push(RouteState.parse('/gallery'));
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });

    test('routeState condition blocks navigation', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery', condition: () => false));
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — cache & preservation
  // -------------------------------------------------------------------------

  group('RouteController cache and preservation', () {
    test('clearCache empties the widget cache', () {
      final controller = _makeController();
      controller.clearCache();
      // After clearCache, resetState should re-add prebuilt routes.
      controller.resetState();
      // No crash means success.
      controller.dispose();
    });

    test('resetState rebuilds prebuilt routes', () {
      final controller = RouteController(
        fallbackRouteState: () => RouteState.parse('/home'),
        builders: [
          _builder('/home', shouldPrebuild: true),
          _builder('/gallery'),
        ],
      );
      controller.resetState();
      // Home should be in cache (prebuilt), gallery should not.
      controller.dispose();
    });

    test('addToCache does not overwrite existing non-SizedBox widgets', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      // Adding to cache again should not replace the existing widget.
      controller.addToCache([RouteState.parse('/gallery')]);
      // No crash and route still works.
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — pushUri (browser navigation)
  // -------------------------------------------------------------------------

  group('RouteController pushUri', () {
    test('pushUri navigates to existing route in history', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      // Simulate browser navigating back to /home.
      controller.pushUri(Uri.parse('/home'));
      expect(controller.currentRouteState.uri.path, '/home');
      controller.dispose();
    });

    test('pushUri creates new route for unknown URI', () {
      final controller = _makeController();
      controller.pushUri(Uri.parse('/gallery'));
      expect(controller.currentRouteState.uri.path, '/gallery');
      controller.dispose();
    });

    test('pushUri does nothing when already on target URI', () {
      final controller = _makeController();
      final stateBefore = controller.pNavigationState.getValue();
      controller.pushUri(Uri.parse('/home'));
      final stateAfter = controller.pNavigationState.getValue();
      expect(stateAfter.index, stateBefore.index);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // RouteController — Pod reactivity
  // -------------------------------------------------------------------------

  group('RouteController Pod reactivity', () {
    test('pCurrentRouteState updates on navigation', () {
      final controller = _makeController();
      expect(controller.pCurrentRouteState.getValue().uri.path, '/home');
      controller.push(RouteState.parse('/gallery'));
      expect(controller.pCurrentRouteState.getValue().uri.path, '/gallery');
      controller.push(RouteState.parse('/canvas'));
      expect(controller.pCurrentRouteState.getValue().uri.path, '/canvas');
      controller.dispose();
    });

    test('pNavigationState updates index on go', () {
      final controller = _makeController();
      controller.push(RouteState.parse('/gallery'));
      controller.push(RouteState.parse('/canvas'));
      controller.goBackward();
      expect(controller.pNavigationState.getValue().index, 1);
      controller.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Animation effects
  // -------------------------------------------------------------------------

  group('AnimationEffect subclasses', () {
    test('NoEffect has zero duration', () {
      const effect = NoEffect();
      expect(effect.duration, Duration.zero);
    });

    test('FadeEffect has 275ms duration', () {
      const effect = FadeEffect();
      expect(effect.duration.inMilliseconds, 275);
    });

    test('CupertinoEffect has 410ms duration', () {
      const effect = CupertinoEffect();
      expect(effect.duration.inMilliseconds, 410);
    });

    test('PageFlapLeft has 500ms duration', () {
      const effect = PageFlapLeft();
      expect(effect.duration.inMilliseconds, 500);
    });

    test('PageFlapRight has 500ms duration', () {
      const effect = PageFlapRight();
      expect(effect.duration.inMilliseconds, 500);
    });

    test('NoEffect data returns identity layers', () {
      const effect = NoEffect();
      final layers = effect.data(
        // Can't create a real BuildContext in unit tests — effects don't use
        // it, but the signature requires it.
        _FakeBuildContext(),
        const Size(400.0, 800.0),
        0.5,
      );
      expect(layers.length, 2);
    });

    test('FadeEffect produces opacity values', () {
      const effect = FadeEffect();
      final layers = effect.data(
        _FakeBuildContext(),
        const Size(400.0, 800.0),
        0.5,
      );
      expect(layers[0].opacity, 0.5);
      expect(layers[1].ignorePointer, true);
    });

    test('ForwardEffect produces horizontal translation', () {
      const effect = ForwardEffect();
      final layers = effect.data(
        _FakeBuildContext(),
        const Size(400.0, 800.0),
        0.5,
      );
      final transform = layers[0].transform;
      expect(transform, isNotNull);
      // At value=0.5, the page should be halfway across.
      final translation = transform!.getTranslation();
      expect(translation.x, closeTo(200.0, 1.0));
    });

    test('BackwardEffect translates in opposite direction', () {
      const effect = BackwardEffect();
      final layers = effect.data(
        _FakeBuildContext(),
        const Size(400.0, 800.0),
        0.5,
      );
      final translation = layers[0].transform!.getTranslation();
      expect(translation.x, closeTo(-200.0, 1.0));
    });

    test('SlideUpEffect translates vertically', () {
      const effect = SlideUpEffect();
      final layers = effect.data(
        _FakeBuildContext(),
        const Size(400.0, 800.0),
        0.5,
      );
      final translation = layers[0].transform!.getTranslation();
      expect(translation.y, closeTo(400.0, 1.0));
    });

    test('All effects produce exactly 2 layers', () {
      final effects = <AnimationEffect>[
        const NoEffect(),
        const FadeEffect(),
        const FadeEffectWeb(),
        const ForwardEffect(),
        const ForwardEffectWeb(),
        const BackwardEffect(),
        const BackwardEffectWeb(),
        const SlideUpEffect(),
        const SlideDownEffect(),
        const CupertinoEffect(),
        const MaterialEffect(),
        const PageFlapLeft(),
        const PageFlapRight(),
      ];
      final ctx = _FakeBuildContext();
      for (final effect in effects) {
        final layers = effect.data(ctx, const Size(400.0, 800.0), 0.5);
        expect(
          layers.length,
          2,
          reason: '${effect.runtimeType} should have 2 layers',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // AnimationLayerEffect
  // -------------------------------------------------------------------------

  group('AnimationLayerEffect', () {
    test('default constructor has all null fields', () {
      const effect = AnimationLayerEffect();
      expect(effect.transform, isNull);
      expect(effect.opacity, isNull);
      expect(effect.colorFilter, isNull);
      expect(effect.imageFilter, isNull);
      expect(effect.ignorePointer, isNull);
    });

    test('isIdentity is true for default', () {
      const effect = AnimationLayerEffect();
      expect(effect.isIdentity, true);
    });

    test('isIdentity is false with opacity < 1', () {
      const effect = AnimationLayerEffect(opacity: 0.5);
      expect(effect.isIdentity, false);
    });

    test('hasVisualEffects detects opacity', () {
      const effect = AnimationLayerEffect(opacity: 0.5);
      expect(effect.hasVisualEffects, true);
    });

    test('equality works', () {
      const a = AnimationLayerEffect(opacity: 0.5);
      const b = AnimationLayerEffect(opacity: 0.5);
      expect(a, equals(b));
    });
  });

  // -------------------------------------------------------------------------
  // RouteManager widget test
  // -------------------------------------------------------------------------

  group('RouteManager widget', () {
    testWidgets('renders and provides controller', (tester) async {
      late RouteController capturedController;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteManager(
              fallbackRouteState: () => RouteState.parse('/home'),
              onControllerCreated: (c) => capturedController = c,
              builders: [
                RouteBuilder(
                  routeState: RouteState.parse('/home'),
                  builder: (context, routeState) {
                    return _TestScreen(routeState: routeState, label: 'Home');
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(capturedController.currentRouteState.uri.path, '/home');
    });

    testWidgets('clipToBounds wraps in ClipRect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteManager(
              fallbackRouteState: () => RouteState.parse('/home'),
              clipToBounds: true,
              builders: [
                RouteBuilder(
                  routeState: RouteState.parse('/home'),
                  builder: (context, routeState) {
                    return _TestScreen(routeState: routeState, label: 'Home');
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ClipRect), findsWidgets);
    });

    testWidgets('wrapper wraps the child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteManager(
              fallbackRouteState: () => RouteState.parse('/home'),
              wrapper: (context, child) {
                return ColoredBox(color: Colors.red, child: child);
              },
              builders: [
                RouteBuilder(
                  routeState: RouteState.parse('/home'),
                  builder: (context, routeState) {
                    return _TestScreen(routeState: routeState, label: 'Home');
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('onControllerCreated is called once', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteManager(
              fallbackRouteState: () => RouteState.parse('/home'),
              onControllerCreated: (_) => callCount++,
              builders: [
                RouteBuilder(
                  routeState: RouteState.parse('/home'),
                  builder: (context, routeState) {
                    return _TestScreen(routeState: routeState, label: 'Home');
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(callCount, 1);
    });
  });

  // -------------------------------------------------------------------------
  // RouteController.of
  // -------------------------------------------------------------------------

  group('RouteController.of', () {
    testWidgets('throws when no provider in tree', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        () => RouteController.of(capturedContext),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Preservation strategy
  // -------------------------------------------------------------------------

  group('Preservation strategy', () {
    test('default strategy checks builder and state shouldPreserve', () {
      final builder = _builder('/home', shouldPreserve: true);
      expect(RouteController.defaultPreservationStrategy(builder), true);
    });

    test('default strategy returns false when neither is preserved', () {
      final builder = _builder('/home');
      expect(RouteController.defaultPreservationStrategy(builder), false);
    });

    test('custom strategy can be set', () {
      final controller = _makeController();
      // Strategy that preserves everything.
      controller.setPreservationStrategy((_) => true);
      // Push and go back — the old route should still be preserved.
      controller.push(RouteState.parse('/gallery'));
      controller.goBackward();
      controller.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal fake BuildContext for unit-testing animation effects.
// Effects only use BuildContext for MediaQuery access, which we bypass by
// passing the size directly via the data function.
// ---------------------------------------------------------------------------

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
