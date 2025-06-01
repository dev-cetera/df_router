// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:collection'; // For LinkedHashSet

// // It's good practice to use foundation.listEquals if possible,
// // but the original code had a custom one inside RenderPrioritizedIndexedStack.
// // For this solution, I'll keep the custom listEquals as per the original structure.
// // If foundation.listEquals is preferred, the custom one can be removed and foundation.listEquals used instead.

// /// A [Stack] that shows a prioritized list of children from a main list.
// ///
// /// The children to be displayed are specified by the `indices` list.
// /// `indices[0]` corresponds to the child that will be rendered topmost.
// /// `indices[1]` will be rendered below `indices[0]`, and so on.
// ///
// /// If an index in the `indices` list is `null`, `-1`, or out of bounds for the
// /// main `children` list, no child is displayed for that priority layer.
// ///
// /// If the `indices` list is empty or all its values are invalid (null, -1, out of bounds),
// /// nothing will be displayed.
// ///
// /// The stack is always as big as the largest child in the main `children` list,
// /// similar to [IndexedStack].
// ///
// /// Changing the `indices` list dynamically updates which children are
// /// visible and their stacking order without rebuilding the child widgets themselves,
// /// preserving their state.
// ///
// /// An optional [indexedWrapperBuilder] can be provided to wrap active children
// /// with other widgets, allowing for transformations, opacity changes, animations, etc.,
// /// based on the child's original index and its current stacking order.
// ///
// /// Example:
// /// `PrioritizedIndexedStack(indices: [2, 0], children: [PageA, PageB, PageC])`
// /// This will render `PageC` (at index 2) on top, and `PageA` (at index 0) below `PageC`.
// /// `PageB` will not be rendered but will maintain its state.
// ///
// /// See also:
// ///
// ///  * [IndexedStack], for a stack that shows a single child.
// ///  * [Stack], for more details about stacks.
// class PrioritizedIndexedStack extends StatelessWidget {
//   /// Creates a [Stack] widget that paints a prioritized list of children.
//   const PrioritizedIndexedStack({
//     super.key,
//     this.alignment = AlignmentDirectional.topStart,
//     this.textDirection,
//     this.clipBehavior = Clip.hardEdge,
//     this.sizing = StackFit.loose,
//     this.indices = const <int?>[],
//     this.children = const <Widget>[],
//   });

//   /// How to align the non-positioned and partially-positioned children in the
//   /// stack.
//   /// Defaults to [AlignmentDirectional.topStart].
//   final AlignmentGeometry alignment;

//   /// The text direction with which to resolve [alignment].
//   /// Defaults to the ambient [Directionality].
//   final TextDirection? textDirection;

//   /// {@macro flutter.material.Material.clipBehavior}
//   /// Defaults to [Clip.hardEdge].
//   final Clip clipBehavior;

//   /// How to size the non-positioned children in the stack.
//   /// Defaults to [StackFit.loose]. This corresponds to [Stack.fit].
//   final StackFit sizing;

//   /// A list of indices specifying which children to display and their stacking order.
//   /// `indices[0]` is the topmost child.
//   /// Values of `null` or `-1` in this list are ignored for rendering.
//   final List<int?> indices;

//   /// The full list of child widgets.
//   /// Only those whose indices are present and valid in the `indices` list will be painted.
//   /// All children maintain their state.
//   final List<Widget> children;

//   @override
//   Widget build(BuildContext context) {
//     // Normalize -1 to null for internal processing.
//     final effectiveIndices = indices.map((index) => index == -1 ? null : index).toList();

//     // Precompute stacking orders for active children.
//     // The stackingOrder is the index in effectiveIndices (0 for topmost).
//     // If a child appears multiple times, its highest stacking order (first occurrence) is used.
//     final childOriginalIndexToStackingOrder = <int, int>{};
//     if (children.isNotEmpty) {
//       for (var order = 0; order < effectiveIndices.length; order++) {
//         final childIdx = effectiveIndices[order];
//         if (childIdx != null && childIdx >= 0 && childIdx < children.length) {
//           if (!childOriginalIndexToStackingOrder.containsKey(childIdx)) {
//             childOriginalIndexToStackingOrder[childIdx] = order;
//           }
//         }
//       }
//     }

//     final wrappedChildren = List<Widget>.generate(children.length, (int i) {
//       final stackingOrder = childOriginalIndexToStackingOrder[i];
//       final isActive = stackingOrder != null;

//       var childWidget = children[i];

//       // A child's RenderObject is made "active" for painting by RenderVisibility
//       // if its index 'i' is present in the valid effectiveIndices (isActive).
//       // This determines if RenderVisibility will paint its child.
//       // The actual stacking and selection is handled by RenderPrioritizedIndexedStack.
//       return Visibility.maintain(visible: isActive, child: childWidget);
//     });

//     return _RawPrioritizedIndexedStack(
//       alignment: alignment,
//       textDirection: textDirection,
//       clipBehavior: clipBehavior,
//       sizing: sizing,
//       indices: effectiveIndices, // Pass normalized (effective) indices
//       children: wrappedChildren,
//     );
//   }
// }

// /// The [RenderObjectWidget] that backs [PrioritizedIndexedStack].
// class _RawPrioritizedIndexedStack extends Stack {
//   const _RawPrioritizedIndexedStack({
//     super.alignment,
//     super.textDirection,
//     super.clipBehavior,
//     required StackFit sizing,
//     required this.indices,
//     super.children,
//   }) : super(fit: sizing);

//   final List<int?> indices;

//   @override
//   RenderPrioritizedIndexedStack createRenderObject(BuildContext context) {
//     assert(
//       _debugCheckHasDirectionality(
//         context,
//         alignment: alignment,
//         textDirection: textDirection,
//         why: () => 'to resolve $alignment for this PrioritizedIndexedStack widget',
//       ),
//     );

