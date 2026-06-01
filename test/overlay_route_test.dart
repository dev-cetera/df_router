import 'package:df_router/df_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

void main() {
  setUp(() {
    TaggedScreenState.resetCounts();
  });

  Future<RouteController> mount(
    WidgetTester tester, {
    required List<RouteBuilder> builders,
    required RouteState Function() fallbackRouteState,
    RouteState Function()? initialRouteState,
  }) async {
    late RouteController controller;
    await tester.pumpWidget(
      wrapRouter(
        RouteManager(
          initialRouteState: initialRouteState,
          fallbackRouteState: fallbackRouteState,
          builders: builders,
          onControllerCreated: (c) => controller = c,
        ),
      ),
    );
    return controller;
  }

  group('isOverlay flag', () {
    testWidgets(
      'when an overlay route is pushed, the base route stays alive '
      'even if its own shouldPreserve is false',
      (tester) async {
        final controller = await mount(
          tester,
          builders: [
            // Base is NOT preserved; without isOverlay protection it would be
            // disposed when the overlay transition completes.
            tagBuilder('home', '/home'),
            tagBuilder('modal', '/modal', isOverlay: true),
          ],
          fallbackRouteState: () => RouteState(Uri.parse('/home')),
        );
        await tester.pumpAndSettle();
        expect(TaggedScreenState.initCounts['home'], 1);
        expect(TaggedScreenState.disposeCounts['home'], isNull);

        controller.push(RouteState(Uri.parse('/modal')));
        await tester.pumpAndSettle();

        expect(TaggedScreenState.initCounts['modal'], 1);
        // The base must NOT have been disposed — the modal needs it underneath.
        expect(TaggedScreenState.disposeCounts['home'], isNull);
        // And the base widget instance must still respond to builds, proving
        // the cache entry wasn't replaced with a SizedBox.shrink placeholder.
        expect(
          find.text('home'),
          findsOneWidget,
          reason: 'base widget should still be in the tree under the modal',
        );
      },
    );

    testWidgets(
      'navigating away from the overlay drops the modal (without preservation) '
      'and leaves the base behind',
      (tester) async {
        final controller = await mount(
          tester,
          builders: [
            tagBuilder('home', '/home'),
            tagBuilder('modal', '/modal', isOverlay: true),
          ],
          fallbackRouteState: () => RouteState(Uri.parse('/home')),
        );
        controller.push(RouteState(Uri.parse('/modal')));
        await tester.pumpAndSettle();
        expect(TaggedScreenState.initCounts['modal'], 1);

        controller.goBackward();
        await tester.pumpAndSettle();

        // Modal had no preservation flag, so it gets disposed; the protection
        // only applies while the overlay is the current route.
        expect(TaggedScreenState.disposeCounts['modal'], 1);
        expect(controller.currentRouteState.uri.path, '/home');
      },
    );

    testWidgets(
      'pushing a non-overlay route on top of the modal lifts the base '
      'protection — base eviction now follows its own preservation flag',
      (tester) async {
        final controller = await mount(
          tester,
          builders: [
            tagBuilder('home', '/home'),
            tagBuilder('modal', '/modal', isOverlay: true),
            tagBuilder('next', '/next'),
          ],
          fallbackRouteState: () => RouteState(Uri.parse('/home')),
        );
        controller.push(RouteState(Uri.parse('/modal')));
        await tester.pumpAndSettle();
        controller.push(RouteState(Uri.parse('/next')));
        await tester.pumpAndSettle();

        // After /next is current (not an overlay), the modal becomes a stale
        // previous-for-transition and gets evicted normally.
        expect(TaggedScreenState.disposeCounts['modal'], 1);
      },
    );
  });
}
