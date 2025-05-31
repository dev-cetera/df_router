import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:collection'; // For LinkedHashSet

/// A [Stack] that shows a prioritized list of children from a main list.
///
/// The children to be displayed are specified by the `indices` list.
/// `indices[0]` corresponds to the child that will be rendered topmost.
/// `indices[1]` will be rendered below `indices[0]`, and so on.
///
/// If an index in the `indices` list is `null`, `-1`, or out of bounds for the
/// main `children` list, no child is displayed for that priority layer.
///
/// If the `indices` list is empty or all its values are invalid (null, -1, out of bounds),
/// nothing will be displayed.
///
/// The stack is always as big as the largest child in the main `children` list,
/// similar to [IndexedStack].
///
/// Changing the `indices` list dynamically updates which children are
/// visible and their stacking order without rebuilding the child widgets themselves,
/// preserving their state.
///
/// Example:
/// `PrioritizedIndexedStack(indices: [2, 0], children: [PageA, PageB, PageC])`
/// This will render `PageC` (at index 2) on top, and `PageA` (at index 0) below `PageC`.
/// `PageB` will not be rendered but will maintain its state.
///
/// See also:
///
///  * [IndexedStack], for a stack that shows a single child.
///  * [Stack], for more details about stacks.
class PrioritizedIndexedStack extends StatelessWidget {
  /// Creates a [Stack] widget that paints a prioritized list of children.
  const PrioritizedIndexedStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
    this.indices = const <int?>[],
    this.children = const <Widget>[],
  });

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  /// Defaults to [AlignmentDirectional.topStart].
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// How to size the non-positioned children in the stack.
  /// Defaults to [StackFit.loose]. This corresponds to [Stack.fit].
  final StackFit sizing;

  /// A list of indices specifying which children to display and their stacking order.
  /// `indices[0]` is the topmost child.
  /// Values of `null` or `-1` in this list are ignored for rendering.
  final List<int?> indices;

  /// The full list of child widgets.
  /// Only those whose indices are present and valid in the `indices` list will be painted.
  /// All children maintain their state.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Normalize -1 to null for internal processing.
    final effectiveIndices = indices.map((index) => index == -1 ? null : index).toList();

    final wrappedChildren = List<Widget>.generate(children.length, (int i) {
      // A child's RenderObject is made "active" for painting by RenderVisibility
      // if its index 'i' is present in the valid effectiveIndices.
      // This determines if RenderVisibility will paint its child.
      // The actual stacking and selection is handled by RenderPrioritizedIndexedStack.
      final isActive = effectiveIndices.any((idx) => idx != null && idx == i);

      return Visibility.maintain(visible: isActive, child: children[i]);
    });

    return _RawPrioritizedIndexedStack(
      alignment: alignment,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      sizing: sizing,
      indices: effectiveIndices, // Pass normalized (effective) indices
      children: wrappedChildren,
    );
  }
}

/// The [RenderObjectWidget] that backs [PrioritizedIndexedStack].
class _RawPrioritizedIndexedStack extends Stack {
  const _RawPrioritizedIndexedStack({
    super.alignment,
    super.textDirection,
    super.clipBehavior,
    required StackFit sizing,
    required this.indices, // These are the effectiveIndices
    super.children,
  }) : super(fit: sizing);

  final List<int?> indices;

  @override
  RenderPrioritizedIndexedStack createRenderObject(BuildContext context) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () => 'to resolve $alignment for this PrioritizedIndexedStack widget',
      ),
    );

    return RenderPrioritizedIndexedStack(
      indices: indices,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
      fit: fit,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPrioritizedIndexedStack renderObject) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () => 'to resolve $alignment for this PrioritizedIndexedStack widget',
      ),
    );
    renderObject
      ..indices = indices
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

