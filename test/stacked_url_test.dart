import 'package:df_router/df_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

/// Mirrors what the controller itself would send to `pushState` — encodes
/// the visible stack in the path, with the standard `?` clause for the
/// active route's query, and the forward portion in the fragment.
Uri _encodeViaController(RouteController controller) {
  final state = controller.pNavigationState.getValue();
  final visible = [for (var i = 0; i <= state.index; i++) state.routes[i].uri];
  final base = RouteStackUri.encode(visible);
  if (state.index >= state.routes.length - 1) return base;
  final forward = [
    for (var i = state.index + 1; i < state.routes.length; i++)
      state.routes[i].uri,
  ];
  return base.replace(fragment: RouteStackUri.encodeSegments(forward));
}

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

    testWidgets(
        'goBackward shortens the visible stack (index moves but the '
        'forward routes are kept so canGoForward still works)', (tester) async {
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

    testWidgets(
        'encoded URL for a stacked controller round-trips through '
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
        for (var i = 0; i <= controller.pNavigationState.getValue().index; i++)
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

    testWidgets(
      'pushing routes (each carrying its own queryParameters) grows the '
      'encoded stack URL with + separators AND preserves per-route queries '
      'via the matrix-style ; clause',
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

        controller.push(
          RouteState(Uri.parse('/sheet'), queryParameters: {'tab': '2'}),
        );
        await tester.pumpAndSettle();
        controller.push(
          RouteState(Uri.parse('/dialog'), queryParameters: {'confirm': 'y'}),
        );
        await tester.pumpAndSettle();

        // What the controller would feed `pushState` with: full encoded stack.
        final state = controller.pNavigationState.getValue();
        final encoded = RouteStackUri.encode(
          [for (var i = 0; i <= state.index; i++) state.routes[i].uri],
        );

        // The bottom-stack /sheet's `?tab=2` becomes `;tab=2` in the path;
        // the top /dialog's `?confirm=y` stays in the standard ? clause.
        expect(encoded.path, '/home+/sheet;tab=2+/dialog');
        expect(encoded.queryParameters, {'confirm': 'y'});
        expect(
          encoded.toString(),
          '/home+/sheet;tab=2+/dialog?confirm=y',
        );

        // And the standard Uri parse still reads the active route's params.
        expect(
          Uri.parse(encoded.toString()).queryParameters,
          {'confirm': 'y'},
        );
      },
    );

    testWidgets(
      'identity-keyed cache: six push()es of the same URI produce six '
      'distinct widget elements (initState fires six times) so dismissing '
      'the top one only dismisses ITS state — not all of them',
      (tester) async {
        final controller = await mountStacked(
          tester,
          builders: [
            tagBuilder('home', '/home'),
            tagBuilder('dialog', '/dialog', isOverlay: true),
          ],
          fallbackRouteState: () => RouteState(Uri.parse('/home')),
        );
        // Six separate pushes with skipCurrent=false so the controller
        // doesn't no-op on the same-URI-as-current case.
        for (var i = 0; i < 6; i++) {
          controller.push(
            RouteState(Uri.parse('/dialog'), skipCurrent: false),
          );
          await tester.pumpAndSettle();
        }
        // The /dialog screen's initState should have fired SIX times — one
        // per push — proving each push has its own widget element rather
        // than collapsing into a single shared instance.
        expect(TaggedScreenState.initCounts['dialog'], 6);
      },
    );

    testWidgets(
      'pushUri with a stack-encoded URI ("/sheet+/dialog") appends ALL '
      'segments in a single call',
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
        controller.pushUri(Uri.parse('/sheet+/dialog'));
        await tester.pumpAndSettle();
        expect(
          controller.pNavigationState.getValue().routes.map((r) => r.uri.path),
          ['/home', '/sheet', '/dialog'],
        );
        expect(controller.pNavigationState.getValue().index, 2);
      },
    );

    testWidgets(
      'push(RouteState) where the route\'s uri is stack-encoded works the '
      'same as pushUri — convenience for callers that already hold a '
      'RouteState',
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
        controller.push(RouteState(Uri.parse('/sheet+/dialog')));
        await tester.pumpAndSettle();
        expect(
          controller.pNavigationState.getValue().routes.map((r) => r.uri.path),
          ['/home', '/sheet', '/dialog'],
        );
      },
    );

    testWidgets(
      'registering a route whose path contains the stack delimiter "+" '
      'throws an ArgumentError under UrlStrategy.stacked — must happen at '
      'controller construction so the misconfiguration cannot ship',
      (tester) async {
        expect(
          () => RouteController(
            urlStrategy: UrlStrategy.stacked,
            fallbackRouteState: () => RouteState(Uri.parse('/home')),
            builders: [
              tagBuilder('home', '/home'),
              tagBuilder('weird', '/has+plus'),
            ],
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    testWidgets(
      'the same "+" in a registered path is ALLOWED under UrlStrategy.flat '
      'because flat URLs do not reserve "+" as a delimiter — back-compat '
      'with apps that used "+" in paths before stacked URLs existed',
      (tester) async {
        // Constructor should NOT throw — UrlStrategy.flat doesn't care about
        // the `+` delimiter at all.
        expect(
          () => RouteController(
            // urlStrategy defaults to flat.
            fallbackRouteState: () => RouteState(Uri.parse('/home')),
            builders: [
              tagBuilder('home', '/home'),
              tagBuilder('weird', '/has+plus'),
            ],
          ),
          returnsNormally,
        );
      },
    );

    testWidgets(
      'goBackward encodes forward-history routes into the URL fragment, '
      'so a reload of "/home+/sheet#/dialog" still knows that /dialog is '
      'reachable via goForward',
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

        // Stack is [/home, /sheet, /dialog], index=2. URL = /home+/sheet+/dialog.
        controller.goBackward();
        await tester.pumpAndSettle();

        // After goBackward: index=1 (showing /sheet), but routes still
        // hold /dialog so goForward works. The URL must now encode /dialog
        // in the fragment so a reload preserves the forward direction.
        final state = controller.pNavigationState.getValue();
        expect(state.index, 1);
        expect(state.routes.map((r) => r.uri.path), [
          '/home',
          '/sheet',
          '/dialog',
        ]);

        final encoded = _encodeViaController(controller);
        expect(encoded.path, '/home+/sheet');
        expect(encoded.fragment, '/dialog');
        expect(encoded.toString(), '/home+/sheet#/dialog');
      },
    );

    testWidgets(
      'goForward after a goBackward drains the fragment — once the user is '
      'back at the top of the stack, the URL has no forward portion',
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
        controller.goForward();
        await tester.pumpAndSettle();

        final encoded = _encodeViaController(controller);
        expect(encoded.path, '/home+/sheet+/dialog');
        expect(encoded.fragment, isEmpty);
      },
    );

    testWidgets(
      'forward-history routes preserve per-route query params via the '
      'fragment\'s ";" matrix syntax — round-trip a 3-stack with each route '
      'carrying its own query, step back twice, encode, decode, check params',
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
        controller.push(
          RouteState(Uri.parse('/sheet'), queryParameters: {'tab': '2'}),
        );
        await tester.pumpAndSettle();
        controller.push(
          RouteState(Uri.parse('/dialog'), queryParameters: {'confirm': 'y'}),
        );
        await tester.pumpAndSettle();
        controller.goBackward();
        await tester.pumpAndSettle();
        controller.goBackward();
        await tester.pumpAndSettle();

        // Stack is [/home, /sheet?tab=2, /dialog?confirm=y], index=0.
        // Active route is /home (no query). The fragment must carry the
        // forward routes with their queryParameters encoded.
        final encoded = _encodeViaController(controller);
        expect(encoded.path, '/home');
        // /sheet's tab=2 and /dialog's confirm=y both must round-trip.
        final forwardUris = RouteStackUri.decodeSegments(encoded.fragment);
        expect(forwardUris, hasLength(2));
        expect(forwardUris[0].path, '/sheet');
        expect(forwardUris[0].queryParameters, {'tab': '2'});
        expect(forwardUris[1].path, '/dialog');
        expect(forwardUris[1].queryParameters, {'confirm': 'y'});
      },
    );

    testWidgets(
      'pushing a new route while there\'s forward history TRUNCATES forward — '
      'classic browser semantics: new push wipes the redo stack and the URL '
      'fragment is empty afterward',
      (tester) async {
        final controller = await mountStacked(
          tester,
          builders: [
            tagBuilder('home', '/home'),
            tagBuilder('sheet', '/sheet', isOverlay: true),
            tagBuilder('dialog', '/dialog', isOverlay: true),
            tagBuilder('toast', '/toast', isOverlay: true),
          ],
          fallbackRouteState: () => RouteState(Uri.parse('/home')),
        );
        controller.push(RouteState(Uri.parse('/sheet')));
        await tester.pumpAndSettle();
        controller.push(RouteState(Uri.parse('/dialog')));
        await tester.pumpAndSettle();
        controller.goBackward();
        await tester.pumpAndSettle();
        // Now: [/home, /sheet, /dialog], index=1, fragment has /dialog.
        controller.push(RouteState(Uri.parse('/toast')));
        await tester.pumpAndSettle();

        // After the push: forward is truncated, /dialog is gone.
        final state = controller.pNavigationState.getValue();
        expect(state.routes.map((r) => r.uri.path), [
          '/home',
          '/sheet',
          '/toast',
        ]);
        expect(state.index, 2);
        final encoded = _encodeViaController(controller);
        expect(encoded.path, '/home+/sheet+/toast');
        expect(encoded.fragment, isEmpty);
      },
    );

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
