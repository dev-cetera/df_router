import 'dart:async';

import 'package:df_router/df_router.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// MODAL EXAMPLE — three flavors of modal-as-route on top of a base page.
//
// All three modals are registered with `isOverlay: true`, which tells the
// router "while this route is current, keep the previous route alive in the
// cache so it can render underneath." Each modal route uses
// `animationEffect: NoEffect()` because the modal widget itself owns its
// slide/fade-in animation — the route system shouldn't run a competing one.
//
// Dismissal in every case is just `RouteController.goBackward()`, either
// triggered by drag, scrim tap, button, or an auto-timeout.
// ---------------------------------------------------------------------------

void main() {
  setToUrlPathStrategy();
  runApp(const ModalExampleApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ROUTES
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class HomeRoute extends RouteState {
  HomeRoute() : super.parse('/home', animationEffect: const FadeEffect());
}

final class SheetRoute extends RouteState {
  SheetRoute() : super.parse('/sheet', animationEffect: const NoEffect());
}

final class ConfirmDialogRoute extends RouteState {
  ConfirmDialogRoute()
      : super.parse('/dialog', animationEffect: const NoEffect());
}

final class ToastRoute extends RouteState {
  ToastRoute() : super.parse('/toast', animationEffect: const NoEffect());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// APP
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ModalExampleApp extends StatelessWidget {
  const ModalExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      builder: (context, _) {
        return Scaffold(
          body: RouteManager(
            // `stacked` makes the URL bar reflect the full visible stack:
            //   /home               (just home)
            //   /home+/sheet        (home with the sheet on top)
            //   /home+/dialog       (home with the dialog on top)
            // Push extends the URL, goBackward shortens it. Cold-booting any
            // of these URLs rehydrates the stack so a bookmark really does
            // open with the modal on top of the home page.
            urlStrategy: UrlStrategy.stacked,
            fallbackRouteState: HomeRoute.new,
            builders: [
              RouteBuilder(
                routeState: HomeRoute(),
                shouldPrebuild: true,
                shouldPreserve: true,
                builder: (context, state) => HomeScreen(routeState: state),
              ),
              RouteBuilder(
                routeState: SheetRoute(),
                isOverlay: true,
                builder: (context, state) => SheetScreen(routeState: state),
              ),
              RouteBuilder(
                routeState: ConfirmDialogRoute(),
                isOverlay: true,
                builder: (context, state) => ConfirmDialogScreen(
                  routeState: state,
                ),
              ),
              RouteBuilder(
                routeState: ToastRoute(),
                isOverlay: true,
                builder: (context, state) => ToastScreen(routeState: state),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// HOME — the always-mounted base page that everything stacks on top of
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
  // A perpetually-animating background so it's obvious the home page is
  // still live (not snapshotted) when a modal is on top of it.
  late final AnimationController _shimmer;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _shimmer.value, -1.0),
              end: Alignment(1.0 + 2.0 * _shimmer.value, 1.0),
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surface,
                theme.colorScheme.tertiaryContainer,
              ],
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Modal Patterns',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Each modal is a route flagged isOverlay: true. '
                    'This home page stays mounted underneath every modal — '
                    'watch the shimmer and counter keep working.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.inverseSurface.withValues(
                      alpha: 0.85,
                    ),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: theme.colorScheme.onInverseSurface,
                        onPressed: () => setState(() => _counter--),
                      ),
                      Text(
                        '$_counter',
                        style: TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: theme.colorScheme.onInverseSurface,
                        onPressed: () => setState(() => _counter++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),
                _ModalCard(
                  icon: Icons.expand_less,
                  title: 'Draggable Bottom Sheet',
                  subtitle:
                      'DraggableModalSheet — slide up, drag down to dismiss, '
                      'tap scrim',
                  onTap: () => RouteController.of(context).push(SheetRoute()),
                ),
                const SizedBox(height: 12.0),
                _ModalCard(
                  icon: Icons.center_focus_strong,
                  title: 'Centered Dialog',
                  subtitle:
                      'Custom widget — fade+scale entry, tap scrim or button',
                  onTap: () =>
                      RouteController.of(context).push(ConfirmDialogRoute()),
                ),
                const SizedBox(height: 12.0),
                _ModalCard(
                  icon: Icons.notifications_active,
                  title: 'Auto-Dismiss Toast',
                  subtitle: 'Slides in from top, dismisses itself after 2.5s '
                      '(or tap it)',
                  onTap: () => RouteController.of(context).push(ToastRoute()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 360.0),
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12.0),
        elevation: 2.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 28.0),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.disabledColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// SHEET — the built-in DraggableModalSheet wrapper
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SheetScreen extends StatelessWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const SheetScreen({super.key, this.routeState});

  @override
  Widget build(BuildContext context) {
    return DraggableModalSheet(
      maxHeightFraction: 0.55,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Drag down, tap the dim area above, or hit "Save & Close".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16.0),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Dark mode'),
              trailing: Switch(value: true, onChanged: _ignoreChange),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_outlined),
              title: Text('Notifications'),
              trailing: Switch(value: false, onChanged: _ignoreChange),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => DraggableModalSheet.dismiss(context),
              child: const Text('Save & Close'),
            ),
          ],
        ),
      ),
    );
  }

  static void _ignoreChange(bool _) {}
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// DIALOG — centered fade+scale card, hand-rolled to show the pattern
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ConfirmDialogScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const ConfirmDialogScreen({super.key, this.routeState});

  @override
  State<ConfirmDialogScreen> createState() => _ConfirmDialogScreenState();
}

class _ConfirmDialogScreenState extends State<ConfirmDialogScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _ctrl.reverse();
    if (!mounted) return;
    RouteController.of(context).goBackward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Stack(
          children: [
            // Scrim — fades in with the dialog and dismisses on tap.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55 * t),
                ),
              ),
            ),
            // Centered card — fade + slight scale-in.
            Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * t,
                  child: GestureDetector(
                    // Absorb taps inside the card so they don't reach the
                    // scrim's onTap.
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360.0),
                      margin: const EdgeInsets.all(24.0),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24.0,
                            offset: const Offset(0.0, 8.0),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 48.0,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'Discard changes?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Your edits will be lost. This dialog is also a '
                            'route — it lives at /dialog on top of /home.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24.0),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _dismiss,
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                  onPressed: _dismiss,
                                  child: const Text('Discard'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// TOAST — top-anchored, auto-dismisses, doesn't block underlying input
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ToastScreen extends StatefulWidget with RouteWidgetMixin {
  @override
  final RouteState? routeState;
  const ToastScreen({super.key, this.routeState});

  @override
  State<ToastScreen> createState() => _ToastScreenState();
}

class _ToastScreenState extends State<ToastScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _autoDismiss;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.forward();
      _autoDismiss = Timer(const Duration(milliseconds: 2500), _dismiss);
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _autoDismiss?.cancel();
    await _ctrl.reverse();
    if (!mounted) return;
    RouteController.of(context).goBackward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        // The widget tree fills the route slot, but only the toast pill at
        // the top responds to hits — taps on the rest of the surface fall
        // through to the home page underneath.
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0.0, (1.0 - t) * -120.0),
              child: Opacity(
                opacity: t,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12.0,
                          offset: const Offset(0.0, 4.0),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Saved — tap to dismiss now',
                          style: TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
