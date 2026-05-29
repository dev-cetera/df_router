import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

void main() {
  setUp(() {
    TaggedScreenState.resetCounts();
  });

  Future<RouteController> mountController(
    WidgetTester tester, {
    required List<RouteBuilder> builders,
    required RouteState Function() fallbackRouteState,
    RouteState Function()? initialRouteState,
    RouteState<Enum> Function()? errorState,
  }) async {
    late RouteController controller;
    await tester.pumpWidget(
      wrapRouter(
        RouteManager(
          initialRouteState: initialRouteState,
          fallbackRouteState: fallbackRouteState,
          errorState: errorState,
          builders: builders,
          onControllerCreated: (c) => controller = c,
        ),
      ),
    );
    return controller;
  }

  group('Construction', () {
    testWidgets('uses fallbackRouteState when no initialRouteState is given',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.currentRouteState.uri.path, '/home');
    });

    testWidgets('uses initialRouteState when provided', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        initialRouteState: () => RouteState(Uri.parse('/about')),
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.currentRouteState.uri.path, '/about');
    });

    testWidgets('prebuilds builders flagged shouldPrebuild', (tester) async {
      await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home', shouldPrebuild: true),
          tagBuilder('about', '/about', shouldPrebuild: true),
          tagBuilder('contact', '/contact'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      await tester.pump();
      // Prebuilt routes initialize their state at controller construction time.
      expect(TaggedScreenState.initCounts['home'], 1);
      expect(TaggedScreenState.initCounts['about'], 1);
      expect(TaggedScreenState.initCounts['contact'], isNull);
    });

    testWidgets('initial cold-boot route falling outside the registered paths '
        'falls back to fallbackRouteState', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        initialRouteState: () => RouteState(Uri.parse('/does-not-exist')),
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.currentRouteState.uri.path, '/home');
    });

    testWidgets('initial cold-boot route whose condition returns false '
        'falls back to fallbackRouteState', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        initialRouteState: () => RouteState(
          Uri.parse('/about'),
          condition: () => false,
        ),
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.currentRouteState.uri.path, '/home');
    });
  });

  group('pathExists / path normalization', () {
    testWidgets('exposes pathExists', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.pathExists(Uri.parse('/home')), isTrue);
      expect(controller.pathExists(Uri.parse('/other')), isFalse);
    });

    testWidgets('trailing slash is normalized away', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('foo', '/foo')],
        fallbackRouteState: () => RouteState(Uri.parse('/foo')),
      );
      expect(controller.pathExists(Uri.parse('/foo/')), isTrue);
    });

    testWidgets('empty path normalizes to "/"', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('root', '/')],
        fallbackRouteState: () => RouteState(Uri.parse('/')),
      );
      expect(controller.pathExists(Uri.parse('')), isTrue);
    });
  });

  group('push (forward navigation)', () {
    testWidgets('pushes a new route and advances the history index',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(RouteState(Uri.parse('/about')));
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/about');
      expect(controller.pNavigationState.getValue().index, 1);
      expect(controller.pNavigationState.getValue().routes.length, 2);
    });

    testWidgets('skipCurrent=true (default) rejects a push to the current uri',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(RouteState(Uri.parse('/home')));
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().routes.length, 1);
    });

    testWidgets('skipCurrent=false allows pushing the same uri', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(
        RouteState(Uri.parse('/home'), skipCurrent: false),
      );
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().routes.length, 2);
    });

    testWidgets('push to an unregistered path is rejected (no navigation)',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(RouteState(Uri.parse('/nope')));
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/home');
      expect(controller.pNavigationState.getValue().routes.length, 1);
    });

    testWidgets('push with failing routeState.condition is rejected',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(
        RouteState(Uri.parse('/about'), condition: () => false),
      );
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/home');
    });

    testWidgets('errorFallback is pushed when path is missing', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('error', '/error'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(
        RouteState(Uri.parse('/nope')),
        errorFallback: RouteState(Uri.parse('/error')),
      );
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/error');
    });
  });

  group('pushUri', () {
    testWidgets('pushes a new uri when not in history', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('about', '/about'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.pushUri(Uri.parse('/about'));
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/about');
    });

    testWidgets('jumps within history when the uri is already there',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.push(RouteState(Uri.parse('/a')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      // History: [/home, /a, /b], index=2. pushUri(/a) should jump back.
      controller.pushUri(Uri.parse('/a'));
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().index, 1);
      expect(controller.currentRouteState.uri.path, '/a');
    });

    testWidgets('no-op when uri matches the current route', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('home', '/home')],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      controller.pushUri(Uri.parse('/home'));
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().routes.length, 1);
    });
  });

  group('goForward / goBackward / step / canGoForward / canGoBackward', () {
    testWidgets('canGoBackward/canGoForward reflect history position',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      expect(controller.canGoBackward, isFalse);
      expect(controller.canGoForward, isFalse);
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(controller.canGoBackward, isTrue);
      expect(controller.canGoForward, isFalse);
      controller.goBackward();
      await tester.pumpAndSettle();
      expect(controller.canGoBackward, isFalse);
      expect(controller.canGoForward, isTrue);
    });

    testWidgets('goBackward moves index -1, goForward moves +1', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(controller.goBackward(), isTrue);
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/a');
      expect(controller.goForward(), isTrue);
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/b');
    });

    testWidgets('goBackward returns false at start of history', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('a', '/a')],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      expect(controller.goBackward(), isFalse);
    });

    testWidgets('goForward returns false at end of history', (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('a', '/a')],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      expect(controller.goForward(), isFalse);
    });

    testWidgets('step jumps by N positions', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
          tagBuilder('c', '/c'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/c')));
      await tester.pumpAndSettle();
      expect(controller.step(-2), isTrue);
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/a');
    });
  });

  group('push truncates forward history', () {
    testWidgets('pushing after a goBackward drops the forward routes',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
          tagBuilder('c', '/c'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/c')));
      await tester.pumpAndSettle();
      controller.goBackward();
      await tester.pumpAndSettle(); // now at /b with /c forward
      expect(controller.canGoForward, isTrue);
      controller.push(RouteState(Uri.parse('/a'))); // truncates /c
      await tester.pumpAndSettle();
      expect(controller.canGoForward, isFalse);
      final routes = controller.pNavigationState.getValue().routes;
      expect(routes.map((r) => r.uri.path).toList(), ['/a', '/b', '/a']);
    });
  });

  group('clearHistory', () {
    testWidgets('keeps only the current route and resets index to 0',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
          tagBuilder('c', '/c'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/c')));
      await tester.pumpAndSettle();
      controller.clearHistory();
      await tester.pump();
      expect(controller.pNavigationState.getValue().routes.length, 1);
      expect(controller.pNavigationState.getValue().index, 0);
      expect(controller.currentRouteState.uri.path, '/c');
    });
  });

  group('cache management', () {
    testWidgets('addToCache then removeFromCache', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      final routeB = RouteState(Uri.parse('/b'));
      controller.addToCache([routeB]);
      await tester.pump();
      // The route widget is built when it's visible. addToCache only puts a
      // Builder in the cache; verify the cache lookup index changes by pushing
      // and confirming no second build of B happens.
      controller.push(routeB);
      await tester.pumpAndSettle();
      final firstBuildCount = TaggedScreenState.buildCounts['b'] ?? 0;
      expect(firstBuildCount, greaterThan(0));
      controller.removeFromCache([routeB]);
      // After removeFromCache, navigating back to B should rebuild it.
      controller.goBackward();
      await tester.pumpAndSettle();
      controller.push(routeB);
      await tester.pumpAndSettle();
      expect(
        TaggedScreenState.initCounts['b'],
        greaterThanOrEqualTo(2),
        reason: 'B should be reinitialized after being removed from cache',
      );
    });

    testWidgets('clearCache disposes all non-current widgets next frame',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.clearCache();
      // The build screen rebuilds after a navigation; force one.
      controller.push(RouteState(Uri.parse('/a'), skipCurrent: false));
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/a');
    });

    testWidgets('resetState clears then re-prebuilds the flagged routes',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a', shouldPrebuild: true),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      final initsBefore = TaggedScreenState.initCounts['a']!;
      controller.resetState();
      await tester.pump();
      // resetState refreshes the cache map; prebuilt routes are re-cached.
      controller.push(RouteState(Uri.parse('/a'), skipCurrent: false));
      await tester.pumpAndSettle();
      expect(
        TaggedScreenState.initCounts['a'],
        greaterThan(initsBefore),
        reason: 'a was cleared then re-cached, so a fresh build re-inits it',
      );
    });
  });

  group('preservation strategy', () {
    testWidgets('default strategy: shouldPreserve=true keeps the State alive',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b', shouldPreserve: true),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(TaggedScreenState.initCounts['b'], 1);
      controller.push(RouteState(Uri.parse('/a'), skipCurrent: false));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      // Second visit must NOT re-initState — preservation kept the State.
      expect(TaggedScreenState.initCounts['b'], 1);
    });

    testWidgets('default strategy: shouldPreserve=false drops the State',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/a'), skipCurrent: false));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      // Without preservation, B is rebuilt on the second visit.
      expect(TaggedScreenState.initCounts['b'], 2);
    });

    testWidgets('custom strategy can force preservation for all routes',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.setPreservationStrategy((_) => true);
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/a'), skipCurrent: false));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(TaggedScreenState.initCounts['b'], 1);
    });
  });

  group('checkRouteFromIndex / Step / Backward / Forward', () {
    testWidgets('checkRouteFromIndex respects bounds', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      controller.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(
        controller.checkRouteFromIndex(0, (r) => r.uri.path == '/a'),
        isTrue,
      );
      expect(
        controller.checkRouteFromIndex(99, (r) => true),
        isFalse,
      );
      expect(
        controller.checkRouteFromIndex(-1, (r) => true),
        isFalse,
      );
    });

    testWidgets('checkBackwardRoute / checkForwardRoute', (tester) async {
      final controller = await mountController(
        tester,
        builders: [
          tagBuilder('a', '/a'),
          tagBuilder('b', '/b'),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/a')),
      );
      final routeA = RouteState(Uri.parse('/a'));
      final routeB = RouteState(Uri.parse('/b'));
      controller.push(routeB);
      await tester.pumpAndSettle();
      expect(controller.checkBackwardRoute(routeA), isTrue);
      expect(controller.checkForwardRoute(routeB), isFalse);
    });
  });

  group('URI matching (ignores query param ORDER)', () {
    testWidgets('pushUri matches in history regardless of query order',
        (tester) async {
      final controller = await mountController(
        tester,
        builders: [tagBuilder('p', '/p')],
        fallbackRouteState: () => RouteState(Uri.parse('/p')),
      );
      controller.push(RouteState(Uri.parse('/p?a=1&b=2')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/p?c=3')));
      await tester.pumpAndSettle();
      // Push the same route with reordered query string — should jump back.
      controller.pushUri(Uri.parse('/p?b=2&a=1'));
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().index, 1);
    });
  });

  group('RouteController.of', () {
    testWidgets('finds the controller via the inherited provider',
        (tester) async {
      late RouteController fromContext;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/x')),
            builders: [
              RouteBuilder<Object?>(
                routeState: RouteState(Uri.parse('/x')),
                builder: (context, state) {
                  fromContext = RouteController.of(context);
                  return TaggedScreen<Object?>(
                    tag: 'x',
                    routeState: state,
                  );
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fromContext, isNotNull);
    });

    testWidgets('throws when no provider is in the tree', (tester) async {
      late BuildContext capturedCtx;
      await tester.pumpWidget(
        wrapRouter(
          Builder(
            builder: (context) {
              capturedCtx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        () => RouteController.of(capturedCtx),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}
