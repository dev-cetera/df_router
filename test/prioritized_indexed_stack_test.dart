import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

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
  group('PrioritizedIndexedStack', () {
    testWidgets(
        'children at the supplied indices are rendered, others are '
        'hidden via Visibility.maintain (and remain in the tree)',
        (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [0],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
              _ColorBox(color: Color(0xFF00FF00), label: 'B'),
              _ColorBox(color: Color(0xFF0000FF), label: 'C'),
            ],
          ),
        ),
      );
      // Only the visible one is "onstage"; the others are kept around via
      // Visibility.maintain (skipOffstage:false reveals them).
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsNothing);
      expect(find.text('B', skipOffstage: false), findsOneWidget);
      expect(find.text('C', skipOffstage: false), findsOneWidget);
      // Exactly three Visibility widgets wrap them — one per child.
      expect(find.byType(Visibility, skipOffstage: false), findsNWidgets(3));
    });

    testWidgets('child at index -1 is treated as null (not rendered)',
        (tester) async {
      await tester.pumpWidget(
        wrapRouter(
          const PrioritizedIndexedStack(
            indices: [-1, 0],
            children: [
              _ColorBox(color: Color(0xFFFF0000), label: 'A'),
              _ColorBox(color: Color(0xFF00FF00), label: 'B'),
            ],
          ),
        ),
      );
      // Only index 0 is active. The -1 entry is a placeholder slot.
      final visibilities = tester
          .widgetList<Visibility>(find.byType(Visibility, skipOffstage: false))
          .toList();
      expect(visibilities.length, 2);
      // Index 0 is 'A' — should be visible.
      expect(visibilities[0].visible, isTrue);
      // Index 1 is 'B' — should NOT be visible (not in indices list).
      expect(visibilities[1].visible, isFalse);
    });

    testWidgets(
        'cached children identity is preserved across pumps when '
        'identical references are passed in', (tester) async {
      final cached = [
        const _ColorBox(color: Color(0xFFFF0000), label: 'A'),
        const _ColorBox(color: Color(0xFF00FF00), label: 'B'),
      ];

      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0],
            children: cached,
          ),
        ),
      );

      final firstA = find.text('A').evaluate().single;

      // Pump again with the SAME list of widgets, only layerEffects changing.
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0],
            layerEffects: const [AnimationLayerEffect(opacity: 0.5)],
            children: cached,
          ),
        ),
      );

      final secondA = find.text('A').evaluate().single;
      // Same Element ⇒ widget identity preserved ⇒ State preserved.
      expect(identical(firstA, secondA), isTrue);
    });

    testWidgets('updating only layerEffects does not rebuild wrapped children',
        (tester) async {
      final cached = [
        const _ColorBox(color: Color(0xFFFF0000), label: 'A'),
        const _ColorBox(color: Color(0xFF00FF00), label: 'B'),
      ];
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0, 1],
            children: cached,
          ),
        ),
      );
      final firstVis = tester
          .widgetList<Visibility>(find.byType(Visibility, skipOffstage: false))
          .toList();

      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0, 1],
            layerEffects: const [
              AnimationLayerEffect(opacity: 0.5),
              AnimationLayerEffect(opacity: 0.25),
            ],
            children: cached,
          ),
        ),
      );
      final secondVis = tester
          .widgetList<Visibility>(find.byType(Visibility, skipOffstage: false))
          .toList();
      // _wrappedChildren is recomputed only when children/indices change. With
      // identical inputs, the Visibility widgets should be the same instances.
      expect(identical(firstVis[0], secondVis[0]), isTrue);
      expect(identical(firstVis[1], secondVis[1]), isTrue);
    });
  });

  group('AnimationLayerEffect', () {
    test('equality compares all fields', () {
      const a = AnimationLayerEffect(opacity: 0.5);
      const b = AnimationLayerEffect(opacity: 0.5);
      const c = AnimationLayerEffect(opacity: 0.6);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('isIdentity is true when all fields are null/default', () {
      const a = AnimationLayerEffect();
      expect(a.isIdentity, isTrue);
    });

    test('isIdentity false when opacity < 1.0', () {
      const a = AnimationLayerEffect(opacity: 0.5);
      expect(a.isIdentity, isFalse);
    });

    test('hasVisualEffects respects opacity threshold', () {
      const opaque = AnimationLayerEffect(opacity: 1.0);
      const semi = AnimationLayerEffect(opacity: 0.5);
      expect(opaque.hasVisualEffects, isFalse);
      expect(semi.hasVisualEffects, isTrue);
    });
  });

  group('Hit testing', () {
    testWidgets(
        'AnimationLayerEffect.ignorePointer suppresses hits on '
        'that layer', (tester) async {
      var bottomTaps = 0;
      var topTaps = 0;
      await tester.pumpWidget(
        wrapRouter(
          PrioritizedIndexedStack(
            indices: const [0, 1],
            // Layer order: index 0 painted on top.
            layerEffects: const [
              AnimationLayerEffect(ignorePointer: true),
              AnimationLayerEffect(),
            ],
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => topTaps++,
                child: const SizedBox.expand(),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bottomTaps++,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PrioritizedIndexedStack));
      await tester.pumpAndSettle();
      // Top layer ignores pointer ⇒ bottom layer receives tap.
      expect(topTaps, 0);
      expect(bottomTaps, 1);
    });

    testWidgets('opacity 0 layer also gets skipped during hit testing',
        (tester) async {
      var bottomTaps = 0;
      var topTaps = 0;
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
                onTap: () => topTaps++,
                child: const SizedBox.expand(),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bottomTaps++,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PrioritizedIndexedStack));
      await tester.pumpAndSettle();
      expect(topTaps, 0);
      expect(bottomTaps, 1);
    });
  });
}
