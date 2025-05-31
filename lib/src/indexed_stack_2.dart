import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [Stack] that shows up to two children from a list of children, identified by
/// [index1] and [index2].
///
/// The child at [index1] is rendered on top of the child at [index2].
/// If [index1] and [index2] are the same (and valid, non-null, not -1),
/// that child is rendered once.
/// If an index is null, -1, or out of bounds, the corresponding child is not displayed.
///
/// The stack is always as big as the largest child in the `children` list,
/// similar to [IndexedStack].
///
/// Changing [index1] or [index2] dynamically updates which children are
/// visible without rebuilding the child widgets themselves, preserving their state.
///
/// At least one of [index1] or [index2] must be non-null. To display nothing,
/// you can set both to -1 (or null, if one was already non-null to pass the assert).
/// For example: `IndexedStack2(index1: -1, index2: -1, children: ...)` is valid if
/// you want to explicitly show nothing but satisfy the constructor requirement.
/// A more common scenario would be `IndexedStack2(index1: 0, index2: -1, children: ...)`.
///
/// See also:
///
///  * [IndexedStack], for a stack that shows a single child.
///  * [Stack], for more details about stacks.
class IndexedStack2 extends StatelessWidget {
  /// Creates a [Stack] widget that paints up to two children from a list.
  ///
  /// Requires at least one of [index1] or [index2] to be non-null.
  /// An index value of -1 is treated as null (meaning the child is not shown).
  const IndexedStack2({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
    this.index1,
    this.index2,
    this.children = const <Widget>[],
  }) : assert(
         index1 != null || index2 != null,
         'At least one of index1 or index2 must be specified for IndexedStack2.',
       );

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See [Stack.alignment] for more information.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// How to size the non-positioned children in the stack.
  ///
  /// Defaults to [StackFit.loose]. This corresponds to [Stack.fit].
  ///
  /// See [StackFit] for more information.
  final StackFit sizing;

  /// The index of the child to show on top.
  ///
  /// If this is null, -1, or out of bounds, this child will not be shown.
  final int? index1;

  /// The index of the child to show below [index1].
  ///
  /// If this is null, -1, or out of bounds, this child will not be shown.
  final int? index2;

  /// The child widgets of the stack.
  ///
  /// Only the children at [index1] and [index2] (if valid) will be painted.
  /// All children maintain their state.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Normalize -1 to null for internal processing.
    // This ensures that subsequent logic only needs to handle null for "not visible".
    final effectiveIndex1 = (index1 == -1) ? null : index1;
    final effectiveIndex2 = (index2 == -1) ? null : index2;

    final wrappedChildren = List<Widget>.generate(children.length, (int i) {
      // A child is considered "active" for rendering if its index 'i' matches
      // a valid effectiveIndex1 or effectiveIndex2.
      // An effective index is valid if it's non-null.
      // Bounds checking for effectiveIndex1/2 against children.length
      // is implicitly handled by _getChildRenderBox later.
      final isActive =
          (effectiveIndex1 != null && i == effectiveIndex1) ||
          (effectiveIndex2 != null && i == effectiveIndex2);

      return Visibility.maintain(
        visible: isActive, // Controls whether RenderVisibility paints its child.
        child: children[i],
      );
    });

    return _RawIndexedStack2(
      alignment: alignment,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      sizing: sizing, // Passed as 'fit' to the underlying Stack
      index1: effectiveIndex1, // Pass normalized (effective) index
      index2: effectiveIndex2, // Pass normalized (effective) index
      children: wrappedChildren,
    );
  }
}

/// The [RenderObjectWidget] that backs [IndexedStack2].
///
/// This widget is responsible for creating and updating the [RenderIndexedStack2].
/// It receives normalized indices (where -1 has been converted to null).
class _RawIndexedStack2 extends Stack {
  const _RawIndexedStack2({
    // key is implicitly handled by Stack
    super.alignment,
    super.textDirection,
    super.clipBehavior,
    required StackFit sizing, // Mapped from IndexedStack2.sizing
    this.index1, // This will be the effectiveIndex1 (null if original was -1 or null)
    this.index2, // This will be the effectiveIndex2 (null if original was -1 or null)
    super.children,
  }) : super(fit: sizing); // Pass 'sizing' as 'fit' to Stack

  final int? index1;
  final int? index2;

  @override
  RenderIndexedStack2 createRenderObject(BuildContext context) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () => 'to resolve $alignment for this IndexedStack2 widget',
      ),
    );

    return RenderIndexedStack2(
      index1: index1, // Pass the already normalized index
      index2: index2, // Pass the already normalized index
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
      fit: fit, // 'fit' is the StackFit property of RenderStack
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderIndexedStack2 renderObject) {
    assert(
      _debugCheckHasDirectionality(
        context,
        alignment: alignment,
        textDirection: textDirection,
        why: () => 'to resolve $alignment for this IndexedStack2 widget',
      ),
    );
    renderObject
      ..index1 =
          index1 // Update with the already normalized index
      ..index2 =
          index2 // Update with the already normalized index
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior
      ..fit = fit;
  }

  @override
  MultiChildRenderObjectElement createElement() {
    return _IndexedStack2Element(this);
  }
}

