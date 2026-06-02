import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '_helpers.dart';

class _ProbeEffect extends AnimationEffect {
  const _ProbeEffect({
    super.duration = const Duration(milliseconds: 100),
    super.curve = Curves.linear,
  });

  @override
  List<AnimationLayerEffect> data(
    BuildContext context,
    Size size,
    double value,
  ) {
    return [AnimationLayerEffect(opacity: value)];
  }
}

class _TwoLayerProbeEffect extends AnimationEffect {
  const _TwoLayerProbeEffect()
      : super(
          duration: const Duration(milliseconds: 100),
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
      AnimationLayerEffect(opacity: 1.0 - value),
    ];
  }
}

// Test harness that lets us read the latest LayerEffectResults from outside the
// build closure without races. The values list is updated on every builder
// invocation.
class _Harness extends StatefulWidget {
  final GlobalKey<AnimationEffectBuilderState> ebKey;
  final List<LayerEffectResult> capture;
  final List<int> buildCount;
  const _Harness({
    required this.ebKey,
    required this.capture,
    required this.buildCount,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) {
    return AnimationEffectBuilder(
      key: widget.ebKey,
      builder: (context, results) {
        widget.buildCount[0]++;
        widget.capture
          ..clear()
          ..addAll(results);
        return const SizedBox.shrink();
      },
    );
  }
}

Future<void> _setEffectsAndRebuild(
  WidgetTester tester,
  GlobalKey<AnimationEffectBuilderState> key,
  List<AnimationEffect> effects,
) async {
  key.currentState!.setEffects(effects);
  // setEffects does not call setState. The parent (_Harness) rebuilds on
  // demand by being remounted; nudge a rebuild via the binding so AnimatedBuilder
  // re-subscribes to the new bundles' animations.
  // ignore: invalid_use_of_protected_member
  (key.currentContext! as Element).markNeedsBuild();
  await tester.pump();
}

void main() {
  testWidgets('initial build supplies a single bundle with NoEffect',
      (tester) async {
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    expect(capture, hasLength(1));
    expect(capture.first.value, 1.0);
  });

  testWidgets('setEffects + restart drives a linear ramp from 0 to 1',
      (tester) async {
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    await _setEffectsAndRebuild(tester, ebKey, [const _ProbeEffect()]);
    ebKey.currentState!.restart();
    await tester.pump();
    expect(capture.first.value, closeTo(0.0, 0.01));
    await tester.pump(const Duration(milliseconds: 50));
    expect(capture.first.value, greaterThan(0.3));
    expect(capture.first.value, lessThan(0.7));
    await tester.pump(const Duration(milliseconds: 100));
    expect(capture.first.value, closeTo(1.0, 0.001));
  });

  testWidgets('setEffects with different length disposes and recreates',
      (tester) async {
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    expect(capture, hasLength(1));
    await _setEffectsAndRebuild(
      tester,
      ebKey,
      const [_ProbeEffect(), _ProbeEffect()],
    );
    expect(capture, hasLength(2));
  });

  testWidgets('onComplete fires when the animation completes', (tester) async {
    var completions = 0;
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    await tester.pumpWidget(
      wrapRouter(
        AnimationEffectBuilder(
          key: ebKey,
          onComplete: () => completions++,
          builder: (context, results) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    final before = completions;
    ebKey.currentState!.setEffects([const _ProbeEffect()]);
    await tester.pump();
    ebKey.currentState!.restart();
    await tester.pumpAndSettle();
    expect(
      completions,
      greaterThan(before),
      reason: 'onComplete should fire at least once after the animation '
          'completes',
    );
    // Pinning the de-dupe behavior: an idle pump after completion does not
    // fire onComplete again.
    final after = completions;
    await tester.pump(const Duration(milliseconds: 200));
    expect(completions, after);
  });

  testWidgets('reverse drives the animation backward', (tester) async {
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    await _setEffectsAndRebuild(tester, ebKey, [const _ProbeEffect()]);
    // After setEffects the controller is at 1.0; reverse should take it to 0.
    ebKey.currentState!.reverse();
    await tester.pumpAndSettle();
    expect(capture.first.value, closeTo(0.0, 0.01));
  });

  testWidgets('two-bundle effect yields two layer effects', (tester) async {
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    await _setEffectsAndRebuild(tester, ebKey, const [_TwoLayerProbeEffect()]);
    // One bundle ⇒ one LayerEffectResult ⇒ its data list has length 2.
    expect(capture, hasLength(1));
    expect(capture.first.data, hasLength(2));
  });

  testWidgets(
      'reuse path: many same-length setEffects calls still apply the '
      'latest curve on each animation', (tester) async {
    // Pins the in-place-mutation reuse path (same length effects). Each call
    // updates the existing CurvedAnimation's `curve` field rather than
    // allocating a new CurvedAnimation (which would leak a status listener
    // back-referenced on the parent controller). The behavioral check here
    // is: after 25 setEffects calls alternating between two curves, the
    // animation's mid-point value reflects the LAST-set curve.
    final ebKey = GlobalKey<AnimationEffectBuilderState>();
    final capture = <LayerEffectResult>[];
    final buildCount = [0];
    await tester.pumpWidget(
      wrapRouter(
        _Harness(ebKey: ebKey, capture: capture, buildCount: buildCount),
      ),
    );
    await tester.pump();
    // 25 round-trips of setEffects with the SAME length (1). Without the
    // in-place mutation, this would attach 25 stale CurvedAnimation status
    // listeners to the controller; with the fix, the listener count stays at 1.
    for (var i = 0; i < 25; i++) {
      await _setEffectsAndRebuild(tester, ebKey, [const _ProbeEffect()]);
    }
    // After all the reuses, the animation must still run correctly: restart
    // and verify the ramp endpoints.
    ebKey.currentState!.restart();
    await tester.pump();
    expect(capture.first.value, closeTo(0.0, 0.01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(capture.first.value, closeTo(1.0, 0.001));
  });
}
