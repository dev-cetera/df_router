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

/// Controls how `RouteController` serializes its navigation history into the
/// browser URL.
enum UrlStrategy {
  /// URL = top-of-stack route only. Each navigation overwrites the URL bar
  /// with the new top route's URI. Cold-booting a URL reconstructs a single
  /// route at the top of an otherwise-empty stack — base routes underneath
  /// a modal are NOT recovered. This is the default and is backwards
  /// compatible with apps written before stacked URLs existed.
  flat,

  /// URL encodes the entire visible stack: routes joined by `+` in the path,
  /// with the top route's queryParameters in the standard `?` clause. So
  /// `[/home, /sheet?tab=2]` round-trips as `/home+/sheet?tab=2`, and
  /// cold-booting that URL reconstructs both entries — the sheet renders on
  /// top of the home page.
  ///
  /// Trade-offs: only the top route's queryParameters survive a reload, and
  /// `+` is reserved as a route delimiter (so registered paths must not
  /// contain it).
  stacked,
}
