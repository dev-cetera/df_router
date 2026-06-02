import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubScreen<TExtra extends Object?> extends StatelessWidget
    with RouteWidgetMixin<TExtra> {
  @override
  final RouteState<TExtra?>? routeState;
  const _StubScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('RouteBuilder defaults', () {
    test(
        'shouldPreserve=false, shouldPrebuild=false, isRedirectable=true, '
        'condition=null', () {
      final b = RouteBuilder<Object?>(
        routeState: RouteState(Uri.parse('/x')),
        builder: (context, state) => _StubScreen<Object?>(routeState: state),
      );
      expect(b.shouldPreserve, isFalse);
      expect(b.shouldPrebuild, isFalse);
      expect(b.isRedirectable, isTrue);
      expect(b.condition, isNull);
    });

    test('non-default flags round-trip', () {
      bool guard() => true;
      final b = RouteBuilder<int>(
        routeState: RouteState<int>(Uri.parse('/x')),
        shouldPreserve: true,
        shouldPrebuild: true,
        isRedirectable: false,
        condition: guard,
        builder: (context, state) => _StubScreen<int>(routeState: state),
      );
      expect(b.shouldPreserve, isTrue);
      expect(b.shouldPrebuild, isTrue);
      expect(b.isRedirectable, isFalse);
      expect(identical(b.condition, guard), isTrue);
    });
  });

  group('RouteBuilder.builder type erasure', () {
    testWidgets('invokes the user builder with a cast RouteState<TExtra>',
        (tester) async {
      RouteState<int?>? received;
      final b = RouteBuilder<int>(
        routeState: RouteState<int>(Uri.parse('/x'), extra: 7),
        builder: (context, state) {
          received = state;
          return _StubScreen<int>(routeState: state);
        },
      );

      // The builder is type-erased on the field but produces a typed widget
      // when invoked with the matching RouteState instance.
      late Widget produced;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              produced = b.builder(
                context,
                RouteState<int>(Uri.parse('/x'), extra: 7),
              );
              return produced;
            },
          ),
        ),
      );

      expect(produced, isA<_StubScreen<int>>());
      expect(received, isNotNull);
      expect(received!.extra, 7);
    });
  });

  group('RouteBuilder.copyWith', () {
    test('preserves unspecified fields', () {
      bool guard() => true;
      final a = RouteBuilder<int>(
        routeState: RouteState<int>(Uri.parse('/x')),
        shouldPreserve: true,
        shouldPrebuild: true,
        isRedirectable: false,
        condition: guard,
        builder: (context, state) => _StubScreen<int>(routeState: state),
      );
      final b = a.copyWith();
      expect(b.shouldPreserve, a.shouldPreserve);
      expect(b.shouldPrebuild, a.shouldPrebuild);
      expect(b.isRedirectable, a.isRedirectable);
      expect(identical(b.condition, a.condition), isTrue);
    });

    test('overrides specified fields', () {
      final a = RouteBuilder<int>(
        routeState: RouteState<int>(Uri.parse('/x')),
        builder: (context, state) => _StubScreen<int>(routeState: state),
      );
      final newState = RouteState<int>(Uri.parse('/y'));
      final b = a.copyWith(
        routeState: newState,
        shouldPreserve: true,
        shouldPrebuild: true,
        isRedirectable: false,
      );
      expect(b.routeState, newState);
      expect(b.shouldPreserve, isTrue);
      expect(b.shouldPrebuild, isTrue);
      expect(b.isRedirectable, isFalse);
    });
  });

  group('RouteBuilder.copyWithout', () {
    test('clears the flags chosen to drop, keeps the others', () {
      bool guard() => true;
      final a = RouteBuilder<int>(
        routeState: RouteState<int>(Uri.parse('/x')),
        shouldPreserve: true,
        shouldPrebuild: true,
        isRedirectable: false,
        condition: guard,
        builder: (context, state) => _StubScreen<int>(routeState: state),
      );
      final b = a.copyWithout(
        shouldPreserve: true,
        shouldPrebuild: true,
        condition: true,
      );
      // copyWithout: flag=true means "drop" for these fields.
      expect(b.shouldPreserve, isFalse);
      expect(b.shouldPrebuild, isFalse);
      expect(b.condition, isNull);
      // isRedirectable defaults to false in copyWithout, so it KEEPS the value
      // (false → keeps current). This is the same inverted-flag pattern as in
      // RouteState.copyWithout for animationEffect/skipCurrent.
      expect(b.isRedirectable, isFalse);
    });
  });
}
