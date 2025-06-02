//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: omit_local_variable_types

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'dart:collection' show LinkedHashSet;
import 'package:flutter/foundation.dart' show listEquals;

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PrioritizedIndexedStack extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveIndices = indices
        .map((index) => index == -1 ? null : index)
        .toList();

    final childOriginalIndexToStackingOrder = <int, int>{};
    if (children.isNotEmpty) {
      for (var order = 0; order < effectiveIndices.length; order++) {
        final childIdx = effectiveIndices[order];
        if (childIdx != null && childIdx >= 0 && childIdx < children.length) {
          if (!childOriginalIndexToStackingOrder.containsKey(childIdx)) {
            childOriginalIndexToStackingOrder[childIdx] = order;
          }
        }
      }
    }

    final wrappedChildren = List<Widget>.generate(children.length, (int i) {
      final stackingOrder = childOriginalIndexToStackingOrder[i];
      final isActive = stackingOrder != null;
      var childWidget = children[i];
      return Visibility.maintain(visible: isActive, child: childWidget);
    });

    return _RawPrioritizedIndexedStack(
      alignment: alignment,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      sizing: sizing,
      indices: effectiveIndices,
      layerEffects: layerEffects,
      children: wrappedChildren,
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
  }) : _indices = indices,
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

  RenderBox? _getChildRenderBox(int? targetIndex) {
    if (targetIndex == null || targetIndex < 0 || firstChild == null) {
      return null;
    }
    var currentChild = firstChild;
    var i = 0;
    while (currentChild != null) {
      if (i == targetIndex) return currentChild;
      final childParentData = currentChild.parentData! as StackParentData;
      currentChild = childParentData.nextSibling;
      i++;
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null || _indices.isEmpty) {
      return;
    }

    // Iterate in reverse paint order (bottom-most visible child first, then layers on top)
    for (
      var stackingOrder = _indices.length - 1;
      stackingOrder >= 0;
      stackingOrder--
    ) {
      final childOriginalIndex = _indices[stackingOrder];
      if (childOriginalIndex == null) continue;

      final RenderBox? childToPaint = _getChildRenderBox(childOriginalIndex);
      if (childToPaint == null) continue;

      final StackParentData childParentData =
          childToPaint.parentData! as StackParentData;
      final AnimationLayerEffect? effectData =
          (_layerEffects != null && stackingOrder < _layerEffects!.length)
          ? _layerEffects![stackingOrder]
          : null;

      // This is the child's position as determined by the Stack layout, relative to the Stack's origin.
      final Offset childStackLayoutOffset = childParentData.offset;
      // This is the absolute offset where painting related to this child will start.
      final Offset absoluteChildPaintOrigin = offset + childStackLayoutOffset;

      // --- Layer for visual effects (opacity, colorFilter, imageFilter) ---
      bool needsSaveLayerForVisualEffects =
          (effectData?.opacity != null && effectData!.opacity! < 1.0) ||
          effectData?.colorFilter != null ||
          effectData?.imageFilter != null;
      Paint? visualEffectsPaint;

      if (needsSaveLayerForVisualEffects) {
        visualEffectsPaint = Paint();
        if (effectData!.opacity != null) {
          // Ensure opacity is applied correctly.
          // Multiplying alpha by 255 for the Paint's color.
          visualEffectsPaint.color = Color.fromRGBO(
            0,
            0,
            0,
            effectData.opacity!,
          );
        }
        if (effectData.colorFilter != null) {
          visualEffectsPaint.colorFilter = effectData.colorFilter;
        }
        if (effectData.imageFilter != null) {
          visualEffectsPaint.imageFilter = effectData.imageFilter;
        }
        // The saveLayer is established at the child's absolute position.
        // Subsequent drawing operations within this layer are relative to this position.
        context.canvas.saveLayer(
          absoluteChildPaintOrigin & childToPaint.size,
          visualEffectsPaint,
        );
      }

      // --- Apply transform using pushTransform ---
      final Matrix4? animationTransform = effectData?.transform;

      // The offset at which the child should be painted by the painter callback of pushTransform.
      // If we used saveLayer, we're already "at" the child's position, so paint at Offset.zero within the layer.
      // Otherwise, paint at the child's layout offset relative to the current context (which includes the stack's `offset`).
      final Offset offsetForPainter = needsSaveLayerForVisualEffects
          ? Offset.zero
          : absoluteChildPaintOrigin;

      if (animationTransform != null && !animationTransform.isIdentity()) {
        context.pushTransform(
          childToPaint
              .needsCompositing, // Crucial: hints to Flutter to use a TransformLayer if needed
          offsetForPainter, // The offset passed to the painter callback
          animationTransform, // The transformation matrix
          (PaintingContext paintingContext, Offset painterOffset) {
            // painterOffset will be the same as offsetForPainter.
            // The canvas is already transformed by animationTransform.
            // We paint the child at painterOffset within this transformed coordinate system.
            paintingContext.paintChild(childToPaint, painterOffset);
          },
        );
      } else {
        // No animationTransform or it's an identity matrix
        // Paint the child directly at the calculated offset.
        // If inside a saveLayer, this offset is Offset.zero (relative to layer's origin).
        // Otherwise, it's absoluteChildPaintOrigin.
        context.paintChild(childToPaint, offsetForPainter);
      }

      if (needsSaveLayerForVisualEffects) {
        context.canvas.restore(); // Restore from saveLayer
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null || _indices.isEmpty) {
      return false;
    }

    for (
      var stackingOrder = 0;
      stackingOrder < _indices.length;
      stackingOrder++
    ) {
      final childOriginalIndex = _indices[stackingOrder];
      if (childOriginalIndex == null) continue;

      final childToTest = _getChildRenderBox(childOriginalIndex);
      if (childToTest == null) continue;

      final AnimationLayerEffect? effectData = _layerEffects?[stackingOrder];

      // Check for ignorePointer or fully transparent
      if (effectData?.ignorePointer == true ||
          (effectData?.opacity != null && effectData!.opacity! <= 0.0)) {
        continue; // Skip hit testing for this child
      }

      final childParentData = childToTest.parentData! as StackParentData;
      final Offset childStackOffset =
          childParentData.offset; // Child's offset within the Stack
      final Matrix4? transform = effectData?.transform;

      bool hitted;
      if (transform != null) {
        hitted = result.addWithPaintTransform(
          transform: transform,

          position: position + childStackOffset,
          hitTest:
              (
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
  // ... (debugVisitOnstageChildren remains the same) ...
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
