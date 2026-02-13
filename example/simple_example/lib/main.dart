import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// SIMPLE EXAMPLE — 4 screens, 4 route modes.
//
//   1. PREBUILT + PRESERVED  (green)  — built at startup, state lives forever
//   2. PRESERVED ONLY        (blue)   — built on first visit, state lives forever
//   3. PREBUILT ONLY         (orange) — built at startup, state resets on leave
//   4. DEFAULT               (red)    — built each visit, state resets on leave
//
// Each screen has a counter + text field. Navigate around and watch what
// persists and what resets. Check the console for lifecycle logs.
// ---------------------------------------------------------------------------

void main() {
  setToUrlPathStrategy();
  runApp(const SimpleApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ROUTES
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PrebuiltPreservedRoute extends RouteState {
  PrebuiltPreservedRoute()
    : super.parse('/prebuilt-preserved', animationEffect: const FadeEffect());
}

final class PreservedOnlyRoute extends RouteState {
  PreservedOnlyRoute()
    : super.parse('/preserved-only', animationEffect: const CupertinoEffect());
}

final class PrebuiltOnlyRoute extends RouteState {
  PrebuiltOnlyRoute()
    : super.parse('/prebuilt-only', animationEffect: const SlideUpEffect());
}

final class DefaultRoute extends RouteState {
  DefaultRoute()
    : super.parse('/default', animationEffect: const MaterialEffect());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// APP
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SimpleApp extends StatelessWidget {
  const SimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      builder: (context, child) {
        return Scaffold(
          body: RouteManager(
            fallbackRouteState: PrebuiltPreservedRoute.new,
            clipToBounds: true,
            builders: [
              // 1. PREBUILT + PRESERVED
              RouteBuilder(
                routeState: PrebuiltPreservedRoute(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, routeState) {
                  return DemoScreen(
                    routeState: routeState,
                    title: 'PREBUILT + PRESERVED',
                    subtitle:
                        'Built at startup. State lives forever.\n'
                        'Counter & text survive navigation.',
                    color: Colors.green,
                  );
                },
              ),
              // 2. PRESERVED ONLY
              RouteBuilder(
                routeState: PreservedOnlyRoute(),
                shouldPreserve: true,
                builder: (context, routeState) {
                  return DemoScreen(
                    routeState: routeState,
                    title: 'PRESERVED ONLY',
                    subtitle:
                        'Built on first visit. State lives forever.\n'
                        'Counter & text survive navigation.',
                    color: Colors.blue,
                  );
                },
              ),
              // 3. PREBUILT ONLY
              RouteBuilder(
                routeState: PrebuiltOnlyRoute(),
                shouldPrebuild: true,
                builder: (context, routeState) {
                  return DemoScreen(
                    routeState: routeState,
                    title: 'PREBUILT ONLY',
                    subtitle:
                        'Built at startup. Disposed on leave.\n'
                        'Counter & text RESET every navigation.',
                    color: Colors.orange,
                  );
                },
              ),
              // 4. DEFAULT (neither)
              RouteBuilder(
                routeState: DefaultRoute(),
                builder: (context, routeState) {
                  return DemoScreen(
                    routeState: routeState,
                    title: 'DEFAULT',
                    subtitle:
                        'Built each visit. Disposed on leave.\n'
                        'Counter & text RESET every navigation.',
                    color: Colors.red,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// DEMO SCREEN
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class DemoScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  final String title;
  final String subtitle;
  final Color color;

  const DemoScreen({
    super.key,
    this.routeState,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int _counter = 0;
  int _initCount = 0;
  int _disposeCount = 0;
  final _textController = TextEditingController();

  String get _tag => widget.title;

  void _log(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('[$ts] [$_tag] $message');
  }

  @override
  void initState() {
    super.initState();
    _initCount++;
    _log('initState #$_initCount');
  }

  @override
  void dispose() {
    _disposeCount++;
    _log('dispose #$_disposeCount');
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NavBar(current: _tag),
        Expanded(
          child: Container(
            color: widget.color.withValues(alpha: 0.05),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    // Description
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Counter
                    Text(
                      '$_counter',
                      style: TextStyle(
                        fontSize: 72.0,
                        fontWeight: FontWeight.w200,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    FilledButton.icon(
                      onPressed: () => setState(() => _counter++),
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.color,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Text field
                    SizedBox(
                      width: 280.0,
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          labelText: 'Type something here',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: widget.color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Lifecycle stats
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Lifecycle Stats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          _StatRow(
                            label: 'initState calls',
                            value: '$_initCount',
                            icon: Icons.play_arrow,
                          ),
                          _StatRow(
                            label: 'dispose calls',
                            value: '$_disposeCount',
                            icon: Icons.stop,
                          ),
                          _StatRow(
                            label: 'counter value',
                            value: '$_counter',
                            icon: Icons.tag,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// NAV BAR
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _NavBar extends StatelessWidget {
  final String current;
  const _NavBar({required this.current});

  @override
  Widget build(BuildContext context) {
    final controller = RouteController.of(context);
    return Container(
      color: Colors.grey.shade900,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                    ? () => controller.goBackward()
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
                    ? () => controller.goForward()
                    : null,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _navBtn(
                        controller,
                        'Pre+Pres',
                        'PREBUILT + PRESERVED',
                        PrebuiltPreservedRoute(),
                        Colors.green,
                      ),
                      _navBtn(
                        controller,
                        'Preserved',
                        'PRESERVED ONLY',
                        PreservedOnlyRoute(),
                        Colors.blue,
                      ),
                      _navBtn(
                        controller,
                        'Prebuilt',
                        'PREBUILT ONLY',
                        PrebuiltOnlyRoute(),
                        Colors.orange,
                      ),
                      _navBtn(
                        controller,
                        'Default',
                        'DEFAULT',
                        DefaultRoute(),
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(
    RouteController controller,
    String label,
    String screenTitle,
    RouteState route,
    Color color,
  ) {
    final active = current == screenTitle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: active ? color : Colors.white70,
          backgroundColor: active
              ? color.withValues(alpha: 0.2)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          minimumSize: Size.zero,
        ),
        onPressed: active ? null : () => controller.push(route),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// STAT ROW
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: Colors.grey.shade500),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.0),
          ),
          const SizedBox(width: 8.0),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
