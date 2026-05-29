import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteState constructor', () {
    test('stores the uri verbatim when no extra query params are provided', () {
      final r = RouteState(Uri.parse('/foo?a=1'));
      expect(r.uri.path, '/foo');
      expect(r.uri.queryParameters, {'a': '1'});
    });

    test('merges uri queryParameters with explicit queryParameters', () {
      final r = RouteState(
        Uri.parse('/foo?a=1'),
        queryParameters: {'b': '2'},
      );
      expect(r.uri.queryParameters, {'a': '1', 'b': '2'});
    });

    test('explicit queryParameters override uri query of same key', () {
      final r = RouteState(
        Uri.parse('/foo?a=1'),
        queryParameters: {'a': '2'},
      );
      expect(r.uri.queryParameters, {'a': '2'});
    });

    test('omits query string when both sources are empty', () {
      final r = RouteState(Uri.parse('/foo'));
      expect(r.uri.hasQuery, isFalse);
    });

    test('defaults: skipCurrent=true, shouldPreserve=false, '
        'animationEffect=NoEffect, condition=null, extra=null', () {
      final r = RouteState(Uri.parse('/x'));
      expect(r.skipCurrent, isTrue);
      expect(r.shouldPreserve, isFalse);
      expect(r.animationEffect, isA<NoEffect>());
      expect(r.condition, isNull);
      expect(r.extra, isNull);
    });

    test('explicit non-default fields round-trip', () {
      bool guard() => false;
      const fade = FadeEffect();
      final r = RouteState<int>(
        Uri.parse('/x'),
        extra: 7,
        skipCurrent: false,
        animationEffect: fade,
        condition: guard,
        shouldPreserve: true,
      );
      expect(r.extra, 7);
      expect(r.skipCurrent, isFalse);
      expect(identical(r.animationEffect, fade), isTrue);
      expect(identical(r.condition, guard), isTrue);
      expect(r.shouldPreserve, isTrue);
    });
  });

  group('RouteState.parse', () {
    test('parses a plain path', () {
      final r = RouteState.parse('/foo/bar');
      expect(r.uri.path, '/foo/bar');
    });

    test('parses path with query string', () {
      final r = RouteState.parse('/foo?a=1&b=2');
      expect(r.uri.queryParameters, {'a': '1', 'b': '2'});
    });

    test('merges queryParameters argument with parsed query', () {
      final r = RouteState.parse('/foo?a=1', queryParameters: {'b': '2'});
      expect(r.uri.queryParameters, {'a': '1', 'b': '2'});
    });
  });

  group('RouteState equality (Equatable: [uri, extra])', () {
    test('equal when uri and extra match', () {
      final a = RouteState<int>(Uri.parse('/x'), extra: 1);
      final b = RouteState<int>(Uri.parse('/x'), extra: 1);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when extra differs', () {
      final a = RouteState<int>(Uri.parse('/x'), extra: 1);
      final b = RouteState<int>(Uri.parse('/x'), extra: 2);
      expect(a, isNot(equals(b)));
    });

    test('not equal when uri differs', () {
      final a = RouteState(Uri.parse('/a'));
      final b = RouteState(Uri.parse('/b'));
      expect(a, isNot(equals(b)));
    });

    test('not equal when query parameters differ', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = RouteState(Uri.parse('/x?a=2'));
      expect(a, isNot(equals(b)));
    });

    test('equality ignores skipCurrent / animationEffect / condition / '
        'shouldPreserve (they are not in props)', () {
      final a = RouteState(
        Uri.parse('/x'),
        skipCurrent: false,
        animationEffect: const FadeEffect(),
        shouldPreserve: true,
      );
      final b = RouteState(Uri.parse('/x'));
      expect(a, equals(b));
    });
  });

  group('RouteState.key', () {
    test('returns a ValueKey of the uri string', () {
      final r = RouteState(Uri.parse('/foo?x=1'));
      expect(r.key, ValueKey(r.uri.toString()));
    });

    test('two RouteStates with the same uri produce equal keys', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = RouteState(Uri.parse('/x?a=1'));
      expect(a.key, b.key);
    });
  });

  group('RouteState.copyWith', () {
    test('preserves unspecified fields', () {
      bool guard() => true;
      final a = RouteState<int>(
        Uri.parse('/x'),
        extra: 1,
        skipCurrent: false,
        animationEffect: const FadeEffect(),
        condition: guard,
        shouldPreserve: true,
      );
      final b = a.copyWith();
      expect(b.uri, a.uri);
      expect(b.extra, a.extra);
      expect(b.skipCurrent, a.skipCurrent);
      expect(b.animationEffect, a.animationEffect);
      expect(b.condition, a.condition);
      expect(b.shouldPreserve, a.shouldPreserve);
    });

    test('overrides specified fields', () {
      final a = RouteState<int>(Uri.parse('/x'), extra: 1);
      final b = a.copyWith(extra: 9, shouldPreserve: true);
      expect(b.extra, 9);
      expect(b.shouldPreserve, isTrue);
      expect(b.uri, a.uri);
    });

    test('copyWith(queryParameters: …) merges into the new uri', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = a.copyWith(queryParameters: {'b': '2'});
      expect(b.uri.queryParameters, {'a': '1', 'b': '2'});
    });
  });

  // Pinning the (slightly non-uniform) semantics of the current implementation:
  //   uri / extra / skipCurrent / condition / shouldPreserve: flag=true keeps
  //   the value, flag=false replaces with the empty default.
  //   animationEffect is INVERTED: flag=true replaces with NoEffect, flag=false
  //   keeps the existing effect.
  //   queryParameters is a no-op when uri=true (the URI carries its own query).
  group('RouteState.copyWithout', () {
    test('extra:false drops extra', () {
      final a = RouteState<int>(Uri.parse('/x'), extra: 7);
      final b = a.copyWithout(extra: false);
      expect(b.extra, isNull);
    });

    test('extra:true keeps extra', () {
      final a = RouteState<int>(Uri.parse('/x'), extra: 7);
      final b = a.copyWithout(extra: true);
      expect(b.extra, 7);
    });

    test('uri:false wipes the path but query is carried over by '
        'the queryParameters:true default', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = a.copyWithout(uri: false);
      expect(b.uri.path, '');
      expect(b.uri.queryParameters, {'a': '1'});
    });

    test('uri:false + queryParameters:false yields a fully empty Uri', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = a.copyWithout(uri: false, queryParameters: false);
      expect(b.uri, Uri());
    });

    test('animationEffect:true (default) replaces with NoEffect', () {
      final a = RouteState(
        Uri.parse('/x'),
        animationEffect: const FadeEffect(),
      );
      final b = a.copyWithout();
      expect(b.animationEffect, isA<NoEffect>());
    });

    test('animationEffect:false keeps the existing effect', () {
      const fade = FadeEffect();
      final a = RouteState(Uri.parse('/x'), animationEffect: fade);
      final b = a.copyWithout(animationEffect: false);
      expect(identical(b.animationEffect, fade), isTrue);
    });

    test('shouldPreserve:false forces shouldPreserve=false', () {
      final a = RouteState(Uri.parse('/x'), shouldPreserve: true);
      final b = a.copyWithout(shouldPreserve: false);
      expect(b.shouldPreserve, isFalse);
    });

    test('shouldPreserve:true keeps the existing value', () {
      final a = RouteState(Uri.parse('/x'), shouldPreserve: true);
      final b = a.copyWithout(shouldPreserve: true);
      expect(b.shouldPreserve, isTrue);
    });

    test('condition:false drops the condition', () {
      bool guard() => false;
      final a = RouteState(Uri.parse('/x'), condition: guard);
      final b = a.copyWithout(condition: false);
      expect(b.condition, isNull);
    });

    test('skipCurrent:false forces skipCurrent=true', () {
      final a = RouteState(Uri.parse('/x'), skipCurrent: false);
      final b = a.copyWithout(skipCurrent: false);
      expect(b.skipCurrent, isTrue);
    });
  });

  group('RouteState.cast', () {
    test('casts extra to a new type', () {
      final a = RouteState<Object?>(Uri.parse('/x'), extra: 42);
      final b = a.cast<int>();
      expect(b, isA<RouteState<int?>>());
      expect(b.extra, 42);
      expect(b.uri, a.uri);
    });
  });

  group('RouteState.matchPath', () {
    test('matches when uri.path is identical regardless of query', () {
      final a = RouteState(Uri.parse('/x?a=1'));
      final b = RouteState(Uri.parse('/x?b=2'));
      expect(a.matchPath(b), isTrue);
    });

    test('does not match when path differs', () {
      final a = RouteState(Uri.parse('/x'));
      final b = RouteState(Uri.parse('/y'));
      expect(a.matchPath(b), isFalse);
    });
  });

  group('RouteState.props', () {
    test('exposes [uri, extra]', () {
      final r = RouteState<int>(Uri.parse('/x'), extra: 9);
      expect(r.props, [r.uri, 9]);
    });
  });
}
