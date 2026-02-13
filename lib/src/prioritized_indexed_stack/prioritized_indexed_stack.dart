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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Custom Stack that renders only specific children (by index) in a priority
// order, with per-layer visual effects (opacity, transform, filters).
// Unlike Flutter's IndexedStack (which shows one child), this shows N layers
// simultaneously — essential for cross-fade and slide transitions between
// two routes. The StatefulWidget layer caches wrapped children to avoid
// rebuilding Visibility.maintain wrappers when only layerEffects change
// (which happens every animation frame).
class PrioritizedIndexedStack extends StatefulWidget {
  const PrioritizedIndexedStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
    this.indices = const <int>[],
    this.children = const <Widget>[],
    this.layerEffects,
  });

  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final Clip clipBehavior;
  final StackFit sizing;
  final List<int> indices;
  final List<Widget> children;
  final List<AnimationLayerEffect>? layerEffects;

  @override
  State<PrioritizedIndexedStack> createState() =>
      _PrioritizedIndexedStackState();
}

class _PrioritizedIndexedStackState extends State<PrioritizedIndexedStack> {
  List<Widget> _wrappedChildren = const [];
  List<int?> _effectiveIndices = const [];

  @override
  void initState() {
    super.initState();
    _rebuildWrappedChildren();
  }

  @override
  void didUpdateWidget(PrioritizedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild the wrapped children when children or indices actually
    // change. During animation, only layerEffects changes — the children
    // and indices stay the same, so we skip the expensive wrapping.
    final childrenChanged = !_widgetListEquals(
      widget.children,
      oldWidget.children,
    );
    final indicesChanged = !listEquals(widget.indices, oldWidget.indices);
    if (childrenChanged || indicesChanged) {
      _rebuildWrappedChildren();
    }
  }

  void _rebuildWrappedChildren() {
    _effectiveIndices =
        widget.indices.map((index) => index == -1 ? null : index).toList();

    final activeSet = <int>{};
    for (final childIdx in _effectiveIndices) {
      if (childIdx != null &&
          childIdx >= 0 &&
          childIdx < widget.children.length) {
        activeSet.add(childIdx);
      }
    }

    _wrappedChildren = List<Widget>.generate(widget.children.length, (int i) {
      return Visibility.maintain(
        visible: activeSet.contains(i),
        child: widget.children[i],
      );
    });
  }

