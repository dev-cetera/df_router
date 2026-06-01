import 'package:df_router/df_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteStackUri.encode', () {
    test('empty list → /', () {
      expect(RouteStackUri.encode([]).toString(), '/');
    });

    test('single route is returned verbatim (byte-identical to flat URL)', () {
      final original = Uri.parse('/home?lang=en');
      expect(RouteStackUri.encode([original]).toString(), '/home?lang=en');
    });

    test('two routes are joined with +', () {
      final encoded = RouteStackUri.encode([
        Uri.parse('/home'),
        Uri.parse('/sheet'),
      ]);
      expect(encoded.toString(), '/home+/sheet');
    });

    test('three routes preserve order (bottom→top reads left→right)', () {
      final encoded = RouteStackUri.encode([
        Uri.parse('/home'),
        Uri.parse('/sheet'),
        Uri.parse('/dialog'),
      ]);
      expect(encoded.toString(), '/home+/sheet+/dialog');
    });

    test(
      'top route queryParameters land in the standard ? clause; lower routes '
      'lose theirs (documented limitation)',
      () {
        final encoded = RouteStackUri.encode([
          Uri.parse('/home?lang=en'),
          Uri.parse('/sheet?tab=2'),
        ]);
        expect(encoded.toString(), '/home+/sheet?tab=2');
        expect(encoded.queryParameters, {'tab': '2'});
      },
    );

    test(
      'standard Uri.parse on an encoded stacked URL still returns the top '
      "route's queryParameters — no router-aware parsing needed",
      () {
        final encoded = RouteStackUri.encode([
          Uri.parse('/home'),
          Uri.parse('/sheet'),
          Uri.parse('/dialog?confirmed=true'),
        ]);
        final reparsed = Uri.parse(encoded.toString());
        expect(reparsed.path, '/home+/sheet+/dialog');
        expect(reparsed.queryParameters, {'confirmed': 'true'});
      },
    );
  });

  group('RouteStackUri.decode', () {
    test('a URL without + decodes to a single route', () {
      final routes = RouteStackUri.decode(Uri.parse('/home'));
      expect(routes, hasLength(1));
      expect(routes.first.toString(), '/home');
    });

    test('queries on a single-route URL are preserved', () {
      final routes = RouteStackUri.decode(Uri.parse('/home?lang=en'));
      expect(routes.first.queryParameters, {'lang': 'en'});
    });

    test('two-segment URL decodes into two routes', () {
      final routes = RouteStackUri.decode(Uri.parse('/home+/sheet'));
      expect(routes.map((u) => u.path), ['/home', '/sheet']);
    });

    test(
      'standard query attaches to the LAST route (the top of the stack); '
      'lower routes have empty query',
      () {
        final routes = RouteStackUri.decode(Uri.parse('/home+/sheet?tab=2'));
        expect(routes, hasLength(2));
        expect(routes[0].path, '/home');
        expect(routes[0].queryParameters, isEmpty);
        expect(routes[1].path, '/sheet');
        expect(routes[1].queryParameters, {'tab': '2'});
      },
    );

    test('empty segments (trailing/leading/double +) are skipped', () {
      // Hand-crafted nonsense URLs that the encoder never emits but a
      // user might paste — make sure we don't crash on them.
      expect(
        RouteStackUri.decode(Uri.parse('/home+')).map((u) => u.path),
        ['/home'],
      );
      expect(
        RouteStackUri.decode(Uri.parse('+/sheet')).map((u) => u.path),
        ['/sheet'],
      );
      expect(
        RouteStackUri.decode(Uri.parse('/home++/sheet')).map((u) => u.path),
        ['/home', '/sheet'],
      );
    });
  });

  group('RouteStackUri round-trip', () {
    test('encode then decode preserves a 3-route stack', () {
      final original = [
        Uri.parse('/home'),
        Uri.parse('/sheet'),
        Uri.parse('/dialog?confirmed=true'),
      ];
      final decoded = RouteStackUri.decode(RouteStackUri.encode(original));
      expect(decoded.map((u) => u.toString()).toList(), [
        '/home',
        '/sheet',
        '/dialog?confirmed=true',
      ]);
    });

    test(
      'lower-route queryParameters are LOST on round-trip (documented) — '
      'pinning this so a future regression that quietly preserves them '
      'shows up here',
      () {
        final original = [
          Uri.parse('/home?lang=en'),
          Uri.parse('/sheet?tab=2'),
        ];
        final decoded = RouteStackUri.decode(RouteStackUri.encode(original));
        expect(decoded[0].queryParameters, isEmpty);
        expect(decoded[1].queryParameters, {'tab': '2'});
      },
    );
  });

  group('RouteStackUri.isStacked', () {
    test('detects + in the path', () {
      expect(RouteStackUri.isStacked(Uri.parse('/a+/b')), isTrue);
      expect(RouteStackUri.isStacked(Uri.parse('/a')), isFalse);
      expect(RouteStackUri.isStacked(Uri.parse('/a?b=c')), isFalse);
    });

    test('+ inside a query string does NOT count as a stack delimiter', () {
      // `+` in a query is decoded to space by some parsers, but the test
      // here is specifically that `isStacked` only inspects the PATH.
      expect(RouteStackUri.isStacked(Uri.parse('/a?b=c+d')), isFalse);
    });
  });
}
