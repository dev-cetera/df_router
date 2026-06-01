import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// KINDLE EXAMPLE — paper-style page turning + state preservation demo.
//
// Five routes, all preserved (shouldPreserve: true). Two of them are also
// PREBUILT at app start (shouldPrebuild: true) — watch the console: their
// `initState` fires before you ever navigate to them.
//
// Every screen has a "+ Add bookmark" button that bumps a local counter
// stored in its State. Because every route is preserved, those counters
// survive every navigation — flip between books, then come back, and the
// number is exactly where you left it. Lifecycle logs (initState / dispose /
// build #N) are printed to the console so you can watch the router work.
//
// The animation is `PaperTurnEffect` for book-to-book navigation, `FadeEffect`
// for the library and the about screen, and `SlideUpEffect` for settings.
// ---------------------------------------------------------------------------

void main() {
  setToUrlPathStrategy();
  runApp(const KindleApp());
}

// ─── PALETTE ────────────────────────────────────────────────────────────────
// Kindle/paper-ish sepia tones.

const _kPaper = Color(0xFFF5EEDC); // cream paper background
const _kInk = Color(0xFF3E2C1C); // dark-brown body text
const _kInkSoft = Color(0xFF6B5642); // muted brown for secondary
const _kBinding = Color(0xFF3E2C1C); // top/bottom bar background
const _kAccent = Color(0xFF8B6F47); // accent (buttons, borders)

// ─── LOGGING ────────────────────────────────────────────────────────────────

void _log(String tag, String message) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  debugPrint('[$ts] [$tag] $message');
}

// ─── ROUTES ─────────────────────────────────────────────────────────────────

final class LibraryRoute extends RouteState {
  LibraryRoute() : super.parse('/library', animationEffect: const FadeEffect());
}

final class Book1Route extends RouteState {
  Book1Route()
      : super.parse('/book/1', animationEffect: const PaperTurnEffect());
}

final class Book2Route extends RouteState {
  Book2Route()
      : super.parse('/book/2', animationEffect: const PaperTurnEffect());
}

final class Book3Route extends RouteState {
  Book3Route()
      : super.parse('/book/3', animationEffect: const PaperTurnEffect());
}

final class SettingsRoute extends RouteState {
  SettingsRoute()
      : super.parse('/settings', animationEffect: const SlideUpEffect());
}

// ─── BOOK CATALOG (mock data) ──────────────────────────────────────────────

class _Book {
  final String id;
  final String title;
  final String author;
  final Color spineColor;
  final List<String> excerpt;
  const _Book({
    required this.id,
    required this.title,
    required this.author,
    required this.spineColor,
    required this.excerpt,
  });
}

const _kBooks = <_Book>[
  _Book(
    id: '1',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    spineColor: Color(0xFF4A6B5C),
    excerpt: [
      'In my younger and more vulnerable years my father gave me some '
          "advice that I've been turning over in my mind ever since.",
      '"Whenever you feel like criticizing any one," he told me, "just '
          "remember that all the people in this world haven't had the "
          'advantages that you\'ve had."',
      'He didn\'t say any more, but we\'ve always been unusually '
          'communicative in a reserved way, and I understood that he meant '
          'a great deal more than that.',
    ],
  ),
  _Book(
    id: '2',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    spineColor: Color(0xFFA5707E),
    excerpt: [
      'It is a truth universally acknowledged, that a single man in '
          'possession of a good fortune, must be in want of a wife.',
      'However little known the feelings or views of such a man may be on '
          'his first entering a neighbourhood, this truth is so well fixed '
          'in the minds of the surrounding families, that he is considered '
          'the rightful property of some one or other of their daughters.',
      '"My dear Mr. Bennet," said his lady to him one day, "have you '
          'heard that Netherfield Park is let at last?"',
    ],
  ),
  _Book(
    id: '3',
    title: '1984',
    author: 'George Orwell',
    spineColor: Color(0xFF5A5A5A),
    excerpt: [
      'It was a bright cold day in April, and the clocks were striking '
          'thirteen.',
      'Winston Smith, his chin nuzzled into his breast in an effort to '
          'escape the vile wind, slipped quickly through the glass doors '
          'of Victory Mansions, though not quickly enough to prevent a '
          'swirl of gritty dust from entering along with him.',
      'The hallway smelt of boiled cabbage and old rag mats. At one end '
          'of it a coloured poster, too large for indoor display, had been '
          'tacked to the wall.',
    ],
  ),
];