//     return RenderPrioritizedIndexedStack(
//       indices: indices,
//       alignment: alignment,
//       textDirection: textDirection ?? Directionality.maybeOf(context),
//       clipBehavior: clipBehavior,
//       fit: fit,
//     );
//   }

//   @override
//   void updateRenderObject(BuildContext context, RenderPrioritizedIndexedStack renderObject) {
//     assert(
//       _debugCheckHasDirectionality(
//         context,
//         alignment: alignment,
//         textDirection: textDirection,
//         why: () => 'to resolve $alignment for this PrioritizedIndexedStack widget',
//       ),
//     );
//     renderObject
//       ..indices = indices
//       ..alignment = alignment
//       ..textDirection = textDirection ?? Directionality.maybeOf(context)
//       ..clipBehavior = clipBehavior
//       ..fit = fit;
//   }

//   @override
//   MultiChildRenderObjectElement createElement() {
//     return _PrioritizedIndexedStackElement(this);
//   }
// }

// /// Custom [RenderObject] for [PrioritizedIndexedStack].
// class RenderPrioritizedIndexedStack extends RenderStack {
//   RenderPrioritizedIndexedStack({
//     required List<int?> indices,
//     super.children,
//     super.alignment,
//     super.textDirection,
//     super.fit,
//     super.clipBehavior,
//   }) : _indices = indices;

//   List<int?> _indices;
//   List<int?> get indices => _indices;
//   set indices(List<int?> value) {
//     if (listEquals(_indices, value)) return; // Using the custom listEquals from the class
//     _indices = value;
//     markNeedsPaint();
//     markNeedsSemanticsUpdate();
//   }

//   // Helper to check list equality (as provided in the original code)
//   // This is part of the RenderPrioritizedIndexedStack class.
//   bool listEquals<T>(List<T>? a, List<T>? b) {
//     if (a == null) return b == null;
//     if (b == null || a.length != b.length) return false;
//     for (var i = 0; i < a.length; i++) {
//       if (a[i] != b[i]) return false;
//     }
//     return true;
//   }

//   RenderBox? _getChildRenderBox(int? targetIndex) {
//     if (targetIndex == null || targetIndex < 0 || firstChild == null) {
//       return null;
//     }
//     var currentChild = firstChild;
//     var i = 0;
//     while (currentChild != null) {
//       if (i == targetIndex) {
//         return currentChild;
//       }
//       final childParentData = currentChild.parentData! as StackParentData;
//       currentChild = childParentData.nextSibling;
//       i++;
//     }
//     return null; // Index out of bounds
//   }

//   @override
//   void paint(PaintingContext context, Offset offset) {
//     if (firstChild == null || _indices.isEmpty) {
//       return;
//     }

//     for (var i = _indices.length - 1; i >= 0; i--) {
//       final childIndex = _indices[i];
//       if (childIndex != null) {
//         final childToPaint = _getChildRenderBox(childIndex);
//         if (childToPaint != null) {
//           final childParentData = childToPaint.parentData! as StackParentData;
//           context.paintChild(childToPaint, offset + childParentData.offset);
//         }
//       }
//     }
//   }

//   bool _hitTestChild(RenderBox child, BoxHitTestResult result, {required Offset position}) {
//     final childParentData = child.parentData! as StackParentData;
//     return result.addWithPaintOffset(
//       offset: childParentData.offset,
//       position: position,
//       hitTest: (BoxHitTestResult result, Offset transformedPosition) {
//         assert(child.parentData == childParentData);
//         return child.hitTest(result, position: transformedPosition);
//       },
//     );
//   }

//   @override
//   bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
//     if (firstChild == null || _indices.isEmpty) {
//       return false;
//     }

//     for (var i = 0; i < _indices.length; i++) {
//       final childIndex = _indices[i];
//       if (childIndex != null) {
//         final childToTest = _getChildRenderBox(childIndex);
//         if (childToTest != null) {
//           if (_hitTestChild(childToTest, result, position: position)) {
//             return true;
//           }
//         }
//       }
//     }
//     return false;
//   }

//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(DiagnosticsProperty<List<int?>>('indices (effective)', _indices));
//   }
// }

// /// Custom [Element] for [PrioritizedIndexedStack].
// class _PrioritizedIndexedStackElement extends MultiChildRenderObjectElement {
//   _PrioritizedIndexedStackElement(_RawPrioritizedIndexedStack super.widget);

//   @override
//   _RawPrioritizedIndexedStack get widget => super.widget as _RawPrioritizedIndexedStack;

//   @override
//   void debugVisitOnstageChildren(ElementVisitor visitor) {
//     if (children.isEmpty) {
//       return;
//     }
//     final effectiveIndices = widget.indices;
//     if (effectiveIndices.isEmpty) {
//       return;
//     }
//     // ignore: prefer_collection_literals
//     final visitedChildIndices = LinkedHashSet<int>();
//     for (final targetIndex in effectiveIndices) {
//       if (targetIndex != null && targetIndex >= 0 && targetIndex < children.length) {
//         if (visitedChildIndices.add(targetIndex)) {
//           visitor(children.elementAt(targetIndex));
//         }
//       }
//     }
//   }
// }

// // Helper function
// bool _debugCheckHasDirectionality(
//   BuildContext context, {
//   required AlignmentGeometry alignment,
//   required TextDirection? textDirection,
//   required String Function() why,
// }) {
//   if (textDirection == null && alignment is AlignmentDirectional) {
//     assert(Directionality.maybeOf(context) != null, why());
//   }
//   return true;
// }
