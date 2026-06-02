//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Codec for serializing a list of route URIs into a single URL and back —
/// used by `RouteController` when `UrlStrategy.stacked` is enabled.
///
/// Wire format:
///   `<route-1>[;<q1>]+<route-2>[;<q2>]+...+<top>[;<qN>][?<topQuery>]`
///
/// - The path concatenates each route's path joined by `+`. `+` is a
///   sub-delim under RFC 3986 and is preserved as a literal character in
///   URI paths (it's only special inside the query component, where it
///   stands in for a space).
/// - A route's own queryParameters serialize as a `;key=value&key=value`
///   matrix clause appended to that route's path segment. `;` is also
///   a sub-delim, allowed in paths without encoding. Values are percent-
///   encoded so `&`/`=`/`;`/`+`/spaces inside a value can't break parsing.
/// - The TOP route additionally accepts the standard `?` clause at the
///   end of the URL. This lets `Uri.parse(stackUrl).queryParameters` keep
///   working as a no-op view onto the active route's params for any
///   external code that hasn't learned about stacked URLs. When both a
///   `;` clause AND the standard `?` are present on the top route, they
///   are merged (`?` keys win on conflict).
///
/// Round-trip examples:
///
/// ```
/// [/home]                        ↔ /home
/// [/home?a=1]                    ↔ /home?a=1
/// [/home, /sheet]                ↔ /home+/sheet
/// [/home, /sheet?tab=2]          ↔ /home+/sheet?tab=2
/// [/home?a=1, /sheet?b=2]        ↔ /home;a=1+/sheet?b=2
/// [/a?x=1, /b?y=2, /c?z=3]       ↔ /a;x=1+/b;y=2+/c?z=3
/// ```
class RouteStackUri {
  RouteStackUri._();

  /// The single character that separates route paths inside the encoded
  /// path. Apps must not register routes whose own path contains this
  /// delimiter (asserted by `RouteController`).
  static const String delimiter = '+';

  /// The character that separates a route's path from its inline (matrix-
  /// style) query inside a single segment of the stack URL.
  static const String querySeparator = ';';

  /// Encodes [routes] as a single stack URI.
  ///
  /// Empty list → `/` (a reasonable default for "no routes yet").
  /// Single route → the route's own URI verbatim (so flat-strategy URLs
  /// stay byte-identical when the stack only ever has one entry).
  static Uri encode(List<Uri> routes) {
    if (routes.isEmpty) return Uri.parse('/');
    if (routes.length == 1) return routes.first;

    final segments = <String>[];
    for (var i = 0; i < routes.length; i++) {
      final route = routes[i];
      final isTop = i == routes.length - 1;
      // Top route's query rides in the standard `?` clause appended after
      // the whole path; everyone else uses the matrix-style `;` clause so
      // their params stay inside the URI's path component.
      if (isTop) {
        segments.add(route.path);
      } else if (route.queryParameters.isEmpty) {
        segments.add(route.path);
      } else {
        segments.add(
          '${route.path}$querySeparator${_encodeMatrixQuery(route.queryParameters)}',
        );
      }
    }
    final path = segments.join(delimiter);
    final topQuery = routes.last.query;
    return Uri.parse(topQuery.isEmpty ? path : '$path?$topQuery');
  }

