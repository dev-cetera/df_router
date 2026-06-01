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
///   `<route-1-path>+<route-2-path>+...+<top-path>[?query]`
///
/// - The path concatenates each route's path joined by `+`. `+` is a
///   sub-delim under RFC 3986 and is preserved as a literal character in
///   URI paths (it's only special inside the query component, where it
///   stands in for a space).
/// - The top-of-stack route's queryParameters (if any) ride along in the
///   standard `?` clause, so `Uri.parse(stackUrl).queryParameters` gives
///   the active route's params with no special parsing needed.
/// - Lower routes' queryParameters are NOT serialized — a documented
///   limitation. Bookmarks point at "the modal that was open and its
///   params"; bases underneath are usually parameter-less.
///
/// Round-trip examples:
///
/// ```
/// [/home]                        ↔ /home
/// [/home?a=1]                    ↔ /home?a=1
/// [/home, /sheet]                ↔ /home+/sheet
/// [/home, /sheet?tab=2]          ↔ /home+/sheet?tab=2
/// [/home?lang=en, /sheet?tab=2]  →  /home+/sheet?tab=2     (lang=en dropped)
/// ```
class RouteStackUri {
  RouteStackUri._();

  /// The single character that separates route paths inside the encoded
  /// path. Apps must not register routes whose own path contains this
  /// delimiter (asserted by `RouteController`).
  static const String delimiter = '+';

  /// Encodes [routes] as a single stack URI.
  ///
  /// Empty list → `/` (a reasonable default for "no routes yet").
  /// Single route → the route's own URI verbatim (so flat-strategy URLs
  /// stay byte-identical when the stack only ever has one entry).
  static Uri encode(List<Uri> routes) {
    if (routes.isEmpty) return Uri.parse('/');
    if (routes.length == 1) return routes.first;

    final paths = routes.map((u) => u.path).join(delimiter);
    final topQuery = routes.last.query;
    return Uri.parse(topQuery.isEmpty ? paths : '$paths?$topQuery');
  }

  /// Decodes a stack URI into its component route URIs.
  ///
  /// If [uri.path] doesn't contain the delimiter, treats the input as a
  /// single route (no decoding needed). The top route inherits [uri]'s
  /// queryParameters; lower routes have empty queryParameters.
  static List<Uri> decode(Uri uri) {
    final path = uri.path;
    if (!path.contains(delimiter)) {
      return [uri];
    }

    final segments = path.split(delimiter);
    final topQuery = uri.query;
    final routes = <Uri>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      // Defensive: ignore empty segments that result from a leading,
      // trailing, or doubled delimiter (`/foo+`, `+/foo`, `/foo++/bar`).
      // The encoder never produces these, but a hand-written or
      // manipulated URL might.
      if (segment.isEmpty) continue;
      final isTop = i == segments.length - 1;
      final raw = (isTop && topQuery.isNotEmpty) ? '$segment?$topQuery' : segment;
      routes.add(Uri.parse(raw));
    }
    return routes;
  }

  /// Whether [uri] is shaped like a stack-encoded URL (contains the
  /// delimiter in its path). Used by `RouteController` to decide whether
  /// a given URL is a flat single-route URL or a stack URL.
  static bool isStacked(Uri uri) => uri.path.contains(delimiter);
}
