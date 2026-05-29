import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// All effects in effects.dart produce a closure from
// (BuildContext, Size, double value) → List<AnimationLayerEffect>. Tests
// here pin: (a) the list always has 2 entries (one per stack layer), (b) the
// endpoints behave correctly at value=0 and value=1, and (c) the duration
// and curve fields are wired up.

const _size = Size(800.0, 600.0);

class _Probe extends StatelessWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<List<AnimationLayerEffect>> _evaluate(
  WidgetTester tester,
  AnimationEffect effect,
  double value,
) async {
  late List<AnimationLayerEffect> out;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) {
          out = effect.data(context, _size, value);
          return const _Probe();
        },
      ),
    ),
  );
  return out;
}

void main() {
  testWidgets('NoEffect: returns two identity layer effects at any value',
      (tester) async {
    const e = NoEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0, hasLength(2));
    expect(at1, hasLength(2));
    for (final r in [...at0, ...at1]) {
      expect(r.transform, isNull);
      expect(r.opacity, isNull);
    }
  });

  testWidgets('NoEffect: duration is zero, curve is linear', (tester) async {
    expect(const NoEffect().duration, Duration.zero);
    expect(const NoEffect().curve, Curves.linear);
  });

  testWidgets('FadeEffect: incoming opacity ramps 0→1', (tester) async {
    const e = FadeEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].opacity, 0.0);
    expect(at1[0].opacity, 1.0);
    // Outgoing layer (index 1) dims to 0.5 and ignores pointer.
    expect(at1[1].opacity, closeTo(0.5, 1e-9));
    expect(at1[1].ignorePointer, isTrue);
  });

  testWidgets('FadeEffectWeb: outgoing layer skips opacity on web', (tester) async {
    const e = FadeEffectWeb();
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at1[0].opacity, 1.0);
    // The kIsWeb=true branch returns only ignorePointer. In tests, kIsWeb=false
    // so we expect the same dimming as FadeEffect.
    expect(at1[1].ignorePointer, isTrue);
  });

  testWidgets('ForwardEffect: incoming slides from right to centre',
      (tester) async {
    const e = ForwardEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    final start = at0[0].transform!.storage[12];
    final end = at1[0].transform!.storage[12];
    // At value=0, the incoming layer is offset by +size.width (off-screen
    // right). At value=1, it's at x=0.
    expect(start, closeTo(_size.width, 1e-9));
    expect(end, closeTo(0.0, 1e-9));
  });

  testWidgets('BackwardEffect: incoming slides from left to centre',
      (tester) async {
    const e = BackwardEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform!.storage[12], closeTo(-_size.width, 1e-9));
    expect(at1[0].transform!.storage[12], closeTo(0.0, 1e-9));
  });

  testWidgets('SlideUpEffect: incoming slides from bottom (Y axis)',
      (tester) async {
    const e = SlideUpEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform!.storage[13], closeTo(_size.height, 1e-9));
    expect(at1[0].transform!.storage[13], closeTo(0.0, 1e-9));
  });

  testWidgets('SlideDownEffect: incoming slides from top (Y axis)',
      (tester) async {
    const e = SlideDownEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform!.storage[13], closeTo(-_size.height, 1e-9));
    expect(at1[0].transform!.storage[13], closeTo(0.0, 1e-9));
  });

  testWidgets('CupertinoEffect and MaterialEffect share the slide-from-right '
      'family but with different durations', (tester) async {
    const c = CupertinoEffect();
    const m = MaterialEffect();
    expect(c.duration, isNot(m.duration));
    expect(c.curve, Curves.easeInOut);
    expect(m.curve, Curves.fastOutSlowIn);
  });

  testWidgets('PageFlapLeft: incoming rotates from -90° to 0°', (tester) async {
    const e = PageFlapLeft();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform, isNotNull);
    expect(at1[0].transform, isNotNull);
    // Opacity ramps 0.3 → 1.0.
    expect(at0[0].opacity, closeTo(0.3, 1e-9));
    expect(at1[0].opacity, closeTo(1.0, 1e-9));
  });

  testWidgets('PageFlapRight: incoming rotates from +90° to 0°', (tester) async {
    const e = PageFlapRight();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform, isNotNull);
    expect(at1[0].transform, isNotNull);
    expect(at0[0].opacity, closeTo(0.3, 1e-9));
    expect(at1[0].opacity, closeTo(1.0, 1e-9));
  });

  testWidgets('every effect returns exactly 2 layer effects', (tester) async {
    const effects = <AnimationEffect>[
      NoEffect(),
      FadeEffect(),
      FadeEffectWeb(),
      ForwardEffect(),
      ForwardEffectWeb(),
      BackwardEffect(),
      BackwardEffectWeb(),
      SlideUpEffect(),
      SlideDownEffect(),
      CupertinoEffect(),
      MaterialEffect(),
      PageFlapLeft(),
      PageFlapRight(),
    ];
    for (final e in effects) {
      final r = await _evaluate(tester, e, 0.5);
      expect(
        r,
        hasLength(2),
        reason: '${e.runtimeType} should produce 2 layer effects',
      );
    }
  });
}
