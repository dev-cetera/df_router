import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

// The CRITICAL invariant for this router: during a transition, the OUTGOING
// route's widget must stay alive and painted so the animation can show it
// underneath the incoming one. Optimizations must not regress this.

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

void main() {
  setUp(() {
    TaggedScreenState.resetCounts();
  });

  Future<RouteController> mount(
    WidgetTester tester, {
    required List<RouteBuilder> builders,
    required RouteState Function() fallback,
  }) async {
    late RouteController controller;
    await tester.pumpWidget(
      wrapRouter(
        RouteManager(
          fallbackRouteState: fallback,
          builders: builders,
          onControllerCreated: (c) => controller = c,
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets(
      'during a push transition, BOTH the incoming and outgoing '
      'route widgets are mounted in the tree', (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('B', '/b', animationEffect: const _SlowEffect()),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);

    controller.push(
      RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
    );
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 100)); // mid-transition

    // BOTH routes are in the element tree during the transition.
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsOneWidget);

    await tester.pumpAndSettle();
    // After settle, A (not preserved) is replaced with a SizedBox placeholder.
    expect(find.text('A', skipOffstage: false), findsNothing);
    expect(find.text('B', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'during a pop (goBackward) transition with a preserved '
      'destination, both the route being popped AND the route being revealed '
      'are mounted, and the destination is NOT re-initialized', (tester) async {
    // This is the user-facing "transitions show what is behind" invariant.
    // The destination (A) must keep its State across the pop animation when
    // it was flagged shouldPreserve. The route being popped (B) must stay
    // rendered until the animation completes so it can visibly slide/fade off.
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a', shouldPreserve: true),
        tagBuilder('B', '/b', animationEffect: const _SlowEffect()),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );

    controller.push(
      RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
    );
    await tester.pumpAndSettle();
    expect(find.text('B', skipOffstage: false), findsOneWidget);

    final initBefore = TaggedScreenState.initCounts['A']!;
    controller.goBackward(animationEffect: const _SlowEffect());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsOneWidget);
    expect(
      TaggedScreenState.initCounts['A'],
      initBefore,
      reason: 'shouldPreserve:true means A keeps its State across the pop',
    );

    await tester.pumpAndSettle();
    expect(find.text('A', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'during a push transition with a preserved outgoing route, '
      'the outgoing route stays mounted (visible behind the incoming one)',
      (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a', shouldPreserve: true),
        tagBuilder('B', '/b', animationEffect: const _SlowEffect()),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    expect(TaggedScreenState.initCounts['A'], 1);

    controller.push(
      RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // mid-animation
    // A must remain mounted *during* the transition.
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsOneWidget);
    // And NOT re-initialized.
    expect(TaggedScreenState.initCounts['A'], 1);

    await tester.pumpAndSettle();
    // After settle, A is preserved (shouldPreserve).
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(TaggedScreenState.initCounts['A'], 1);
  });

  testWidgets('preserved routes survive past the transition completion',
      (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a', shouldPreserve: true),
        tagBuilder('B', '/b'),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    final initA = TaggedScreenState.initCounts['A']!;

    controller.push(RouteState(Uri.parse('/b')));
    await tester.pumpAndSettle();

    // Even after settle, A is preserved — its element is still in the tree.
    expect(find.text('A', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsOneWidget);
    // And its State has not been re-initialized.
    expect(TaggedScreenState.initCounts['A'], initA);
  });

  testWidgets(
      'non-preserved outgoing route is replaced with a SizedBox '
      'placeholder after the transition completes (cache slot retained)',
      (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('B', '/b'),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );

    controller.push(RouteState(Uri.parse('/b')));
    await tester.pumpAndSettle();

    // A is no longer findable by its tag — its widget was replaced.
    expect(find.text('A', skipOffstage: false), findsNothing);
    // And the dispose was actually called on its State.
    expect(TaggedScreenState.disposeCounts['A'], 1);
  });

  testWidgets(
      'two consecutive pushes: only the most recent transition is '
      'animating; the very first route is gone after both settle',
      (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('B', '/b'),
        tagBuilder('C', '/c'),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    controller.push(RouteState(Uri.parse('/b')));
    await tester.pumpAndSettle();
    controller.push(RouteState(Uri.parse('/c')));
    await tester.pumpAndSettle();
    // Only C remains visible. A was popped from the cache after B settled,
    // B after C settled.
    expect(find.text('C', skipOffstage: false), findsOneWidget);
    expect(find.text('B', skipOffstage: false), findsNothing);
    expect(find.text('A', skipOffstage: false), findsNothing);
  });

  testWidgets(
      'prebuilt route does NOT count as the rendered route — only '
      'the active route is painted on top', (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('Prebuilt', '/prebuilt', shouldPrebuild: true),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    // Prebuilt is built at controller-init time but not displayed.
    expect(TaggedScreenState.initCounts['Prebuilt'], 1);
    // It is in the tree (cached), but not visible.
    expect(find.text('Prebuilt', skipOffstage: false), findsOneWidget);
    expect(find.text('Prebuilt'), findsNothing); // offstage by default
    expect(find.text('A'), findsOneWidget); // active and visible
    controller.push(RouteState(Uri.parse('/prebuilt')));
    await tester.pumpAndSettle();
    expect(TaggedScreenState.initCounts['Prebuilt'], 1); // not re-inited
    expect(find.text('Prebuilt'), findsOneWidget);
  });

  testWidgets('layer order: the active route paints OVER the outgoing route',
      (tester) async {
    // During a transition, indices=[currentIdx, previousIdx]. In paint(), the
    // stack iterates indices from last to first, so children at lower-index
    // (in the indices list) end up on top. currentIdx is at position 0 in the
    // indices list ⇒ painted last ⇒ on top.
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('B', '/b', animationEffect: const _SlowEffect()),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    controller.push(
      RouteState(Uri.parse('/b'), animationEffect: const _SlowEffect()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Find the PrioritizedIndexedStack widget and read its indices.
    final stack = tester.widget<PrioritizedIndexedStack>(
      find.byType(PrioritizedIndexedStack),
    );
    expect(stack.indices.length, 2);
    // Both indices must be valid (non -1).
    expect(stack.indices[0], isNot(-1));
    expect(stack.indices[1], isNot(-1));
    // They must point at different cache entries (current vs previous).
    expect(stack.indices[0], isNot(stack.indices[1]));

    await tester.pumpAndSettle();
  });

  testWidgets('clearHistory does not tear down the current route',
      (tester) async {
    final controller = await mount(
      tester,
      builders: [
        tagBuilder('A', '/a'),
        tagBuilder('B', '/b'),
      ],
      fallback: () => RouteState(Uri.parse('/a')),
    );
    controller.push(RouteState(Uri.parse('/b')));
    await tester.pumpAndSettle();
    final initBefore = TaggedScreenState.initCounts['B']!;
    controller.clearHistory();
    await tester.pumpAndSettle();
    // B was the current route and stays alive — its State must NOT be re-inited.
    expect(TaggedScreenState.initCounts['B'], initBefore);
    expect(find.text('B'), findsOneWidget);
  });
}
