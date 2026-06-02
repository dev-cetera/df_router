# Changelog

## [0.6.0]

- Released @ 6/2026 (UTC)
- breaking: `AnimationEffect.data` is now a method (`List<AnimationLayerEffect> data(BuildContext, Size, double)`) — custom subclasses must replace their `get data => (ctx, sz, v) => [...]` override with a regular method.
- breaking: `setPreservationStrategy` callback signature is now `(RouteBuilder) => bool`; read `builder.routeState` for the previous second argument.
- breaking: `RouteState.key` returns `ObjectKey(this)` instead of `ValueKey(uri.toString())` — two same-URI instances no longer share a Flutter element.
- breaking: widget cache is identity-keyed; an explicit `push(rs.copyWith(skipCurrent: false))` now creates a distinct widget per call (modal stacking). `skipCurrent: true` (default) still dedups against preserved cache entries.
- breaking: `PaperTurnEffect` is visually rewritten — outgoing page peels off the surface with size-aware perspective; use the unchanged `PageFlapLeft` / `PageFlapRight` for the previous behavior.
- breaking: `push` / `pushUri` interpret `+` in the URI path as a stack delimiter under `UrlStrategy.stacked`; registering a route path containing `+` under that strategy throws `ArgumentError` at construction.
- feat: `UrlStrategy.stacked` opt-in for deep-linkable route stacks — URLs like `/home+/sheet?tab=2` round-trip across reloads.
- feat: forward-history survives reloads under `UrlStrategy.stacked` — routes beyond the active one are encoded in the URL fragment (`/home+/sheet#/dialog+/toast`), so reloading after a `goBackward` still leaves `goForward` / browser-forward reachable.
- feat: `RouteStackUri` codec for encoding / decoding stack URIs with matrix-style `;` clauses for per-route queryParameters; plus `RouteStackUri.encodeSegments` / `decodeSegments` for the fragment portion.
- feat: `DraggableModalSheet` — drag-down-to-dismiss bottom-sheet modals as first-class routes.
- feat: `DragNavigable` — horizontal swipe to navigate forward / back, drives the standard route animation via tentative-navigation hooks.
- feat: `RouteBuilder.isOverlay` flag keeps the previous route mounted beneath modals so the base actually paints behind.
- feat: tentative-navigation API on `RouteController` (`beginTentativeNavigation`, `updateTentativeProgress`, `commitTentative`, `abortTentative`, `isTentativeActive`) for gesture-driven transitions.
- feat: `PaperTurnBackEffect` mirror of `PaperTurnEffect` for backward page turns.
- feat: `AnimationEffect.previousOnTop` getter for effects where the outgoing layer is the visible mover.
- feat: `AnimationEffectBuilderState.reverseAndAwait` / `forwardAndAwait` for awaiting transition completion.
- fix: stacked-layer `ColorFilter` / `ImageFilter` now reaches Material / ink / `RepaintBoundary` children (previously silently dropped by the canvas-level `saveLayer` path).
- fix: cold-booting into a multi-route stack URL now paints the base route below the top.
- fix: `buildScreen` paints every route in the visible stack as a static layer beneath the active transition pair.
- fix: page-turn effects compute perspective from the active viewport size so wide screens no longer lose pixels to negative-W clipping.
- fix: duplicate path registrations log a warning in release builds (previously a debug-only `assert`).