/// Custom [RenderObject] for [PrioritizedIndexedStack].
class RenderPrioritizedIndexedStack extends RenderStack {
  RenderPrioritizedIndexedStack({
    required List<int?> indices,
    super.children,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  }) : _indices = indices;

  List<int?> _indices;
  List<int?> get indices => _indices;
  set indices(List<int?> value) {
    if (listEquals(_indices, value)) return;
    _indices = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  // Helper to check list equality
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  RenderBox? _getChildRenderBox(int? targetIndex) {
    if (targetIndex == null || targetIndex < 0 || firstChild == null) {
      return null;
    }
    var currentChild = firstChild;
    var i = 0;
    while (currentChild != null) {
      if (i == targetIndex) {
        // This currentChild is the RenderVisibility RenderBox.
        // Its 'visible' property (managed by Visibility.maintain) determines
        // if it actually paints its own child.
        return currentChild;
      }
      final childParentData = currentChild.parentData! as StackParentData;
      currentChild = childParentData.nextSibling;
      i++;
    }
    return null; // Index out of bounds
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null || _indices.isEmpty) {
      return;
    }

    // Paint from bottom-most to top-most.
    // Iterate _indices from last to first.
    for (var i = _indices.length - 1; i >= 0; i--) {
      final childIndex = _indices[i];
      if (childIndex != null) {
        // childIndex is already normalized (null for original -1 or null)
        final childToPaint = _getChildRenderBox(childIndex);
        if (childToPaint != null) {
          final childParentData = childToPaint.parentData! as StackParentData;
          context.paintChild(childToPaint, offset + childParentData.offset);
        }
      }
    }
  }

  bool _hitTestChild(RenderBox child, BoxHitTestResult result, {required Offset position}) {
    final childParentData = child.parentData! as StackParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformedPosition) {
        return child.hitTest(result, position: transformedPosition);
      },
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null || _indices.isEmpty) {
      return false;
    }

    // Hit test from top-most to bottom-most.
    // Iterate _indices from first to last.
    for (var i = 0; i < _indices.length; i++) {
      final childIndex = _indices[i];
      if (childIndex != null) {
        // childIndex is already normalized
        final childToTest = _getChildRenderBox(childIndex);
        if (childToTest != null) {
          // Check if the RenderVisibility child itself is visible.
          // This check is implicitly handled because if RenderVisibility.visible is false,
          // it won't paint its child, and its hitTestSelf or hitTestChildren might return false
          // or not include its actual content. The _hitTestChild call will correctly
          // delegate to the RenderVisibility's hitTest.
          if (_hitTestChild(childToTest, result, position: position)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<List<int?>>('indices (effective)', _indices));
  }
}

/// Custom [Element] for [PrioritizedIndexedStack].
class _PrioritizedIndexedStackElement extends MultiChildRenderObjectElement {
  _PrioritizedIndexedStackElement(_RawPrioritizedIndexedStack super.widget);

  @override
  _RawPrioritizedIndexedStack get widget => super.widget as _RawPrioritizedIndexedStack;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (children.isEmpty) {
      // 'children' here are the child Elements of _RawPrioritizedIndexedStack
      return;
    }

    // widget.indices are the effective indices (null if not shown for that layer)
    final effectiveIndices = widget.indices;
    if (effectiveIndices.isEmpty) {
      return;
    }

    // Use a set to visit each unique child element only once,
    // even if its index appears multiple times in effectiveIndices.
    // The order of visitation doesn't strictly matter for debugVisitOnstageChildren,
    // but visiting in stack order (top-first) is reasonable.
    // ignore: prefer_collection_literals
    final visitedChildIndices = LinkedHashSet<int>();

    for (final targetIndex in effectiveIndices) {
      if (targetIndex != null && targetIndex >= 0 && targetIndex < children.length) {
        if (visitedChildIndices.add(targetIndex)) {
          // Add returns true if element was not already in set
          visitor(children.elementAt(targetIndex));
        }
      }
    }
  }
}

// Helper function
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
