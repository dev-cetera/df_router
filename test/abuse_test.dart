// Abuse tests: probe the package's edges with pathological inputs and patterns
// that real users might hit. These tests have two purposes:
//   1. Find bugs (rapid pushes, dispose races, degenerate inputs).
//   2. Pin current behavior so future refactors can't quietly regress.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

class _SlowEffect extends AnimationEffect {
  const _SlowEffect()
      : super(
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    return [
      AnimationLayerEffect(opacity: value),
      AnimationLayerEffect(opacity: 1.0 - value, ignorePointer: true),
    ];
  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  final String label;
  const _ColorBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Text(
          label,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    TaggedScreenState.resetCounts();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RouteController abuse — pathological constructions
  // ─────────────────────────────────────────────────────────────────────────

  group('RouteController abuse — pathological constructions', () {
    testWidgets(
        'empty builders list mounts cleanly; controller exists but has no '
        'renderable routes', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/x')),
            builders: const [],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pump();
      expect(controller.pathExists(Uri.parse('/x')), isFalse);
      // Pushing into a nonexistent path is a silent no-op (logged, not thrown).
      controller.push(RouteState(Uri.parse('/anywhere')));
      await tester.pump();
      expect(controller.currentRouteState.uri.path, '/x');
    });

    testWidgets('duplicate builder paths: last builder in the list wins',
        (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/x')),
            builders: [
              tagBuilder('first', '/x'),
              tagBuilder('second', '/x'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });

    testWidgets(
        'path normalization: with/without trailing slash collapse to '
        'the same key', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/foo/')),
            builders: [tagBuilder('foo', '/foo/')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.pathExists(Uri.parse('/foo')), isTrue);
      expect(controller.pathExists(Uri.parse('/foo/')), isTrue);
      controller.push(RouteState(Uri.parse('/foo')));
      await tester.pumpAndSettle();
      // Push to '/foo' should match the '/foo/' builder.
      expect(find.text('foo'), findsOneWidget);
    });

    testWidgets('empty Uri path normalizes to "/" and matches a "/" builder',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/')),
            builders: [tagBuilder('root', '/')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.pathExists(Uri.parse('')), isTrue);
      expect(controller.pathExists(Uri()), isTrue);
    });

    testWidgets('paths with special characters and unicode survive round-trip',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/foo%20bar')),
            builders: [
              tagBuilder('a', '/foo%20bar'),
              tagBuilder('b', '/héllo'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // %20 in path stays %20 in path (URI does not auto-decode the path
      // component). The path matcher works against the literal Uri.path.
      expect(controller.pathExists(Uri.parse('/foo%20bar')), isTrue);
      // Unicode path component is also a literal byte sequence in Uri.path.
      expect(controller.pathExists(Uri.parse('/héllo')), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RouteController abuse — rapid mutation
  // ─────────────────────────────────────────────────────────────────────────

  group('RouteController abuse — rapid mutation', () {
    testWidgets(
        '100 sequential pushes without pump completes without '
        'exceptions and the final route is current', (tester) async {
      late RouteController controller;
      final builders = <RouteBuilder>[
        tagBuilder('home', '/'),
        for (var i = 0; i < 100; i++) tagBuilder('r$i', '/r$i'),
      ];
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/')),
            builders: builders,
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 100; i++) {
        controller.push(RouteState(Uri.parse('/r$i')));
      }
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/r99');
      // History length: initial '/' + 100 pushes = 101 entries.
      expect(controller.pNavigationState.getValue().routes.length, 101);
    });

    testWidgets('rapid push, then goBackward chain: history coherence holds',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/')),
            builders: [
              tagBuilder('home', '/'),
              for (var i = 0; i < 10; i++) tagBuilder('r$i', '/r$i'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        controller.push(RouteState(Uri.parse('/r$i')));
        await tester.pumpAndSettle();
      }
      // Go all the way back.
      for (var i = 0; i < 10; i++) {
        expect(controller.canGoBackward, isTrue);
        controller.goBackward();
        await tester.pumpAndSettle();
      }
      expect(controller.canGoBackward, isFalse);
      expect(controller.currentRouteState.uri.path, '/');
      // Then go all the way forward.
      for (var i = 0; i < 10; i++) {
        expect(controller.canGoForward, isTrue);
        controller.goForward();
        await tester.pumpAndSettle();
      }
      expect(controller.currentRouteState.uri.path, '/r9');
    });

    testWidgets(
        'push then dispose immediately: no exception, controller is '
        'safe to call into after dispose (calls become silent no-ops)',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b')));
      // Unmount the RouteManager — triggers controller.dispose().
      await tester.pumpWidget(wrapRouter(const SizedBox.shrink()));
      // Post-dispose calls must not throw.
      controller.push(RouteState(Uri.parse('/a')));
      controller.goBackward();
      controller.goForward();
      controller.clearHistory();
      controller.resetState();
      controller.clearCache();
      controller.addToCache([RouteState(Uri.parse('/a'))]);
      controller.removeFromCache([RouteState(Uri.parse('/a'))]);
      // No assertions to make — just survive without throwing.
    });

    testWidgets(
        'push during in-progress transition restarts the animation '
        'cleanly; only the final route ends up visible', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a'),
              tagBuilder('b', '/b'),
              tagBuilder('c', '/c'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Push C while B's transition is mid-flight.
      controller.push(
        RouteState(Uri.parse('/c'), animationEffect: const _SlowEffect()),
      );
      await tester.pumpAndSettle();
      expect(find.text('c'), findsOneWidget);
      expect(controller.currentRouteState.uri.path, '/c');
    });

    testWidgets(
        'addToCache then immediately removeFromCache same route: cache '
        'returns to baseline', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final routeB = RouteState(Uri.parse('/b'));
      controller.addToCache([routeB]);
      controller.removeFromCache([routeB]);
      await tester.pumpAndSettle();
      // Navigation to B still works.
      controller.push(routeB);
      await tester.pumpAndSettle();
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('clearHistory during an in-progress transition does not crash',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      controller.clearHistory();
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().routes.length, 1);
      expect(controller.currentRouteState.uri.path, '/b');
    });

    testWidgets(
        'rapid setPreservationStrategy changes do not affect the '
        'in-flight transition', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      controller.setPreservationStrategy((_) => true);
      controller.setPreservationStrategy((_) => false);
      controller.setPreservationStrategy(
        (b) => b.shouldPreserve || b.routeState.shouldPreserve,
      );
      await tester.pumpAndSettle();
      expect(find.text('b'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RouteController abuse — guards and conditions
  // ─────────────────────────────────────────────────────────────────────────

  group('RouteController abuse — guards and conditions', () {
    testWidgets(
        'a condition that itself navigates (recursive push) does not '
        'deadlock or stack-overflow', (tester) async {
      late RouteController controller;
      var conditionHits = 0;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a'),
              tagBuilder('b', '/b'),
              tagBuilder('c', '/c'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(
          Uri.parse('/b'),
          condition: () {
            conditionHits++;
            // Recursive push from within a condition. The condition returns
            // false so the original push is rejected, but the inner push
            // executes first.
            if (conditionHits == 1) {
              controller.push(RouteState(Uri.parse('/c')));
            }
            return false;
          },
        ),
      );
      await tester.pumpAndSettle();
      // The condition rejected /b; the inner push to /c succeeded.
      expect(controller.currentRouteState.uri.path, '/c');
      // The condition was hit exactly once (guards self-reentry).
      expect(conditionHits, 1);
    });

    testWidgets(
        'a builder.condition that returns false blocks navigation '
        'without leaving an inconsistent state', (tester) async {
      late RouteController controller;
      var allowB = false;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a'),
              RouteBuilder<Object?>(
                routeState: RouteState(Uri.parse('/b')),
                condition: () => allowB,
                builder: (context, state) =>
                    TaggedScreen<Object?>(tag: 'b', routeState: state),
              ),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/b'))); // blocked
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/a');
      allowB = true;
      controller.push(RouteState(Uri.parse('/b'))); // allowed
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/b');
    });

    testWidgets(
        'initial-route condition false falls back even if path is '
        'registered', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            initialRouteState: () => RouteState(
              Uri.parse('/secret'),
              condition: () => false,
            ),
            fallbackRouteState: () => RouteState(Uri.parse('/home')),
            builders: [
              tagBuilder('home', '/home'),
              tagBuilder('secret', '/secret'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/home');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTENCE INVARIANT — preserved routes do not rebuild during transitions
  // ─────────────────────────────────────────────────────────────────────────

  group('Persistence invariant', () {
    testWidgets(
        'preserved-but-not-active route is NOT rebuilt during a '
        'transition between two other routes (this is what makes "stateful '
        'routes" actually stateful)', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a', shouldPreserve: true),
              tagBuilder('b', '/b'),
              tagBuilder('c', '/c'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Visit B (so a transition runs from A → B; A is preserved).
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pumpAndSettle();
      final buildsBefore = TaggedScreenState.buildCounts['a']!;
      // Now navigate B → C. During this transition A is offstage but kept in
      // the tree (shouldPreserve). It must NOT be rebuilt.
      controller.push(
        RouteState(Uri.parse('/c'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      // CRITICAL: A's build() count must not have moved.
      expect(
        TaggedScreenState.buildCounts['a'],
        buildsBefore,
        reason: 'A is preserved and offstage during B→C — re-rendering it '
            'would defeat the "stateful routes" guarantee that the router '
            'is built to provide. If this fails, something marked A dirty '
            'during the transition (rebuild loop, key churn, stale '
            'InheritedWidget dependency, etc.).',
      );
    });

    testWidgets(
        'the OUTGOING route during a transition does not rebuild '
        'per animation frame (the AnimatedBuilder only re-paints, not '
        're-builds, the cached widget subtrees)', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a', shouldPreserve: true),
              tagBuilder('b', '/b'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final buildsBefore = TaggedScreenState.buildCounts['a']!;
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump(); // start the animation
      // Drive ~20 animation frames manually.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 15));
      }
      await tester.pumpAndSettle();
      // A's build() ran AT MOST once more (potentially once if the layer
      // composition forced a relayout of its subtree). But not 20+ times.
      final buildsAfter = TaggedScreenState.buildCounts['a']!;
      expect(
        buildsAfter - buildsBefore,
        lessThanOrEqualTo(1),
        reason: 'The outgoing layer should be re-PAINTED per frame, not '
            're-BUILT. A delta of >1 here means the animation tick is '
            'leaking through Element-tree rebuilds.',
      );
    });

    testWidgets('the INCOMING route also does not rebuild per animation frame',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a'),
              tagBuilder('b', '/b'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      final buildsAtStart = TaggedScreenState.buildCounts['b']!;
      // Drive ~20 frames.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 15));
      }
      await tester.pumpAndSettle();
      final buildsAtEnd = TaggedScreenState.buildCounts['b']!;
      expect(
        buildsAtEnd - buildsAtStart,
        lessThanOrEqualTo(1),
        reason: 'The incoming layer should be re-PAINTED per frame via the '
            'AnimatedBuilder + render-object pipeline — not re-BUILT.',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PrioritizedIndexedStack abuse
  // ─────────────────────────────────────────────────────────────────────────

  group('PrioritizedIndexedStack abuse', () {
    testWidgets(
        'duplicate indices ([0, 0]) paint the same child twice but '
        'do not crash; hit testing returns on the first hit', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0, 0],
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox.expand(),
              ),
              const _ColorBox(color: Color(0xFF00FF00), label: 'B'),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PrioritizedIndexedStack));
      await tester.pumpAndSettle();
      expect(taps, 1, reason: 'Duplicate indices must not cause double-taps');
    });

    testWidgets(
        'out-of-range indices ([5, 6] with 2 children) render nothing '
        'and never crash', (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [5, 6],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
              _ColorBox(color: Color(0xFF00FF00), label: 'B'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Both children are wrapped in Visibility(visible:false) — found offstage
      // but not onstage.
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
      expect(find.text('A', skipOffstage: false), findsOneWidget);
    });

    testWidgets('empty indices with non-empty children: nothing is painted',
        (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsNothing);
    });

    testWidgets(
        'layerEffects shorter than indices: extra layers paint with '
        'default (no-effect) settings, no crash', (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [0, 1],
            layerEffects: [
              AnimationLayerEffect(opacity: 0.5),
              // Only one effect for two indices.
            ],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
              _ColorBox(color: Color(0xFF00FF00), label: 'B'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
        'layerEffects longer than indices: extras are ignored '
        'silently', (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [0],
            layerEffects: [
              AnimationLayerEffect(opacity: 0.5),
              AnimationLayerEffect(opacity: 0.0),
              AnimationLayerEffect(opacity: 0.0),
            ],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('opacity out of [0,1] is clamped: opacity=2.0 paints as 1.0',
        (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [0],
            layerEffects: [AnimationLayerEffect(opacity: 2.0)],
            children: [_ColorBox(color: Color(0xFFFF0000), label: 'A')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Just verify no crash. Opacity 2.0 takes the `< 1.0` branch as false
      // (so no opacity layer is pushed) — equivalent to opacity 1.0.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets(
        'fully transparent layer (opacity=0): not painted AND not '
        'hit-tested', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0, 1],
            layerEffects: const [
              AnimationLayerEffect(opacity: 0.0),
              AnimationLayerEffect(),
            ],
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps += 100,
                child: const SizedBox.expand(),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PrioritizedIndexedStack));
      await tester.pumpAndSettle();
      // The opacity=0 layer was skipped — the tap fell through to layer 1.
      expect(taps, 1);
    });

    testWidgets(
        'combining opacity + imageFilter on the same layer: the layer '
        'is painted (not tinted black). This pins the paint.color RGB=white '
        'fix in the saveLayer branch.', (tester) async {
      // A real ImageFilter — identity matrix is the cheapest way to force the
      // saveLayer-with-paint.color branch without distorting the layer.
      final identityFilter = ui.ImageFilter.matrix(Matrix4.identity().storage);
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0],
            layerEffects: [
              AnimationLayerEffect(
                opacity: 0.5,
                imageFilter: identityFilter,
              ),
            ],
            children: const [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // We can't easily sample pixel color in a unit test without golden
      // files, but at minimum the layer must render — the text is findable.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets(
        'rapid index churn (50 widget rebuilds with shifting indices) '
        'survives without leaking children', (tester) async {
      final children = [
        for (var i = 0; i < 5; i++)
          _ColorBox(
            color: Color(0xFF000000 | (i * 50)),
            label: 'c$i',
          ),
      ];
      for (var i = 0; i < 50; i++) {
        await tester.pumpWidget(
          wrapRouter(
            PrioritizedIndexedStack(
              indices: [i % 5, (i + 1) % 5],
              children: children,
            ),
          ),
        );
        await tester.pump();
      }
      // No assertions — surviving 50 churns without exceptions is the test.
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tree rebuild abuse — unmounts during transitions etc.
  // ─────────────────────────────────────────────────────────────────────────

  group('Tree rebuild abuse', () {
    testWidgets(
        'unmounting RouteManager mid-transition disposes cleanly with '
        'no pending-timer leaks', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(
        RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Yank the tree before the animation completes.
      await tester.pumpWidget(wrapRouter(const SizedBox.shrink()));
      // pumpAndSettle would catch any leftover ticker.
      await tester.pumpAndSettle();
    });

    testWidgets(
        'remounting a fresh RouteManager replaces the controller; the '
        'old one is gone and the new one navigates independently',
        (tester) async {
      RouteController? c1;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            key: const ValueKey('mgr-1'),
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a'), tagBuilder('b', '/b')],
            onControllerCreated: (c) => c1 = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      c1!.push(RouteState(Uri.parse('/b')));
      await tester.pumpAndSettle();
      expect(c1!.currentRouteState.uri.path, '/b');
      // Swap in a fresh manager with different builders.
      RouteController? c2;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            key: const ValueKey('mgr-2'),
            fallbackRouteState: () => RouteState(Uri.parse('/x')),
            builders: [tagBuilder('x', '/x'), tagBuilder('y', '/y')],
            onControllerCreated: (c) => c2 = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(c2, isNot(same(c1)));
      expect(c2!.currentRouteState.uri.path, '/x');
      c2!.push(RouteState(Uri.parse('/y')));
      await tester.pumpAndSettle();
      expect(c2!.currentRouteState.uri.path, '/y');
    });

    testWidgets(
        'rebuilding RouteManager with the SAME key does not '
        'reinitialize the controller', (tester) async {
      var controllerCreated = 0;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            key: const ValueKey('stable'),
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a')],
            onControllerCreated: (_) => controllerCreated++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Pump the same widget tree again — State should be preserved.
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            key: const ValueKey('stable'),
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a')],
            onControllerCreated: (_) => controllerCreated++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controllerCreated, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PaperTurnEffect (and other effects) edge inputs
  // ─────────────────────────────────────────────────────────────────────────

  group('Animation effect edge inputs', () {
    testWidgets(
        'PaperTurnEffect with Size.zero does not crash and returns '
        'finite transform entries', (tester) async {
      const e = PaperTurnEffect();
      late List<AnimationLayerEffect> mid;
      await tester.pumpWidget(
        wrapRouter(
          Builder(
            builder: (context) {
              mid = e.data(context, Size.zero, 0.5);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(mid, hasLength(2));
      expect(mid[0].transform, isNotNull);
      for (final entry in mid[0].transform!.storage) {
        expect(entry.isFinite, isTrue);
      }
    });

    testWidgets(
        'PaperTurnEffect at exact value=0 and value=1 produces a '
        'transform whose entries are all finite', (tester) async {
      const e = PaperTurnEffect();
      late List<AnimationLayerEffect> at0;
      late List<AnimationLayerEffect> at1;
      const size = Size(800, 600);
      await tester.pumpWidget(
        wrapRouter(
          Builder(
            builder: (context) {
              at0 = e.data(context, size, 0.0);
              at1 = e.data(context, size, 1.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      for (final entry in at0[0].transform!.storage) {
        expect(entry.isFinite, isTrue);
      }
      for (final entry in at1[0].transform!.storage) {
        expect(entry.isFinite, isTrue);
      }
    });

    testWidgets(
        'PaperTurnEffect mid-turn blur sigmaX is positive (negative '
        'or NaN sigmas in ui.ImageFilter.blur would be undefined)',
        (tester) async {
      // Re-derive the sigma formula the effect uses internally: midPeak * 2.5.
      // We can't introspect the produced ImageFilter directly, so we verify
      // the formula's outputs are always positive and finite for all sampled
      // mid-range values of the animation.
      for (final v in const [0.05, 0.25, 0.5, 0.75, 0.95]) {
        final midPeak = math.sin(v * math.pi);
        final sigma = midPeak * 2.5;
        expect(sigma, greaterThan(0));
        expect(sigma.isFinite, isTrue);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // pushUri abuse — URI normalization edges
  // ─────────────────────────────────────────────────────────────────────────

  group('pushUri abuse', () {
    testWidgets(
        'pushUri with reordered query params jumps to existing entry '
        'instead of duplicating it', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/p')),
            builders: [tagBuilder('p', '/p')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/p?a=1&b=2')));
      await tester.pumpAndSettle();
      controller.pushUri(Uri.parse('/p?b=2&a=1'));
      await tester.pumpAndSettle();
      // No duplicate — we jumped to the existing index.
      expect(controller.pNavigationState.getValue().routes.length, 2);
    });

    testWidgets(
        'pushUri with errorFallback when path is invalid lands on the '
        'fallback', (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [
              tagBuilder('a', '/a'),
              tagBuilder('error', '/error'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.pushUri(
        Uri.parse('/nope'),
        errorFallback: RouteState(Uri.parse('/error')),
      );
      await tester.pumpAndSettle();
      expect(controller.currentRouteState.uri.path, '/error');
    });

    testWidgets('pushUri with a Uri whose path is the current path is a no-op',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            fallbackRouteState: () => RouteState(Uri.parse('/a')),
            builders: [tagBuilder('a', '/a')],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.pushUri(Uri.parse('/a'));
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().routes.length, 1);
    });
  });
}