/// Custom [RenderObject] for [IndexedStack2].
///
/// Extends [RenderStack] and overrides painting and hit-testing logic
/// to only consider children at `index1` and `index2`.
/// The `_index1` and `_index2` fields here are the effective indices
/// (null if originally null or -1).
class RenderIndexedStack2 extends RenderStack {
  RenderIndexedStack2({
    int? index1,
    int? index2,
    super.children,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  }) : _index1 = index1,
       _index2 = index2;

  int? _index1;
  int? get index1 => _index1;
  set index1(int? value) {
    if (_index1 == value) return;
    _index1 = value; // value is already normalized (null for -1)
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  int? _index2;
  int? get index2 => _index2;
  set index2(int? value) {
    if (_index2 == value) return;
    _index2 = value; // value is already normalized (null for -1)
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// Gets the RenderBox for the child at the given targetIndex.
  /// Returns null if targetIndex is null, negative, or out of bounds.
  RenderBox? _getChildRenderBox(int? targetIndex) {
    // Handles targetIndex == null and targetIndex < 0 (which covers original -1 cases
    // if they weren't normalized, though they should be by this point).
    if (targetIndex == null || targetIndex < 0 || firstChild == null) {
      return null;
    }
    var currentChild = firstChild;
    var i = 0;
    while (currentChild != null) {
      if (i == targetIndex) {
        return currentChild; // This is the RenderVisibility object
      }
      final childParentData = currentChild.parentData! as StackParentData;
      currentChild = childParentData.nextSibling;
      i++;
    }
    return null; // Index out of bounds
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) {
      return;
    }

    // _index1 and _index2 are already effective indices (null if not to be shown)
    final childForIndex2 = _getChildRenderBox(_index2);
    final childForIndex1 = _getChildRenderBox(_index1);

    // If indices are the same (and valid), childForIndex1 and childForIndex2
    // will point to the same RenderBox.
    if (_index1 != null && _index1 == _index2) {
      // Only paint once if indices are the same and valid (non-null)
      if (childForIndex1 != null) {
        final childParentData = childForIndex1.parentData! as StackParentData;
        context.paintChild(childForIndex1, offset + childParentData.offset);
      }
    } else {
      // Paint child at index2 (bottom layer) if it's valid
      if (childForIndex2 != null) {
        final childParentData = childForIndex2.parentData! as StackParentData;
        context.paintChild(childForIndex2, offset + childParentData.offset);
      }
      // Paint child at index1 (top layer) if it's valid
      if (childForIndex1 != null) {
        final childParentData = childForIndex1.parentData! as StackParentData;
        context.paintChild(childForIndex1, offset + childParentData.offset);
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
    if (firstChild == null) {
      return false;
    }

    // _index1 and _index2 are already effective indices
    final childForIndex1 = _getChildRenderBox(_index1);
    final childForIndex2 = _getChildRenderBox(_index2);

    if (_index1 != null && _index1 == _index2) {
      // If indices are the same and valid, hit test only once.
      if (childForIndex1 != null) {
        return _hitTestChild(childForIndex1, result, position: position);
      }
    } else {
      // Hit test top-most child (index1) first, if valid.
      if (childForIndex1 != null) {
        if (_hitTestChild(childForIndex1, result, position: position)) {
          return true;
        }
      }
      // Then hit test child below (index2), if valid.
      if (childForIndex2 != null) {
        if (_hitTestChild(childForIndex2, result, position: position)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('index1 (effective)', _index1));
    properties.add(IntProperty('index2 (effective)', _index2));
  }
}

/// Custom [Element] for [IndexedStack2].
///
/// This element is responsible for managing the lifecycle of the [RenderIndexedStack2]
/// and correctly reporting which children are "onstage" for debugging and accessibility.
class _IndexedStack2Element extends MultiChildRenderObjectElement {
  _IndexedStack2Element(_RawIndexedStack2 super.widget);

  @override
  _RawIndexedStack2 get widget => super.widget as _RawIndexedStack2;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (children.isEmpty) {
      // 'children' here are the child Elements
      return;
    }

    // widget.index1 and widget.index2 are the effective indices (null if not shown)
    final i1 = widget.index1;
    final i2 = widget.index2;

    // Visit child for index1 if it's a valid, non-null, and in-bounds index
    if (i1 != null && i1 >= 0 && i1 < children.length) {
      visitor(children.elementAt(i1));
    }

    // Visit child for index2 if it's a valid, non-null, in-bounds index,
    // AND different from index1 (to avoid double visit if indices were same).
    if (i2 != null && i2 >= 0 && i2 < children.length && i1 != i2) {
      visitor(children.elementAt(i2));
    }
  }
}

// Helper function from Flutter's `basic.dart` (widgets/basic.dart)
// Used to assert that Directionality is available if alignment is directional.
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
