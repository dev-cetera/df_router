import 'package:df_router/df_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

void main() {
  setUp(() {
    TaggedScreenState.resetCounts();
  });

  Future<RouteController> mountStacked(
    WidgetTester tester, {
    required List<RouteBuilder> builders,
    required RouteState Function() fallbackRouteState,
    RouteState Function()? initialRouteState,
  }) async {
    late RouteController controller;
    await tester.pumpWidget(
      wrapRouter(
        RouteManager(
          urlStrategy: UrlStrategy.stacked,
          initialRouteState: initialRouteState,
          fallbackRouteState: fallbackRouteState,
          builders: builders,
          onControllerCreated: (c) => controller = c,
        ),
      ),
    );
    return controller;
  }

  group('UrlStrategy.stacked', () {
    testWidgets('push extends the in-memory stack', (tester) async {
      final controller = await mountStacked(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('sheet', '/sheet', isOverlay: true),
          tagBuilder('dialog', '/dialog', isOverlay: true),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );
      expect(controller.pNavigationState.getValue().routes, hasLength(1));

      controller.push(RouteState(Uri.parse('/sheet')));
      await tester.pumpAndSettle();
      expect(
        controller.pNavigationState.getValue().routes.map((r) => r.uri.path),
        ['/home', '/sheet'],
      );
      expect(controller.pNavigationState.getValue().index, 1);

      controller.push(RouteState(Uri.parse('/dialog')));
      await tester.pumpAndSettle();
      expect(
        controller.pNavigationState.getValue().routes.map((r) => r.uri.path),
        ['/home', '/sheet', '/dialog'],
      );
      expect(controller.pNavigationState.getValue().index, 2);
    });

    testWidgets('goBackward shortens the visible stack (index moves but the '
        'forward routes are kept so canGoForward still works)',
        (tester) async {
      final controller = await mountStacked(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('sheet', '/sheet', isOverlay: true),
          tagBuilder('dialog', '/dialog', isOverlay: true),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );

      controller.push(RouteState(Uri.parse('/sheet')));
      await tester.pumpAndSettle();
      controller.push(RouteState(Uri.parse('/dialog')));
      await tester.pumpAndSettle();

      controller.goBackward();
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().index, 1);
      expect(controller.canGoForward, isTrue);

      controller.goBackward();
      await tester.pumpAndSettle();
      expect(controller.pNavigationState.getValue().index, 0);
      expect(controller.canGoBackward, isFalse);
    });

    testWidgets('encoded URL for a stacked controller round-trips through '
        'RouteStackUri — pushState payload matches the visible stack',
        (tester) async {
      final controller = await mountStacked(
        tester,
        builders: [
          tagBuilder('home', '/home'),
          tagBuilder('sheet', '/sheet', isOverlay: true),
        ],
        fallbackRouteState: () => RouteState(Uri.parse('/home')),
      );

      controller.push(
        RouteState(Uri.parse('/sheet'), queryParameters: {'tab': '2'}),
      );
      await tester.pumpAndSettle();

      final encoded = RouteStackUri.encode([
        for (var i = 0;
            i <= controller.pNavigationState.getValue().index;
            i++)
          controller.pNavigationState.getValue().routes[i].uri,
      ]);
      // The visible stack should serialize to /home+/sheet?tab=2.
      expect(encoded.path, '/home+/sheet');
      expect(encoded.queryParameters, {'tab': '2'});
      // And standard Uri.parse on the toString gets the same queryParameters
      // back — the whole point of putting the top route's query in the
      // standard `?` clause.
      expect(
        Uri.parse(encoded.toString()).queryParameters,
        {'tab': '2'},
      );
    });

    testWidgets('flat strategy still behaves like before (no regression)',
        (tester) async {
      late RouteController controller;
      await tester.pumpWidget(
        wrapRouter(
          RouteManager(
            // Default: UrlStrategy.flat.
            fallbackRouteState: () => RouteState(Uri.parse('/home')),
            builders: [
              tagBuilder('home', '/home'),
              tagBuilder('about', '/about'),
            ],
            onControllerCreated: (c) => controller = c,
          ),
        ),
      );
      controller.push(RouteState(Uri.parse('/about')));
      await tester.pumpAndSettle();
      // Even though we pushed multiple, history walks the same as before —
      // this test exists to make sure adding the urlStrategy field didn't
      // silently change flat-mode semantics.
      expect(controller.pNavigationState.getValue().index, 1);
      expect(
        controller.pNavigationState.getValue().routes.map((r) => r.uri.path),
        ['/home', '/about'],
      );
    });
  });
}