  /// Decodes a stack URI into its component route URIs.
  ///
  /// If [uri.path] doesn't contain the delimiter, treats the input as a
  /// single route (no decoding needed). Each segment's `;<query>` clause
  /// becomes that route's queryParameters; the standard `?<query>` clause
  /// at the end of [uri] is merged into the TOP route's params.
  static List<Uri> decode(Uri uri) {
    final path = uri.path;
    if (!path.contains(delimiter)) {
      return [uri];
    }

    final segments = path.split(delimiter);
    final topQuery = uri.queryParameters;
    final routes = <Uri>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      // Defensive: ignore empty segments that result from a leading,
      // trailing, or doubled delimiter. The encoder never produces these,
      // but a hand-written or manipulated URL might.
      if (segment.isEmpty) continue;

      final semiIdx = segment.indexOf(querySeparator);
      final String segPath;
      final Map<String, String> segQuery;
      if (semiIdx == -1) {
        segPath = segment;
        segQuery = const {};
      } else {
        segPath = segment.substring(0, semiIdx);
        segQuery = _decodeMatrixQuery(segment.substring(semiIdx + 1));
      }

      final isTop = i == segments.length - 1;
      // Top route merges its matrix-clause params (if any) with the
      // standard `?` query — the standard query wins on key conflict so
      // users can override matrix-encoded defaults from the address bar.
      final combined = isTop && topQuery.isNotEmpty
          ? <String, String>{...segQuery, ...topQuery}
          : segQuery;

      routes.add(
        Uri(
          path: segPath,
          queryParameters: combined.isNotEmpty ? combined : null,
        ),
      );
    }
    return routes;
  }

  /// Whether [uri] is shaped like a stack-encoded URL (contains the
  /// delimiter in its path). Used by `RouteController` to decide whether
  /// a given URL is a flat single-route URL or a stack URL.
  static bool isStacked(Uri uri) => uri.path.contains(delimiter);

  /// Encodes [routes] as a `+`-separated string with each route's
  /// queryParameters serialized inline via the matrix-style `;` clause
  /// (no standard `?` top-route special-case).
  ///
  /// Used by `RouteController` to serialize forward-history routes into
  /// a URL fragment when `UrlStrategy.stacked` is enabled — the path
  /// holds the visible-stack via [encode], the fragment holds the forward
  /// portion via this method, so a reload reconstructs the full history.
  static String encodeSegments(List<Uri> routes) {
    final segments = <String>[];
    for (final route in routes) {
      if (route.queryParameters.isEmpty) {
        segments.add(route.path);
      } else {
        segments.add(
          '${route.path}$querySeparator'
          '${_encodeMatrixQuery(route.queryParameters)}',
        );
      }
    }
    return segments.join(delimiter);
  }

  /// Inverse of [encodeSegments]. Parses a `+`-separated route list (with
  /// `;`-prefixed per-route matrix queries) into a list of `Uri`s. Empty
  /// input yields an empty list; empty segments are defensively skipped.
  static List<Uri> decodeSegments(String input) {
    if (input.isEmpty) return const [];
    final routes = <Uri>[];
    for (final segment in input.split(delimiter)) {
      if (segment.isEmpty) continue;
      final semiIdx = segment.indexOf(querySeparator);
      if (semiIdx == -1) {
        routes.add(Uri(path: segment));
      } else {
        final segPath = segment.substring(0, semiIdx);
        final segQuery = _decodeMatrixQuery(segment.substring(semiIdx + 1));
        routes.add(
          Uri(
            path: segPath,
            queryParameters: segQuery.isNotEmpty ? segQuery : null,
          ),
        );
      }
    }
    return routes;
  }

  /// Encodes a `{key: value}` map as `k1=v1&k2=v2` with each component
  /// percent-encoded so `&` / `=` / `;` / `+` / spaces inside a value
  /// can't be misread as structural punctuation when the path is
  /// re-parsed.
  static String _encodeMatrixQuery(Map<String, String> params) {
    final parts = <String>[];
    params.forEach((k, v) {
      parts.add('${Uri.encodeComponent(k)}=${Uri.encodeComponent(v)}');
    });
    return parts.join('&');
  }

  /// Inverse of [_encodeMatrixQuery]. Skips empty pairs and pairs without
  /// an `=` (defensive — the encoder never emits them).
  static Map<String, String> _decodeMatrixQuery(String matrix) {
    if (matrix.isEmpty) return const {};
    final out = <String, String>{};
    for (final pair in matrix.split('&')) {
      if (pair.isEmpty) continue;
      final eqIdx = pair.indexOf('=');
      if (eqIdx == -1) continue;
      final key = Uri.decodeComponent(pair.substring(0, eqIdx));
      final value = Uri.decodeComponent(pair.substring(eqIdx + 1));
      out[key] = value;
    }
    return out;
  }
}
