import 'dart:math' as math;

import 'package:df_router/df_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/rendering.dart' show debugRepaintRainbowEnabled;

void main() {
  debugRepaintRainbowEnabled = kDebugMode;
  setToUrlPathStrategy();
  runApp(const MyApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// VERBOSE LOGGER
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void _log(String tag, String message) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  debugPrint('[$ts] [$tag] $message');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ROUTE DEFINITIONS
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HomeRoute extends RouteState {
  HomeRoute() : super.parse('/home', animationEffect: const FadeEffect());
}

final class GalleryRoute extends RouteState {
  GalleryRoute()
      : super.parse('/gallery', animationEffect: const CupertinoEffect());
}

final class CanvasRoute extends RouteState {
  CanvasRoute()
      : super.parse('/canvas', animationEffect: const SlideUpEffect());
}

final class StacksRoute extends RouteState {
  StacksRoute()
      : super.parse('/stacks', animationEffect: const MaterialEffect());
}

final class AnimationsRoute extends RouteState {
  AnimationsRoute()
      : super.parse('/animations', animationEffect: const ForwardEffect());
}

final class TransitionsRoute extends RouteState {
  TransitionsRoute()
      : super.parse('/transitions', animationEffect: const SlideDownEffect());
}

final class GridRoute extends RouteState {
  GridRoute() : super.parse('/grid', animationEffect: const PageFlapLeft());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// APP
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _log('App', 'build');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Scaffold(
          body: RouteManager(
            fallbackRouteState: () {
              _log('RouteManager', 'fallbackRouteState called → HomeRoute');
              return HomeRoute();
            },
            clipToBounds: true,
            onControllerCreated: (controller) {
              _log('RouteManager', 'controller created');
              _log(
                'RouteManager',
                'registered paths: '
                    '/home=${controller.pathExists(Uri.parse('/home'))}, '
                    '/gallery=${controller.pathExists(Uri.parse('/gallery'))}, '
                    '/canvas=${controller.pathExists(Uri.parse('/canvas'))}, '
                    '/stacks=${controller.pathExists(Uri.parse('/stacks'))}, '
                    '/animations=${controller.pathExists(Uri.parse('/animations'))}, '
                    '/transitions=${controller.pathExists(Uri.parse('/transitions'))}, '
                    '/grid=${controller.pathExists(Uri.parse('/grid'))}',
              );
            },
            builders: [
              // ── MODE 1: PREBUILT + PRESERVED ──
              // Built at startup, stays alive forever.
              RouteBuilder(
                routeState: HomeRoute(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, routeState) {
                  _log(
                    'RouteBuilder',
                    '/home builder called (prebuilt+preserved)',
                  );
                  return HomeScreen(routeState: routeState);
                },
              ),
              // ── MODE 2: PRESERVED ONLY ──
              // Built on first visit, stays alive forever.
              RouteBuilder(
                routeState: GalleryRoute(),
                shouldPreserve: true,
                builder: (context, routeState) {
                  _log(
                    'RouteBuilder',
                    '/gallery builder called (preserved only)',
                  );
                  return GalleryScreen(routeState: routeState);
                },
              ),
              // ── MODE 3: PREBUILT + PRESERVED ──
              // Animated canvas built at startup, never disposed.
              RouteBuilder(
                routeState: CanvasRoute(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, routeState) {
                  _log(
                    'RouteBuilder',
                    '/canvas builder called (prebuilt+preserved)',
                  );
                  return CanvasScreen(routeState: routeState);
                },
              ),
              // ── MODE 4: PREBUILT ONLY ──
              // Built at startup, disposes when navigated away.
              RouteBuilder(
                routeState: StacksRoute(),
                shouldPrebuild: true,
                builder: (context, routeState) {
                  _log(
                    'RouteBuilder',
                    '/stacks builder called (prebuilt only)',
                  );
                  return StacksScreen(routeState: routeState);
                },
              ),
              // ── MODE 5: DEFAULT (NEITHER) ──
              // Rebuilt each visit, disposed when leaving.
              RouteBuilder(
                routeState: AnimationsRoute(),
                builder: (context, routeState) {
                  _log('RouteBuilder', '/animations builder called (default)');
                  return AnimationsScreen(routeState: routeState);
                },
              ),
              // ── MODE 6: DEFAULT (NEITHER) ──
              // Transition tester, rebuilt each visit.
              RouteBuilder(
                routeState: TransitionsRoute(),
                builder: (context, routeState) {
                  _log('RouteBuilder', '/transitions builder called (default)');
                  return TransitionsScreen(routeState: routeState);
                },
              ),
              // ── MODE 7: PRESERVED ONLY ──
              // Heavy grid, scroll position preserved.
              RouteBuilder(
                routeState: GridRoute(),
                shouldPreserve: true,
                builder: (context, routeState) {
                  _log('RouteBuilder', '/grid builder called (preserved only)');
                  return GridScreen(routeState: routeState);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// SHARED NAV BAR
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _NavBar extends StatelessWidget {
  final String current;
  const _NavBar({required this.current});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    final navState = controller.pNavigationState.getValue();
    final historyIndex = navState.index;
    final historyLength = navState.routes.length;

    _log(
      'NavBar',
      'build on $current — history: $historyIndex/$historyLength, '
          'canBack=${controller.canGoBackward}, canFwd=${controller.canGoForward}',
    );

    return Container(
      color: Colors.grey.shade900,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44.0,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: controller.canGoBackward
                        ? Colors.white
                        : Colors.white24,
                    size: 20.0,
                  ),
                  onPressed: controller.canGoBackward
                      ? () {
                          _log('NavBar', 'goBackward tapped');
                          controller.goBackward();
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color: controller.canGoForward
                        ? Colors.greenAccent
                        : Colors.white24,
                    size: 20.0,
                  ),
                  onPressed: controller.canGoForward
                      ? () {
                          _log('NavBar', 'goForward tapped');
                          controller.goForward();
                        }
                      : null,
                ),
                const SizedBox(width: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${historyIndex + 1}/$historyLength',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11.0,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (controller.canGoForward)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                      'FWD',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        _navBtn(controller, 'Home', '/home', HomeRoute()),
                        _navBtn(
                          controller,
                          'Gallery',
                          '/gallery',
                          GalleryRoute(),
                        ),
                        _navBtn(
                          controller,
                          'Canvas',
                          '/canvas',
                          CanvasRoute(),
                        ),
                        _navBtn(
                          controller,
                          'Stacks',
                          '/stacks',
                          StacksRoute(),
                        ),
                        _navBtn(
                          controller,
                          'Anim',
                          '/animations',
                          AnimationsRoute(),
                        ),
                        _navBtn(
                          controller,
                          'Trans',
                          '/transitions',
                          TransitionsRoute(),
                        ),
                        _navBtn(controller, 'Grid', '/grid', GridRoute()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // History breadcrumb trail showing where you are in the stack.
          SizedBox(
            height: 16.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: historyLength,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, i) {
                final route = navState.routes[i];
                final isCurrent = i == historyIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.amber
                          : i > historyIndex
                              ? Colors.greenAccent.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    child: Text(
                      route.uri.path.substring(1),
                      style: TextStyle(
                        fontSize: 9.0,
                        color: isCurrent ? Colors.black : Colors.white54,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(
    RouteController controller,
    String label,
    String path,
    RouteState route,
  ) {
    final active = current == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.amber : Colors.white70,
          backgroundColor:
              active ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        ),
        onPressed: active
            ? null
            : () {
                _log(
                  'NavBar',
                  'push $path (effect: ${route.animationEffect.runtimeType})',
                );
                controller.push(route);
              },
        child: Text(label, style: const TextStyle(fontSize: 13.0)),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ModeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 1. HOME — prebuilt + preserved
// Animated shimmer background, counter that persists across navigations.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class HomeScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const HomeScreen({super.key, this.routeState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _buildCount = 0;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _log(
      'Home',
      'initState — PREBUILT+PRESERVED — should fire ONCE at startup',
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _log('Home', 'dispose — PREBUILT+PRESERVED — should NEVER fire during nav');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _log('Home', 'build #$_buildCount (counter=$_counter)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/home'),
          Expanded(
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + 2.0 * _shimmer.value, -1.0),
                      end: Alignment(1.0 + 2.0 * _shimmer.value, 1.0),
                      colors: const [
                        Color(0xFF1A237E),
                        Color(0xFF311B92),
                        Color(0xFF4A148C),
                        Color(0xFF311B92),
                        Color(0xFF1A237E),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _ModeChip(
                      label: 'PREBUILT + PRESERVED',
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Counter: $_counter',
                      style: const TextStyle(
                        fontSize: 48.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'build() called $_buildCount times',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Counter persists. Shimmer keeps running.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.0),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            setState(() => _counter--);
                            _log('Home', 'counter decremented to $_counter');
                          },
                          icon: const Icon(Icons.remove),
                          label: const Text('Dec'),
                        ),
                        const SizedBox(width: 12.0),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() => _counter++);
                            _log('Home', 'counter incremented to $_counter');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Inc'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 2. GALLERY — preserved only (NOT prebuilt)
// Heavy ListView with 300 items. Scroll position survives navigation.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GalleryScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const GalleryScreen({super.key, this.routeState});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _scrollController = ScrollController();
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _log('Gallery', 'initState — PRESERVED ONLY — fires on FIRST visit only');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _log('Gallery', 'dispose — PRESERVED ONLY — should NEVER fire during nav');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Gallery', 'build (selected=$_selectedIndex)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/gallery'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.teal.shade50,
            child: const Row(
              children: [
                _ModeChip(label: 'PRESERVED ONLY', color: Colors.teal),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Scroll position & selection survive navigation',
                    style: TextStyle(fontSize: 12.0, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 300,
              itemBuilder: (context, index) {
                return _GalleryTile(
                  index: index,
                  selected: index == _selectedIndex,
                  onTap: () {
                    _log('Gallery', 'selected item $index');
                    setState(() => _selectedIndex = index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hue = (index * 7.0) % 360.0;
    final color = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
    final lightColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.85).toColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [color, color.withValues(alpha: 0.7)]
                : [lightColor, lightColor.withValues(alpha: 0.5)],
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8.0,
                    offset: const Offset(0.0, 2.0),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item #${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Hue ${hue.toStringAsFixed(0)} — tap to select',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: selected ? Colors.white70 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 3. CANVAS — prebuilt + preserved
// Animated spirograph drawn with CustomPaint. Keeps animating off-screen.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CanvasScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const CanvasScreen({super.key, this.routeState});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  double _r1 = 100.0;
  double _r2 = 40.0;
  double _d = 60.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _log(
      'Canvas',
      'initState — PREBUILT+PRESERVED — fires ONCE at startup, '
          'animation keeps running even when off-screen',
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _log(
      'Canvas',
      'dispose — PREBUILT+PRESERVED — should NEVER fire during nav',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Canvas', 'build (R1=$_r1, R2=$_r2, D=$_d)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/canvas'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                const Row(
                  children: [
                    _ModeChip(
                      label: 'PREBUILT + PRESERVED',
                      color: Colors.deepPurple,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Animation runs even when off-screen',
                        style: TextStyle(fontSize: 12.0, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                _buildSlider('R1', _r1, 20.0, 200.0, (v) {
                  setState(() => _r1 = v);
                }),
                _buildSlider('R2', _r2, 10.0, 100.0, (v) {
                  setState(() => _r2 = v);
                }),
                _buildSlider('D', _d, 10.0, 150.0, (v) {
                  setState(() => _d = v);
                }),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SpirographPainter(
                    t: _anim.value,
                    r1: _r1,
                    r2: _r2,
                    d: _d,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 24.0,
          child: Text(label, style: const TextStyle(fontSize: 12.0)),
        ),
        Expanded(
          child: _SimpleSlider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40.0,
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 12.0),
          ),
        ),
      ],
    );
  }
}

// Avoids the Overlay ancestor requirement that Material Slider has when
// used inside MaterialApp.builder (which bypasses the Navigator/Overlay).
class _SimpleSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SimpleSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fraction = (value - min) / (max - min);
        final trackWidth = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newFraction =
                (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
            onChanged(min + newFraction * (max - min));
          },
          onTapDown: (details) {
            final newFraction =
                (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
            onChanged(min + newFraction * (max - min));
          },
          child: Container(
            height: 32.0,
            alignment: Alignment.centerLeft,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 4.0,
                  width: trackWidth,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Container(
                  height: 4.0,
                  width: trackWidth * fraction,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                Positioned(
                  left: (trackWidth * fraction - 8.0)
                      .clamp(0.0, trackWidth - 16.0),
                  child: Container(
                    width: 16.0,
                    height: 16.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpirographPainter extends CustomPainter {
  final double t;
  final double r1;
  final double r2;
  final double d;

  _SpirographPainter({
    required this.t,
    required this.r1,
    required this.r2,
    required this.d,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final maxAngle = t * 40.0 * math.pi;
    const steps = 2000;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * maxAngle;
      final diff = r1 - r2;
      final ratio = diff / r2;
      final x = cx + diff * math.cos(angle) + d * math.cos(ratio * angle);
      final y = cy + diff * math.sin(angle) - d * math.sin(ratio * angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final hue = (t * 360.0) % 360.0;
    paint.color = HSLColor.fromAHSL(0.8, hue, 0.8, 0.5).toColor();
    canvas.drawPath(path, paint);

    paint
      ..color =
          HSLColor.fromAHSL(0.3, (hue + 120.0) % 360.0, 0.8, 0.5).toColor()
      ..strokeWidth = 0.5;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpirographPainter oldDelegate) => true;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 4. STACKS — prebuilt only (NOT preserved)
// Complex Stack with positioned layers and a draggable circle.
// Draggable position resets each visit because not preserved.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class StacksScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const StacksScreen({super.key, this.routeState});

  @override
  State<StacksScreen> createState() => _StacksScreenState();
}

class _StacksScreenState extends State<StacksScreen> {
  Offset _dragPosition = const Offset(100.0, 200.0);
  int _layerCount = 5;

  @override
  void initState() {
    super.initState();
    _log(
      'Stacks',
      'initState — PREBUILT ONLY — fires at STARTUP, '
          'state resets when navigated away',
    );
  }

  @override
  void dispose() {
    _log(
      'Stacks',
      'dispose — PREBUILT ONLY — fires when navigated away '
          '(drag pos lost: $_dragPosition)',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Stacks', 'build (layers=$_layerCount, drag=$_dragPosition)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/stacks'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const _ModeChip(label: 'PREBUILT ONLY', color: Colors.orange),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: Text(
                    'Drag position resets each visit',
                    style: TextStyle(fontSize: 12.0, color: Colors.black54),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _layerCount > 1
                          ? () => setState(() => _layerCount--)
                          : null,
                      iconSize: 18.0,
                    ),
                    Text('$_layerCount layers'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _layerCount < 15
                          ? () => setState(() => _layerCount++)
                          : null,
                      iconSize: 18.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < _layerCount; i++)
                      Positioned(
                        left: 20.0 + i * 30.0,
                        top: 40.0 + i * 25.0,
                        child: Transform.rotate(
                          angle: i * 0.15,
                          child: Container(
                            width: 120.0 + i * 10.0,
                            height: 80.0 + i * 8.0,
                            decoration: BoxDecoration(
                              color: HSLColor.fromAHSL(
                                0.7,
                                (i * 40.0) % 360.0,
                                0.7,
                                0.6,
                              ).toColor(),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8.0,
                                  offset: const Offset(2.0, 4.0),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Layer $i',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: _dragPosition.dx - 30.0,
                      top: _dragPosition.dy - 30.0,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _dragPosition += details.delta;
                          });
                        },
                        child: Container(
                          width: 60.0,
                          height: 60.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade400,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 16.0,
                                offset: const Offset(0.0, 4.0),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.open_with,
                            color: Colors.white,
                            size: 28.0,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.0,
                      left: 0.0,
                      right: 0.0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            'Drag: (${_dragPosition.dx.toStringAsFixed(0)}, '
                            '${_dragPosition.dy.toStringAsFixed(0)})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 5. ANIMATIONS — default (neither prebuilt nor preserved)
// Multiple concurrent animations. All restart from scratch each visit.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class AnimationsScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const AnimationsScreen({super.key, this.routeState});

  @override
  State<AnimationsScreen> createState() => _AnimationsScreenState();
}

class _AnimationsScreenState extends State<AnimationsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotation;
  late final AnimationController _bounce;
  late final AnimationController _pulse;
  late final AnimationController _colorShift;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _colorShift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _log(
      'Animations',
      'initState — DEFAULT — fires EVERY visit, '
          '4 controllers created (rotation, bounce, pulse, colorShift)',
    );
  }

  @override
  void dispose() {
    _rotation.dispose();
    _bounce.dispose();
    _pulse.dispose();
    _colorShift.dispose();
    _log(
      'Animations',
      'dispose — DEFAULT — fires when navigated away '
          '(counter lost: $_counter)',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Animations', 'build (counter=$_counter)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/animations'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.pink.shade50,
            child: Row(
              children: [
                const _ModeChip(label: 'DEFAULT (NEITHER)', color: Colors.pink),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: Text(
                    'Everything resets on each visit',
                    style: TextStyle(fontSize: 12.0, color: Colors.black54),
                  ),
                ),
                Text(
                  'Counter: $_counter',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4.0),
                IconButton(
                  icon: const Icon(Icons.add, size: 18.0),
                  onPressed: () {
                    setState(() => _counter++);
                    _log('Animations', 'counter incremented to $_counter');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _rotation,
                _bounce,
                _pulse,
                _colorShift,
              ]),
              builder: (context, _) {
                final hue = _colorShift.value * 360.0;
                return Container(
                  color: HSLColor.fromAHSL(0.05, hue, 0.8, 0.5).toColor(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _rotatingShape(
                            _rotation.value,
                            Colors.blue,
                            'Rotate',
                          ),
                          _rotatingShape(
                            _rotation.value * 1.5,
                            Colors.green,
                            'x1.5',
                          ),
                          _rotatingShape(
                            _rotation.value * 0.5,
                            Colors.red,
                            'x0.5',
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _bouncingCircle(_bounce.value, Colors.purple),
                          _bouncingCircle(
                            (_bounce.value + 0.33) % 1.0,
                            Colors.orange,
                          ),
                          _bouncingCircle(
                            (_bounce.value + 0.66) % 1.0,
                            Colors.cyan,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _pulsingCircle(_pulse.value, hue),
                          _pulsingCircle(_pulse.value, (hue + 120.0) % 360.0),
                          _pulsingCircle(_pulse.value, (hue + 240.0) % 360.0),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: List.generate(12, (i) {
                            final barHue = (hue + i * 30.0) % 360.0;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                height: 40.0 +
                                    30.0 *
                                        math.sin(
                                          _bounce.value * math.pi + i * 0.5,
                                        ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: HSLColor.fromAHSL(
                                    0.8,
                                    barHue,
                                    0.7,
                                    0.5,
                                  ).toColor(),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rotatingShape(double turns, Color color, String label) {
    return Transform.rotate(
      angle: turns * 2.0 * math.pi,
      child: Container(
        width: 70.0,
        height: 70.0,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12.0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _bouncingCircle(double t, Color color) {
    final y = -60.0 * math.sin(t * math.pi);
    return Transform.translate(
      offset: Offset(0.0, y),
      child: Container(
        width: 50.0,
        height: 50.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 12.0 + 8.0 * t,
              offset: Offset(0.0, 4.0 + 8.0 * (1.0 - t)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulsingCircle(double t, double hue) {
    final scale = 0.7 + 0.3 * t;
    final color = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 60.0,
        height: 60.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.2)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3 * t),
              blurRadius: 20.0 * t,
              spreadRadius: 5.0 * t,
            ),
          ],
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 6. TRANSITIONS — default (neither)
// Test every single transition effect. Rebuilt each visit.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class TransitionsScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const TransitionsScreen({super.key, this.routeState});

  @override
  State<TransitionsScreen> createState() => _TransitionsScreenState();
}

class _TransitionsScreenState extends State<TransitionsScreen> {
  static const _effects = <String, AnimationEffect>{
    'NoEffect': NoEffect(),
    'FadeEffect': FadeEffect(),
    'FadeEffectWeb': FadeEffectWeb(),
    'ForwardEffect': ForwardEffect(),
    'ForwardEffectWeb': ForwardEffectWeb(),
    'BackwardEffect': BackwardEffect(),
    'BackwardEffectWeb': BackwardEffectWeb(),
    'SlideUpEffect': SlideUpEffect(),
    'SlideDownEffect': SlideDownEffect(),
    'CupertinoEffect': CupertinoEffect(),
    'MaterialEffect': MaterialEffect(),
    'PageFlapLeft': PageFlapLeft(),
    'PageFlapRight': PageFlapRight(),
  };

  String _lastUsed = '';

  @override
  void initState() {
    super.initState();
    _log('Transitions', 'initState — DEFAULT — fires EVERY visit');
  }

  @override
  void dispose() {
    _log('Transitions', 'dispose — DEFAULT — fires when navigated away');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Transitions', 'build (lastUsed=$_lastUsed)');
    final controller = RouteController.of(context);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/transitions'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.cyan.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _ModeChip(label: 'DEFAULT (NEITHER)', color: Colors.cyan),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Test every transition by navigating to Home',
                        style: TextStyle(fontSize: 12.0, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                if (_lastUsed.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'Last used: $_lastUsed',
                    style:
                        TextStyle(fontSize: 11.0, color: Colors.cyan.shade700),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12.0),
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 2.2,
              children: _effects.entries.map((entry) {
                return _TransitionCard(
                  name: entry.key,
                  effect: entry.value,
                  onTap: () {
                    _log(
                      'Transitions',
                      'push HomeRoute with ${entry.key} '
                          '(${entry.value.duration.inMilliseconds}ms)',
                    );
                    setState(() => _lastUsed = entry.key);
                    controller.push(
                      HomeRoute().copyWith(animationEffect: entry.value),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backward Navigation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                ),
                const SizedBox(height: 8.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _effects.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ActionChip(
                          label: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 10.0),
                          ),
                          onPressed: controller.canGoBackward
                              ? () {
                                  _log(
                                    'Transitions',
                                    'goBackward with ${entry.key}',
                                  );
                                  setState(
                                    () => _lastUsed = '${entry.key} (back)',
                                  );
                                  controller.goBackward(
                                    animationEffect: entry.value,
                                  );
                                }
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  final String name;
  final AnimationEffect effect;
  final VoidCallback onTap;

  const _TransitionCard({
    required this.name,
    required this.effect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                '${effect.duration.inMilliseconds}ms',
                style: TextStyle(fontSize: 11.0, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// 7. GRID — preserved only (NOT prebuilt)
// Heavy grid of colored cells with selection. Scroll + selection preserved.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GridScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const GridScreen({super.key, this.routeState});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final _selected = <int>{};
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _log('Grid', 'initState — PRESERVED ONLY — fires on FIRST visit only');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _log(
      'Grid',
      'dispose — PRESERVED ONLY — should NEVER fire during nav '
          '(${_selected.length} selections would be lost)',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log('Grid', 'build (${_selected.length} selected)');
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const _NavBar(current: '/grid'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                const _ModeChip(label: 'PRESERVED ONLY', color: Colors.amber),
                const SizedBox(width: 8.0),
                Text(
                  '${_selected.length} selected',
                  style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _log('Grid', 'cleared ${_selected.length} selections');
                      setState(() => _selected.clear());
                    },
                    child:
                        const Text('Clear', style: TextStyle(fontSize: 12.0)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
              itemCount: 500,
              itemBuilder: (context, index) {
                final isSelected = _selected.contains(index);
                final hue = (index * 3.7) % 360.0;
                final color = HSLColor.fromAHSL(1.0, hue, 0.5, 0.6).toColor();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(index);
                      } else {
                        _selected.add(index);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8.0),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.0)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 8.0,
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