  /// Compares widget lists by identity (not deep equality) since cached
  /// widgets are the same object references when unchanged.
  static bool _widgetListEquals(List<Widget> a, List<Widget> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _RawPrioritizedIndexedStack(
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      clipBehavior: widget.clipBehavior,
      sizing: widget.sizing,
      indices: _effectiveIndices,
      layerEffects: widget.layerEffects,
      children: _wrappedChildren,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _RawPrioritizedIndexedStack extends Stack {
  const _RawPrioritizedIndexedStack({
    super.alignment,
    super.textDirection,
    super.clipBehavior,
    required StackFit sizing,
    required this.indices,
    this.layerEffects,
    super.children,
  }) : super(fit: sizing);

  final List<int?> indices;
  final List<AnimationLayerEffect>? layerEffects;

  @override
  RenderPrioritizedIndexedStack createRenderObject(BuildContext context) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () =>
            'to resolve $alignment for this PrioritizedIndexedStack widget',
      ),
    );
    return RenderPrioritizedIndexedStack(
      indices: indices,
      layerEffects: layerEffects,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
      fit: fit,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPrioritizedIndexedStack renderObject,
  ) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () =>
            'to resolve $alignment for this PrioritizedIndexedStack widget',
      ),
    );
    renderObject
      ..indices = indices
      ..layerEffects = layerEffects
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior
      ..fit = fit;
  }

  @override
  MultiChildRenderObjectElement createElement() {
    return _PrioritizedIndexedStackElement(this);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class RenderPrioritizedIndexedStack extends RenderStack {
  RenderPrioritizedIndexedStack({
    required List<int?> indices,
    List<AnimationLayerEffect>? layerEffects,
    super.children,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  })  : _indices = indices,
        _layerEffects = layerEffects;

  List<int?> _indices;
  List<int?> get indices => _indices;
  set indices(List<int?> value) {
    if (listEquals(_indices, value)) return;
    _indices = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  List<AnimationLayerEffect>? _layerEffects;
  List<AnimationLayerEffect>? get layerEffects => _layerEffects;
  set layerEffects(List<AnimationLayerEffect>? value) {
    if (listEquals(_layerEffects, value)) return;
    _layerEffects = value;
    markNeedsPaint();
  }

  /// Builds an indexed lookup table from the child linked list once per
  /// paint/hitTest pass, replacing the old O(n)-per-lookup traversal.
  List<RenderBox> _buildChildList() {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      final pd = child.parentData! as StackParentData;
      child = pd.nextSibling;
    }
    return list;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null || _indices.isEmpty) {
      return;
    }

    final childList = _buildChildList();

    for (var stackingOrder = _indices.length - 1;
        stackingOrder >= 0;
        stackingOrder--) {
      final childOriginalIndex = _indices[stackingOrder];
      if (childOriginalIndex == null ||
          childOriginalIndex < 0 ||
          childOriginalIndex >= childList.length) {
        continue;
      }

      final childToPaint = childList[childOriginalIndex];
      final childParentData = childToPaint.parentData! as StackParentData;
      final effectData =
          (_layerEffects != null && stackingOrder < _layerEffects!.length)
              ? _layerEffects![stackingOrder]
              : null;

      final childStackLayoutOffset = childParentData.offset;
      final absoluteChildPaintOrigin = offset + childStackLayoutOffset;

      final animationTransform = effectData?.transform;
      final currentOpacity = effectData?.opacity;
      final currentColorFilter = effectData?.colorFilter;
      final currentImageFilter = effectData?.imageFilter;

      final hasOpacity = currentOpacity != null && currentOpacity < 1.0;
      final hasColorFilter = currentColorFilter != null;
      final hasImageFilter = currentImageFilter != null;
      final hasOnlyOpacity = hasOpacity && !hasColorFilter && !hasImageFilter;
      final needsSaveLayer =
          (hasOpacity || hasColorFilter || hasImageFilter) && !hasOnlyOpacity;

      if (hasOnlyOpacity) {
        // Use pushOpacity for opacity-only effects. This leverages Flutter's
        // compositing layer system (OpacityLayer) which is GPU-accelerated
        // and avoids the expensive offscreen buffer that saveLayer requires.
        final alpha = (currentOpacity * 255.0).round().clamp(0, 255);
        context.pushOpacity(
          absoluteChildPaintOrigin,
          alpha,
          (PaintingContext opacityCtx, Offset opacityOff) {
            _paintChildWithTransform(
              opacityCtx,
              opacityOff,
              childToPaint,
              animationTransform,
            );
          },
        );
      } else if (needsSaveLayer) {
        // Full saveLayer needed when colorFilter or imageFilter is present.
        final paint = Paint();
        if (hasOpacity) {
          paint.color = Color.fromRGBO(0, 0, 0, currentOpacity);
        }
        if (hasColorFilter) {
          paint.colorFilter = currentColorFilter;
        }
        if (hasImageFilter) {
          paint.imageFilter = currentImageFilter;
        }
        context.canvas.saveLayer(
          absoluteChildPaintOrigin & childToPaint.size,
          paint,
        );
        _paintChildWithTransform(
          context,
          Offset.zero,
          childToPaint,
          animationTransform,
        );
        context.canvas.restore();
      } else {
        // No visual effects — paint directly.
        _paintChildWithTransform(
          context,
          absoluteChildPaintOrigin,
          childToPaint,
          animationTransform,
        );
      }
    }
  }

  void _paintChildWithTransform(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    Matrix4? transform,
  ) {
    if (transform != null && !transform.isIdentity()) {
      context.pushTransform(
        child.needsCompositing,
        offset,
        transform,
        (PaintingContext paintCtx, Offset paintOff) {
          paintCtx.paintChild(child, paintOff);
        },
      );
    } else {
      context.paintChild(child, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null || _indices.isEmpty) {
      return false;
    }

    final childList = _buildChildList();

    for (var stackingOrder = 0;
        stackingOrder < _indices.length;
        stackingOrder++) {
      final childOriginalIndex = _indices[stackingOrder];
      if (childOriginalIndex == null ||
          childOriginalIndex < 0 ||
          childOriginalIndex >= childList.length) {
        continue;
      }

      final childToTest = childList[childOriginalIndex];

      final effectData =
          (_layerEffects != null && stackingOrder < _layerEffects!.length)
              ? _layerEffects![stackingOrder]
              : null;

      final effectivelyIgnorePointer = effectData?.ignorePointer ?? false;
      final currentOpacity = effectData?.opacity;
      final currentTransform = effectData?.transform;

      final fullyTransparent = currentOpacity != null && currentOpacity <= 0.0;

      if (effectivelyIgnorePointer || fullyTransparent) {
        continue;
      }

      final childParentData = childToTest.parentData! as StackParentData;
      final childStackOffset = childParentData.offset;

      bool hitted;
      if (currentTransform != null && !currentTransform.isIdentity()) {
        hitted = result.addWithPaintTransform(
          transform: currentTransform,
          position: position - childStackOffset,
          hitTest: (
            BoxHitTestResult hitTestResult,
            Offset transformedLocalPosition,
          ) {
            return childToTest.hitTest(
              hitTestResult,
              position: transformedLocalPosition,
            );
          },
        );
      } else {
        hitted = result.addWithPaintOffset(
          offset: childStackOffset,
          position: position,
          hitTest: (BoxHitTestResult hitTestResult, Offset localPosition) {
            return childToTest.hitTest(hitTestResult, position: localPosition);
          },
        );
      }

      if (hitted) {
        return true;
      }
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<List<int?>>('indices (effective)', _indices),
    );
    properties.add(
      DiagnosticsProperty<List<AnimationLayerEffect>>(
        'layerEffects',
        _layerEffects,
        defaultValue: null,
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PrioritizedIndexedStackElement extends MultiChildRenderObjectElement {
  _PrioritizedIndexedStackElement(_RawPrioritizedIndexedStack super.widget);
  @override
  _RawPrioritizedIndexedStack get widget =>
      super.widget as _RawPrioritizedIndexedStack;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (children.isEmpty) {
      return;
    }
    final effectiveIndices = widget.indices;
    if (effectiveIndices.isEmpty) {
      return;
    }
    // ignore: prefer_collection_literals
    final visitedChildIndices = LinkedHashSet<int>();
    for (final targetIndex in effectiveIndices) {
      if (targetIndex != null &&
          targetIndex >= 0 &&
          targetIndex < children.length) {
        if (visitedChildIndices.add(targetIndex)) {
          visitor(children.elementAt(targetIndex));
        }
      }
    }
  }
}

bool _debugCheckHasDirectionality(
  BuildContext context, {
  required AlignmentGeometry alignment,
  required TextDirection? textDirection,
  required String Function() why,
}) {
  if (textDirection == null && alignment is AlignmentDirectional) {
    assert(Directionality.maybeOf(context) != null, why());
  }
  return true;
}
