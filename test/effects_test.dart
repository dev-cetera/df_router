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

  testWidgets('FadeEffectWeb: outgoing layer skips opacity on web',
      (tester) async {
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

  testWidgets(
      'CupertinoEffect and MaterialEffect share the slide-from-right '
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

  testWidgets('PageFlapRight: incoming rotates from +90° to 0°',
      (tester) async {
    const e = PageFlapRight();
    final at0 = await _evaluate(tester, e, 0.0);
    final at1 = await _evaluate(tester, e, 1.0);
    expect(at0[0].transform, isNotNull);
    expect(at1[0].transform, isNotNull);
    expect(at0[0].opacity, closeTo(0.3, 1e-9));
    expect(at1[0].opacity, closeTo(1.0, 1e-9));
  });

  testWidgets(
      'PaperTurnEffect: the static INCOMING layer (slot 1) carries '
      'no transform at any value — the background page sits dead-flat '
      'underneath the rotating outgoing page from start to finish. This is '
      'the equivalent of the old "lands FLAT" invariant under the redesigned '
      'semantics where the OUTGOING does the visible motion.', (tester) async {
    const e = PaperTurnEffect();
    for (final v in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final at = await _evaluate(tester, e, v);
      expect(
        at[1].transform,
        isNull,
        reason: 'static background layer must have no transform at value=$v',
      );
    }
  });

  testWidgets(
      'PaperTurnEffect: previousOnTop is true (the outgoing page is '
      'the visible mover, so the router renders it in the top slot)',
      (tester) async {
    const e = PaperTurnEffect();
    expect(e.previousOnTop, isTrue);
  });

  testWidgets(
      'PaperTurnEffect: endpoints are clean (no blur, no scrim) and '
      'the mid-turn frame has all secondary effects active', (tester) async {
    const e = PaperTurnEffect();
    final at0 = await _evaluate(tester, e, 0.0);
    final atMid = await _evaluate(tester, e, 0.5);
    final at1 = await _evaluate(tester, e, 1.0);

    // ENDPOINTS: blur (on outgoing) and scrim (on incoming) are skipped at
    // value 0 / 1 because the `midPeak > 0.1` / `> 0.05` gates evaluate to
    // false. The outgoing opacity starts at 1.0 at value=0; at value=1 it
    // tapers to 0 (so the page is invisible by the time it's rotated
    // edge-on, preventing the anti-aliased edge-line flicker between
    // transitions). The incoming layer never sets opacity (so it's null,
    // which the renderer treats as 1.0).
    expect(at0[0].imageFilter, isNull);
    expect(at1[0].imageFilter, isNull);
    expect(at0[1].colorFilter, isNull);
    expect(at1[1].colorFilter, isNull);
    expect(at0[0].opacity, closeTo(1.0, 1e-9));
    expect(at1[0].opacity, closeTo(0.0, 1e-9));
    expect(at0[1].opacity, isNull);
    expect(at1[1].opacity, isNull);

    // MID-TURN: blur on the outgoing page (slot 0), scrim on the incoming
    // page (slot 1), transform on the outgoing page. The OUTGOING also
    // ignores hits during the whole animation so taps fall through to the
    // incoming page underneath (and so the incoming stays interactive once
    // the outgoing is replaced with a `SizedBox.shrink` placeholder after
    // the transition completes).
    expect(atMid[0].imageFilter, isNotNull, reason: 'motion blur on outgoing');
    expect(atMid[1].colorFilter, isNotNull, reason: 'scrim on incoming bg');
    expect(atMid[0].transform, isNotNull, reason: 'rotated+sheared+lifted');
    expect(atMid[0].ignorePointer, isTrue, reason: 'outgoing ignores hits');
    expect(
      atMid[1].ignorePointer,
      isNot(isTrue),
      reason: 'incoming must remain hittable',
    );
  });

  testWidgets(
      'PaperTurnBackEffect plays PaperTurnEffect in REVERSE time: '
      'the incoming page is the visible mover (previousOnTop=false) and '
      'the layer effects at value=v match the forward effect at value=1-v, '
      'modulo the swapped slot roles', (tester) async {
    const e = PaperTurnBackEffect();
    // Default — incoming is the visible mover, slot 0 holds the transform.
    expect(e.previousOnTop, isFalse);

    // Static-outgoing invariant — slot 1 carries no transform at any v.
    for (final v in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final at = await _evaluate(tester, e, v);
      expect(at[1].transform, isNull, reason: 'static layer at value=$v');
    }

    final at0 = await _evaluate(tester, e, 0.0);
    final atMid = await _evaluate(tester, e, 0.5);
    final at1 = await _evaluate(tester, e, 1.0);

    // Endpoints: no blur, no scrim (midPeak=0 at both endpoints regardless
    // of time direction, since sin(πv) = sin(π(1-v))).
    expect(at0[0].imageFilter, isNull);
    expect(at1[0].imageFilter, isNull);
    expect(at0[1].colorFilter, isNull);
    expect(at1[1].colorFilter, isNull);

    // Mid-turn: blur on the incoming (transforming), scrim on the outgoing.
    expect(atMid[0].imageFilter, isNotNull);
    expect(atMid[1].colorFilter, isNotNull);
    expect(atMid[0].transform, isNotNull);

    // Hit-test routing: outgoing (slot 1) ignores hits so taps reach the
    // incoming (slot 0) as soon as it un-rotates back to flat.
    expect(atMid[0].ignorePointer, isNot(isTrue));
    expect(atMid[1].ignorePointer, isTrue);

    // Opacity arc is time-reversed: the incoming starts at 0 (invisible
    // because it's edge-on and faded) and ends at full opacity when flat.
    expect(at0[0].opacity, closeTo(0.0, 1e-9));
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
      PaperTurnEffect(),
      PaperTurnBackEffect(),
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
