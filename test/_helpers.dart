import 'package:df_router/df_router.dart';
import 'package:flutter/widgets.dart';

class TaggedScreen<TExtra extends Object?> extends StatefulWidget
    with RouteWidgetMixin<TExtra> {
  @override
  final RouteState<TExtra?>? routeState;
  final String tag;
  const TaggedScreen({super.key, required this.tag, this.routeState});

  @override
  State<TaggedScreen<TExtra>> createState() => TaggedScreenState<TExtra>();
}

class TaggedScreenState<TExtra extends Object?>
    extends State<TaggedScreen<TExtra>> {
  static final initCounts = <String, int>{};
  static final disposeCounts = <String, int>{};
  static final buildCounts = <String, int>{};

  static void resetCounts() {
    initCounts.clear();
    disposeCounts.clear();
    buildCounts.clear();
  }

  @override
  void initState() {
    super.initState();
    initCounts.update(widget.tag, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    disposeCounts.update(widget.tag, (n) => n + 1, ifAbsent: () => 1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buildCounts.update(widget.tag, (n) => n + 1, ifAbsent: () => 1);
    // Each tagged screen paints a unique color so we can identify what's
    // visible at the pixel level when needed.
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: Text(
          widget.tag,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}

Widget wrapRouter(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: child,
    ),
  );
}

RouteBuilder<TExtra> tagBuilder<TExtra extends Object?>(
  String tag,
  String path, {
  bool shouldPreserve = false,
  bool shouldPrebuild = false,
  bool isOverlay = false,
  AnimationEffect animationEffect = const NoEffect(),
}) {
  return RouteBuilder<TExtra>(
    routeState: RouteState<TExtra>(
      Uri.parse(path),
      animationEffect: animationEffect,
    ),
    shouldPreserve: shouldPreserve,
    shouldPrebuild: shouldPrebuild,
    isOverlay: isOverlay,
    builder: (context, state) => TaggedScreen<TExtra>(
      tag: tag,
      routeState: state,
    ),
  );
}
