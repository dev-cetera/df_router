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
      'top route queryParameters land in the standard ? clause; lower '
      'routes serialize via the matrix-style ; clause inside the path',
      () {
        final encoded = RouteStackUri.encode([
          Uri.parse('/home?lang=en'),
          Uri.parse('/sheet?tab=2'),
        ]);
        expect(encoded.toString(), '/home;lang=en+/sheet?tab=2');
        expect(encoded.queryParameters, {'tab': '2'});
      },
    );

    test(
      'multiple lower routes each carry their own ; matrix clause',
      () {
        final encoded = RouteStackUri.encode([
          Uri.parse('/home?a=1'),
          Uri.parse('/sheet?b=2&c=3'),
          Uri.parse('/dialog?d=4'),
        ]);
        expect(encoded.toString(), '/home;a=1+/sheet;b=2&c=3+/dialog?d=4');
      },
    );

    test(
      'special characters in lower-route query values are percent-encoded '
      "so they can't break the path-level parsing",
      () {
        final encoded = RouteStackUri.encode([
          Uri.parse('/home').replace(queryParameters: {'q': 'a&b=c+d e'}),
          Uri.parse('/sheet'),
        ]);
        // & = and + ; space are all encoded inside the matrix clause.
        expect(encoded.path, '/home;q=a%26b%3Dc%2Bd%20e+/sheet');
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
      'standard ? query attaches to the LAST route (top of stack); routes '
      'without a ; matrix clause have empty queryParameters',
      () {
        final routes = RouteStackUri.decode(Uri.parse('/home+/sheet?tab=2'));
        expect(routes, hasLength(2));
        expect(routes[0].path, '/home');
        expect(routes[0].queryParameters, isEmpty);
        expect(routes[1].path, '/sheet');
        expect(routes[1].queryParameters, {'tab': '2'});
      },
    );

    test(
      'matrix-style ; clauses are parsed as per-route queryParameters',
      () {
        final routes = RouteStackUri.decode(
          Uri.parse('/home;a=1+/sheet;b=2&c=3+/dialog?d=4'),
        );
        expect(routes, hasLength(3));
        expect(routes[0].path, '/home');
        expect(routes[0].queryParameters, {'a': '1'});
        expect(routes[1].path, '/sheet');
        expect(routes[1].queryParameters, {'b': '2', 'c': '3'});
        expect(routes[2].path, '/dialog');
        expect(routes[2].queryParameters, {'d': '4'});
      },
    );

    test(
      'when the top route has BOTH a ; matrix clause and a ? standard '
      'clause, the two merge with the standard ? winning on key conflict',
      () {
        final routes = RouteStackUri.decode(
          Uri.parse('/home+/sheet;a=1&b=2?b=override&c=3'),
        );
        expect(routes[1].queryParameters, {
          'a': '1',
          'b': 'override',
          'c': '3',
        });
      },
    );

    test('percent-encoded values inside a matrix clause are decoded', () {
      final routes = RouteStackUri.decode(
        Uri.parse('/home;q=a%26b%3Dc%2Bd%20e+/sheet'),
      );
      expect(routes[0].queryParameters, {'q': 'a&b=c+d e'});
    });

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
      'lower-route queryParameters SURVIVE the round-trip via the matrix '
      '; clause in each segment',
      () {
        final original = [
          Uri.parse('/home?lang=en'),
          Uri.parse('/sheet?tab=2'),
        ];
        final decoded = RouteStackUri.decode(RouteStackUri.encode(original));
        expect(decoded[0].queryParameters, {'lang': 'en'});
        expect(decoded[1].queryParameters, {'tab': '2'});
      },
    );

    test(
      'special characters in lower-route values round-trip cleanly',
      () {
        final original = [
          Uri.parse('/home').replace(
            queryParameters: {'q': 'a&b=c+d e', 'extra': ';weird/value'},
          ),
          Uri.parse('/sheet'),
        ];
        final decoded = RouteStackUri.decode(RouteStackUri.encode(original));
        expect(decoded[0].queryParameters, original[0].queryParameters);
      },
    );
  });

  group('RouteStackUri.encodeSegments / decodeSegments', () {
    test('empty list encodes to empty string', () {
      expect(RouteStackUri.encodeSegments([]), isEmpty);
    });

    test('single route with no query encodes to just its path', () {
      expect(
        RouteStackUri.encodeSegments([Uri.parse('/dialog')]),
        '/dialog',
      );
    });

    test(
      'multiple routes join with "+" and per-route queries use ";" matrix '
      'clauses (no top-route "?" special case)',
      () {
        final encoded = RouteStackUri.encodeSegments([
          Uri.parse('/dialog?confirm=y'),
          Uri.parse('/toast'),
        ]);
        expect(encoded, '/dialog;confirm=y+/toast');
      },
    );

    test('round-trips routes with per-route queries through the fragment', () {
      final original = [
        Uri.parse('/dialog?confirm=y'),
        Uri.parse('/toast?msg=ok'),
      ];
      final decoded =
          RouteStackUri.decodeSegments(RouteStackUri.encodeSegments(original));
      expect(decoded[0].path, '/dialog');
      expect(decoded[0].queryParameters, {'confirm': 'y'});
      expect(decoded[1].path, '/toast');
      expect(decoded[1].queryParameters, {'msg': 'ok'});
    });

    test('empty input decodes to empty list (no crash)', () {
      expect(RouteStackUri.decodeSegments(''), isEmpty);
    });

    test(
      'fragment URL round-trip — a controller emitting a forward-history '
      'URL like "/home+/sheet#/dialog+/toast" reads back as visible=[home,sheet] '
      'forward=[dialog,toast]',
      () {
        final url = Uri(
          path: RouteStackUri.encode([Uri.parse('/home'), Uri.parse('/sheet')])
              .path,
          fragment: RouteStackUri.encodeSegments(
            [Uri.parse('/dialog'), Uri.parse('/toast')],
          ),
        );
        expect(url.toString(), '/home+/sheet#/dialog+/toast');
        expect(
          RouteStackUri.decode(url).map((u) => u.path).toList(),
          ['/home', '/sheet'],
        );
        expect(
          RouteStackUri.decodeSegments(url.fragment)
              .map((u) => u.path)
              .toList(),
          ['/dialog', '/toast'],
        );
      },
    );
  });

  group('Regression: real URL shapes', () {
    test(
      "the URL '/home+/sheet;hello=2&workd=2+/dialog+/toast' decodes to "
      'four routes, with sheet carrying its matrix-clause queryParameters',
      () {
        final routes = RouteStackUri.decode(
          Uri.parse('/home+/sheet;hello=2&workd=2+/dialog+/toast'),
        );
        expect(routes, hasLength(4));
        expect(routes[0].path, '/home');
        expect(routes[0].queryParameters, isEmpty);
        expect(routes[1].path, '/sheet');
        expect(routes[1].queryParameters, {'hello': '2', 'workd': '2'});
        expect(routes[2].path, '/dialog');
        expect(routes[2].queryParameters, isEmpty);
        expect(routes[3].path, '/toast');
        expect(routes[3].queryParameters, isEmpty);
      },
    );

    test(
      're-encoding the decoded 4-route stack reproduces the input URL '
      'byte-for-byte (idempotent round-trip)',
      () {
        const input = '/home+/sheet;hello=2&workd=2+/dialog+/toast';
        final routes = RouteStackUri.decode(Uri.parse(input));
        final reEncoded = RouteStackUri.encode([for (final r in routes) r]);
        expect(reEncoded.toString(), input);
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