// ─── APP ────────────────────────────────────────────────────────────────────

class KindleApp extends StatelessWidget {
  const KindleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'df_router — Kindle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _kAccent,
        scaffoldBackgroundColor: _kPaper,
      ),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _kPaper,
          body: RouteManager(
            fallbackRouteState: LibraryRoute.new,
            clipToBounds: true,
            builders: [
              // ── LIBRARY: prebuilt + preserved (the home screen) ─────────
              RouteBuilder(
                routeState: LibraryRoute(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, routeState) =>
                    LibraryScreen(routeState: routeState),
              ),
              // ── BOOK 1: prebuilt + preserved (instant first-tap turn) ──
              RouteBuilder(
                routeState: Book1Route(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, routeState) =>
                    BookScreen(routeState: routeState, book: _kBooks[0]),
              ),
              // ── BOOK 2: preserved only (built on first visit) ──────────
              RouteBuilder(
                routeState: Book2Route(),
                shouldPreserve: true,
                builder: (context, routeState) =>
                    BookScreen(routeState: routeState, book: _kBooks[1]),
              ),
              // ── BOOK 3: preserved only ─────────────────────────────────
              RouteBuilder(
                routeState: Book3Route(),
                shouldPreserve: true,
                builder: (context, routeState) =>
                    BookScreen(routeState: routeState, book: _kBooks[2]),
              ),
              // ── SETTINGS: preserved only ───────────────────────────────
              RouteBuilder(
                routeState: SettingsRoute(),
                shouldPreserve: true,
                builder: (context, routeState) =>
                    SettingsScreen(routeState: routeState),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── SHARED LIFECYCLE-LOGGING STATE MIXIN ───────────────────────────────────

mixin _LifecycleLogged<W extends StatefulWidget> on State<W> {
  String get logTag;
  int _buildCount = 0;
  int _initCount = 0;
  int _disposeCount = 0;

  int get initCount => _initCount;
  int get disposeCount => _disposeCount;
  int get buildCount => _buildCount;

  @override
  void initState() {
    super.initState();
    _initCount++;
    _log(logTag, 'initState (#$_initCount)');
  }

  @override
  void dispose() {
    _disposeCount++;
    _log(logTag, 'dispose (#$_disposeCount)');
    super.dispose();
  }

  void logBuild() {
    _buildCount++;
    _log(logTag, 'build (#$_buildCount)');
  }
}

// ─── LIBRARY SCREEN ─────────────────────────────────────────────────────────

class LibraryScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const LibraryScreen({super.key, this.routeState});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with _LifecycleLogged {
  @override
  String get logTag => 'LIBRARY';

  int _bookmarks = 0;

  @override
  Widget build(BuildContext context) {
    logBuild();
    return Column(
      children: [
        const _TopBar(title: 'Your Library', current: '/library'),
        Expanded(
          child: Container(
            color: _kPaper,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tap a book to open it.\n'
                    'The page-turn between books is `PaperTurnEffect`.',
                    style: TextStyle(
                      color: _kInkSoft,
                      fontSize: 14.0,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // ── BOOKSHELF ────────────────────────────────────
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.65,
                    children: [
                      _BookCover(
                        book: _kBooks[0],
                        onTap: () => RouteController.of(context)
                            .push(Book1Route()),
                      ),
                      _BookCover(
                        book: _kBooks[1],
                        onTap: () => RouteController.of(context)
                            .push(Book2Route()),
                      ),
                      _BookCover(
                        book: _kBooks[2],
                        onTap: () => RouteController.of(context)
                            .push(Book3Route()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  // ── PERSISTENCE PROOF ────────────────────────────
                  _PersistenceCard(
                    tag: 'LIBRARY',
                    counter: _bookmarks,
                    counterLabel: 'Library bookmarks',
                    initCount: initCount,
                    buildCount: buildCount,
                    onIncrement: () => setState(() => _bookmarks++),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── BOOK SCREEN ────────────────────────────────────────────────────────────

class BookScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  final _Book book;
  const BookScreen({super.key, this.routeState, required this.book});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> with _LifecycleLogged {
  @override
  String get logTag => 'BOOK ${widget.book.id}';

  int _bookmarks = 0;

  RouteState _nextBookRoute() {
    // Cycle through books 1 → 2 → 3 → 1.
    switch (widget.book.id) {
      case '1':
        return Book2Route();
      case '2':
        return Book3Route();
      default:
        return Book1Route();
    }
  }

  RouteState _previousBookRoute() {
    switch (widget.book.id) {
      case '1':
        return Book3Route();
      case '2':
        return Book1Route();
      default:
        return Book2Route();
    }
  }

  @override
  Widget build(BuildContext context) {
    logBuild();
    return Column(
      children: [
        _TopBar(
          title: widget.book.title,
          subtitle: 'by ${widget.book.author}',
          current: '/book/${widget.book.id}',
        ),
        Expanded(
          child: Container(
            // Opaque sepia background. The page mounted *underneath* during a
            // PaperTurnEffect transition would otherwise bleed through.
            color: _kPaper,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── PAGE-TURN BUTTONS ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InkButton(
                        icon: Icons.chevron_left,
                        label: 'Previous book',
                        // Override the route's default (forward) animation so
                        // "Previous" plays the mirror-direction paper turn —
                        // otherwise next/previous look identical and you
                        // can't tell which direction you went.
                        onPressed: () => RouteController.of(context).push(
                          _previousBookRoute(),
                          animationEffect: const PaperTurnBackEffect(),
                        ),
                      ),
                      _InkButton(
                        icon: Icons.chevron_right,
                        label: 'Next book',
                        onPressed: () => RouteController.of(context)
                            .push(_nextBookRoute()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  // ── EXCERPT ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: widget.book.spineColor.withValues(alpha: 0.5),
                          width: 3.0,
                        ),
                      ),
                    ),
                    child: Text(
                      'Chapter 1',
                      style: TextStyle(
                        color: widget.book.spineColor,
                        fontSize: 12.0,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  for (final paragraph in widget.book.excerpt) ...[
                    Text(
                      paragraph,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 16.0,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                  const SizedBox(height: 16.0),
                  // ── PERSISTENCE PROOF ────────────────────────────
                  _PersistenceCard(
                    tag: 'BOOK ${widget.book.id}',
                    counter: _bookmarks,
                    counterLabel:
                        'Bookmarks in "${widget.book.title}"',
                    initCount: initCount,
                    buildCount: buildCount,
                    onIncrement: () => setState(() => _bookmarks++),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SETTINGS SCREEN ────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const SettingsScreen({super.key, this.routeState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with _LifecycleLogged {
  @override
  String get logTag => 'SETTINGS';

  int _fontSizeBumps = 0;

  @override
  Widget build(BuildContext context) {
    logBuild();
    return Column(
      children: [
        const _TopBar(title: 'Settings', current: '/settings'),
        Expanded(
          child: Container(
            color: _kPaper,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Settings is preserved too — bumping the font size below '
                    'and then navigating away will leave the value intact '
                    'when you come back.',
                    style: TextStyle(
                      color: _kInkSoft,
                      fontSize: 14.0,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _PersistenceCard(
                    tag: 'SETTINGS',
                    counter: _fontSizeBumps,
                    counterLabel: 'Font-size bumps',
                    initCount: initCount,
                    buildCount: buildCount,
                    onIncrement: () => setState(() => _fontSizeBumps++),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── COMMON WIDGETS ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String current;
  const _TopBar({required this.title, this.subtitle, required this.current});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    return Container(
      color: _kBinding,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 20.0,
                  color: controller.canGoBackward
                      ? _kPaper
                      : _kPaper.withValues(alpha: 0.3),
                ),
                // Mirror page-turn animation when stepping back through book
                // history — without this the back-step would use `NoEffect`
                // (the default) and the user would only see a forward paper
                // turn from book-to-book, never the reverse.
                onPressed: controller.canGoBackward
                    ? () => controller.goBackward(
                          animationEffect: const PaperTurnBackEffect(),
                        )
                    : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward,
                  size: 20.0,
                  color: controller.canGoForward
                      ? _kPaper
                      : _kPaper.withValues(alpha: 0.3),
                ),
                onPressed: controller.canGoForward
                    ? controller.goForward
                    : null,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kPaper,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: _kPaper.withValues(alpha: 0.6),
                          fontSize: 11.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              _NavChip(
                label: 'Library',
                active: current == '/library',
                onTap: () =>
                    RouteController.of(context).push(LibraryRoute()),
              ),
              _NavChip(
                label: 'Settings',
                active: current == '/settings',
                onTap: () =>
                    RouteController.of(context).push(SettingsRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: active ? _kPaper : _kPaper.withValues(alpha: 0.6),
          backgroundColor: active
              ? _kAccent.withValues(alpha: 0.45)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          minimumSize: Size.zero,
        ),
        onPressed: active ? null : onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final _Book book;
  final VoidCallback onTap;
  const _BookCover({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: book.spineColor,
      borderRadius: BorderRadius.circular(4.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                book.title.toUpperCase(),
                style: const TextStyle(
                  color: _kPaper,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                height: 1.0,
                color: _kPaper.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 6.0),
              Text(
                book.author,
                style: TextStyle(
                  color: _kPaper.withValues(alpha: 0.8),
                  fontSize: 10.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _InkButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.0, color: _kAccent),
      label: Text(
        label,
        style: const TextStyle(
          color: _kInk,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: _kAccent.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
    );
  }
}

class _PersistenceCard extends StatelessWidget {
  final String tag;
  final int counter;
  final String counterLabel;
  final int initCount;
  final int buildCount;
  final VoidCallback onIncrement;
  const _PersistenceCard({
    required this.tag,
    required this.counter,
    required this.counterLabel,
    required this.initCount,
    required this.buildCount,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _kPaper,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: _kAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persistence check — $tag',
            style: const TextStyle(
              color: _kInkSoft,
              fontSize: 11.0,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$counter',
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 40.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  counterLabel,
                  style: const TextStyle(
                    color: _kInkSoft,
                    fontSize: 13.0,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onIncrement,
                icon: const Icon(Icons.bookmark_add_outlined, size: 16.0),
                label: const Text('Add bookmark'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: _kPaper,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Lifecycle stats — proof of preservation.
          //
          //   initState (#)  → if it stays at 1 across navigations, the State
          //                    object survived (i.e. preservation worked).
          //   build (#)      → the build call count. Should grow only when
          //                    the screen is actually visible.
          //
          // If you tap "Add bookmark" then navigate away and come back, both
          // the counter and `initState (#1)` line should be the same. If
          // initState reads (#2) you lost preservation somewhere.
          Wrap(
            spacing: 16.0,
            runSpacing: 4.0,
            children: [
              _StatPill(label: 'initState (#)', value: '$initCount'),
              _StatPill(label: 'build (#)', value: '$buildCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kInkSoft,
              fontSize: 11.0,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            value,
            style: const TextStyle(
              color: _kInk,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
