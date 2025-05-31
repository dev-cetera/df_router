import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:collection'; // For LinkedHashSet

import 'package:flutter/foundation.dart' show listEquals; // For robust list comparison

class AnimatedStackWrapper extends StatefulWidget {
  // Parameters for the animation behavior
  final PISTransition transition;
  final Duration animationDuration;

  // Parameters to pass to the underlying PrioritizedIndexedStack
  final List<int?> indices;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final Clip clipBehavior;
  final StackFit sizing;

  const AnimatedStackWrapper({
    super.key,
    required this.transition,
    this.animationDuration = const Duration(milliseconds: 300),
    required this.indices,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
  });

  @override
  State<AnimatedStackWrapper> createState() => _AnimatedStackWrapperState();
}

class _AnimatedStackWrapperState extends State<AnimatedStackWrapper> with TickerProviderStateMixin {
  List<int?> _previousIndices = const [];

  @override
  void initState() {
    super.initState();
    widget.transition.initialize(vsync: this, duration: widget.animationDuration);
    // Initial call to onIndicesChanged when the widget is first built.
    // previousIndices is empty as there's no prior state.
    widget.transition.onIndicesChanged(
      previousIndices: const [],
      newIndices: widget.indices,
      childrenCount: widget.children.length,
    );
    _previousIndices = List.of(widget.indices); // Store initial indices
  }

  @override
  void didUpdateWidget(AnimatedStackWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool transitionChanged = widget.transition != oldWidget.transition;
    bool durationChanged = widget.animationDuration != oldWidget.animationDuration;

    if (transitionChanged || durationChanged) {
      oldWidget.transition.dispose(); // Dispose old transition
      widget.transition.initialize(vsync: this, duration: widget.animationDuration);
      // When transition or duration changes, treat it like a fresh start for index changes.
      // This will trigger onIndicesChanged with current indices against an "empty" previous.
      widget.transition.onIndicesChanged(
        previousIndices:
            const [], // Or _previousIndices if you want to animate from last known state
        newIndices: widget.indices,
        childrenCount: widget.children.length,
      );
    } else if (!listEquals(widget.indices, _previousIndices) ||
        widget.children.length != oldWidget.children.length) {
      // Only call onIndicesChanged if indices actually changed or children count changed
      widget.transition.onIndicesChanged(
        previousIndices: _previousIndices,
        newIndices: widget.indices,
        childrenCount: widget.children.length,
      );
    }
    _previousIndices = List.of(widget.indices); // Update stored previous indices
  }

  @override
  void dispose() {
    widget.transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder ensures that this part rebuilds whenever the transition's
    // animationListenable notifies (e.g., on every tick of an AnimationController).
    return AnimatedBuilder(
      animation: widget.transition.animationListenable,
      builder: (context, child) {
        return PrioritizedIndexedStack(
          // Pass down properties from the wrapper
          alignment: widget.alignment,
          textDirection: widget.textDirection,
          clipBehavior: widget.clipBehavior,
          sizing: widget.sizing,
          indices: widget.indices, // These are the current target indices
          children: widget.children,
          manipulatorApplier: (
            ctx,
            originalChildIndex,
            stackingOrder,
            isActiveInStack,
            controller,
          ) {
            // Query the PISTransition for the current transformation values
            final transformation = widget.transition.getTransformation(
              context: ctx,
              childOriginalIndex: originalChildIndex,
              newStackingOrder: stackingOrder,
              isActiveInNewStack: isActiveInStack,
            );
            controller.setProperties(
              opacity: transformation.opacity,
              transform: transformation.transform,
            );
          },
        );
      },
    );
  }
}

/// Data class to hold opacity and transform values for a child during transition.
class PISTransformation {
  final double opacity;
  final Matrix4 transform;

  const PISTransformation({this.opacity = 1.0, required this.transform});

  static PISTransformation identity = PISTransformation(transform: Matrix4.identity());
}

/// Abstract class defining the contract for a transition animation
/// to be used with AnimatedStackWrapper and PrioritizedIndexedStack.
abstract class PISTransition {
  /// The [Listenable] that drives the animation (typically an AnimationController).
  /// AnimatedStackWrapper will listen to this to rebuild.
  Listenable get animationListenable;

  /// Initializes the transition. Must be called before use.
  /// [vsync]: The TickerProvider.
  /// [duration]: The duration of the transition.
  void initialize({required TickerProvider vsync, required Duration duration});

  /// Called by AnimatedStackWrapper when the active indices in PrioritizedIndexedStack change.
  /// This method should decide if and how to start an animation.
  ///
  /// [previousIndices]: The list of `widget.children` indices that were active before the change.
  ///                    The first element is the topmost, second is below, etc.
  /// [newIndices]: The list of `widget.children` indices that are now active.
  ///               The first element is the new topmost, second is new below, etc.
  /// [childrenCount]: The total number of children available in the main `children` list.
  void onIndicesChanged({
    required List<int?> previousIndices,
    required List<int?> newIndices,
    required int childrenCount,
  });

  /// Retrieves the current transformation for a specific child.
  ///
  /// [context]: The BuildContext.
  /// [childOriginalIndex]: The index of the child in the main `children` list.
  /// [newStackingOrder]: The child's current stacking order in `newIndices` (0 for top, 1 for second, etc.).
  ///                     Null if the child is not active in `newIndices`.
  /// [isActiveInNewStack]: True if this child is present in `newIndices`.
  PISTransformation getTransformation({
    required BuildContext context,
    required int childOriginalIndex,
    required int? newStackingOrder,
    required bool isActiveInNewStack,
  });

  /// Disposes of any resources (like AnimationController).
  void dispose();
}

class PISTopLayerSlideTransition extends PISTransition {
  late AnimationController _controller;
  Animation<Offset>? _slideAnimationForTopLayer;

  // Store the original index of the page that IS the current/incoming top
  int? _currentTopOriginalIndex;
  // Store the original index of the page that IS stationary below the top
  int? _stationaryBelowTopOriginalIndex;

  bool _isTransitioning = false;

  @override
  Listenable get animationListenable => _controller;

  @override
  void initialize({required TickerProvider vsync, required Duration duration}) {
    _controller = AnimationController(vsync: vsync, duration: duration)..addStatusListener((
      status,
    ) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _isTransitioning = false;
        // After transition, the _currentTopOriginalIndex is the one fully visible.
        // The _stationaryBelowTopOriginalIndex might no longer be relevant if it's not in newIndices[1]
      }
    });
  }

  @override
  void onIndicesChanged({
    required List<int?> previousIndices,
    required List<int?> newIndices,
    required int childrenCount,
  }) {
    final oldTopOriginalIdx = previousIndices.isNotEmpty ? previousIndices[0] : null;
    final newTopOriginalIdx = newIndices.isNotEmpty ? newIndices[0] : null;
    final newSecondOriginalIdx = newIndices.length > 1 ? newIndices[1] : null;

    _currentTopOriginalIndex = newTopOriginalIdx;
    _stationaryBelowTopOriginalIndex = newSecondOriginalIdx; // This will be the stationary one

    // Only animate if the top element has actually changed and is valid
    if (newTopOriginalIdx != null && newTopOriginalIdx != oldTopOriginalIdx) {
      _isTransitioning = true;

      // For this transition, the new top always slides in from the right.
      // The element below it (newIndices[1]) does not move.
      final curve = Curves.easeInOutCubic;
      _slideAnimationForTopLayer = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: curve));

      _controller.forward(from: 0.0);
    } else {
      // Top element hasn't changed, or newTop is null.
      _isTransitioning = false;
      _controller.value = 1.0; // Ensure animation is at its completed state
      // If top didn't change but second did, we still update _stationaryBelowTopOriginalIndex
      if (newTopOriginalIdx == oldTopOriginalIdx) {
        _stationaryBelowTopOriginalIndex = newSecondOriginalIdx;
      }
    }
  }

  @override
  PISTransformation getTransformation({
    required BuildContext context,
    required int childOriginalIndex,
    required int? newStackingOrder, // current stacking order in PIS.indices
    required bool isActiveInNewStack, // is this child in PIS.indices at all
  }) {
    if (!isActiveInNewStack) {
      return PISTransformation(opacity: 0.0, transform: Matrix4.identity());
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Case 1: This child IS the current top AND is actively transitioning
    if (_isTransitioning &&
        childOriginalIndex == _currentTopOriginalIndex &&
        newStackingOrder == 0 &&
        _slideAnimationForTopLayer != null) {
      return PISTransformation(
        opacity: 1.0,
        transform: Matrix4.translationValues(
          _slideAnimationForTopLayer!.value.dx * screenWidth,
          0,
          0,
        ),
      );
    }
    // Case 2: This child IS the current top, BUT the transition is complete or wasn't for this top element
    else if (childOriginalIndex == _currentTopOriginalIndex && newStackingOrder == 0) {
      return PISTransformation.identity; // Show as is, no transform, full opacity
    }
    // Case 3: This child IS the one designated to be stationary below the top
    else if (childOriginalIndex == _stationaryBelowTopOriginalIndex && newStackingOrder == 1) {
      return PISTransformation.identity; // Stationary, full opacity
    }

    // Default: Any other active child (should not happen if indices is only 0 or 0,1)
    // or inactive children are made fully transparent.
    return PISTransformation(opacity: 0.0, transform: Matrix4.identity());
  }

  @override
  void dispose() {
    _controller.dispose();
  }
}

/// A PISTransition that applies no animation, showing the top item directly.
class PISNoTransition extends PISTransition {
  // A dummy notifier to satisfy the Listenable requirement, though it won't change.
  final ValueNotifier<double> _notifier = ValueNotifier(1.0);
  int? _currentTopIndex;

  @override
  Listenable get animationListenable => _notifier;

  @override
  void initialize({required TickerProvider vsync, required Duration duration}) {
    // No-op
  }

  @override
  void onIndicesChanged({
    required List<int?> previousIndices,
    required List<int?> newIndices,
    required int childrenCount,
  }) {
    _currentTopIndex = newIndices.isNotEmpty ? newIndices[0] : null;
    // Notify to ensure a rebuild if only indices changed without an actual animation starting
    // This is subtle: if PISNoTransition is used, onIndicesChanged might be the only signal
    // to update which child is fully visible if AnimatedBuilder doesn't run.
    // However, AnimatedStackWrapper rebuilds on index change anyway.
    // _notifier.value = _notifier.value; // Force notify (hacky, not ideal)
    // Better: AnimatedStackWrapper's didUpdateWidget handles this.
  }

  @override
  PISTransformation getTransformation({
    required BuildContext context,
    required int childOriginalIndex,
    required int? newStackingOrder,
    required bool isActiveInNewStack,
  }) {
    if (isActiveInNewStack && childOriginalIndex == _currentTopIndex && newStackingOrder == 0) {
      return PISTransformation.identity; // Show only the top item
    }
    return PISTransformation(opacity: 0.0, transform: Matrix4.identity());
  }

  @override
  void dispose() {
    _notifier.dispose();
  }
}

class ChildManipulatorController {
  double _opacity = 1.0;
  Matrix4 _transform = Matrix4.identity();
  // You could add more properties here like Alignment for Transform's alignment, etc.

  double get opacity => _opacity;
  Matrix4 get transform => _transform;

  /// Sets the visual properties for the child.
  /// This is called by the user within the `manipulatorApplier` callback.
  /// The widget tree must be rebuilt (e.g., via setState in the parent
  /// or AnimatedBuilder) for these changes to be picked up by ChildVisualProxy.
  void setProperties({double? opacity, Matrix4? transform}) {
    if (opacity != null) {
      _opacity = opacity;
    }
    if (transform != null) {
      _transform = transform;
    }
  }

  /// Resets properties to their default visual state.
  void resetProperties() {
    _opacity = 1.0;
    _transform = Matrix4.identity();
  }
}

class ChildVisualProxy extends StatelessWidget {
  final ChildManipulatorController controller;
  final Widget child; // This will be the KeyedSubtree(child: originalChildren[i])

  const ChildVisualProxy({
    super.key, // A key might be useful if PIS reorders these proxies, but it doesn't.
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Directly apply transformations from the controller.
    // No animation is done here; it reflects the current state of the controller.
    return Opacity(
      opacity: controller.opacity,
      child: Transform(
        transform: controller.transform,
        alignment: Alignment.center, // Or make this configurable via controller/PIS parameter
        child: child,
      ),
    );
  }
}

// Typedef ChildManipulatorApplier from previous correct example:
typedef ChildManipulatorApplier =
    void Function(
      BuildContext context,
      int childOriginalIndex,
      int? stackingOrder, // null if not active in stack
      bool isActiveInStack,
      ChildManipulatorController controller,
    );

class PrioritizedIndexedStack extends StatefulWidget {
  const PrioritizedIndexedStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.clipBehavior = Clip.hardEdge,
    this.sizing = StackFit.loose,
    this.indices = const <int?>[],
    this.children = const <Widget>[],
    this.manipulatorApplier, // User's callback to set controller values
  });

  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final Clip clipBehavior;
  final StackFit sizing;
  final List<int?> indices;
  final List<Widget> children;
  final ChildManipulatorApplier? manipulatorApplier;

  @override
  State<PrioritizedIndexedStack> createState() => _PrioritizedIndexedStackState();
}

class _PrioritizedIndexedStackState extends State<PrioritizedIndexedStack> {
  late List<ChildManipulatorController> _controllers;
  // _keyedOriginalChildren stores KeyedSubtree(key: ValueKey(i), child: widget.children[i])
  // to preserve the state of the original children.
  late List<Widget> _keyedOriginalChildren;

  @override
  void initState() {
    super.initState();
    _initializeControllersAndChildren();
  }

  void _initializeControllersAndChildren() {
    _controllers = List.generate(
      widget.children.length,
      (_) => ChildManipulatorController(),
      growable: false,
    );
    _keyedOriginalChildren = List.generate(
      widget.children.length,
      (i) => KeyedSubtree(
        key: ValueKey('pis_original_child_$i'), // Stable key for the original child's state
        child: widget.children[i],
      ),
      growable: false,
    );
  }

  @override
  void didUpdateWidget(PrioritizedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool childrenListLengthChanged = widget.children.length != oldWidget.children.length;

    if (childrenListLengthChanged) {
      // If the number of children changes, we need to rebuild controllers and keyed children.
      _initializeControllersAndChildren();
    } else {
      // If length is same, check if any child widget instance itself has changed.
      // If so, update the corresponding _keyedOriginalChildren entry.
      // The controllers remain the same as they are tied to the slot, not the instance.
      for (int i = 0; i < widget.children.length; i++) {
        if (widget.children[i] != oldWidget.children[i]) {
          _keyedOriginalChildren[i] = KeyedSubtree(
            key: ValueKey('pis_original_child_$i'), // Maintain the same key
            child: widget.children[i], // Pass the new widget instance
          );
        }
      }
    }
    // Note: The ChildManipulatorControllers are updated in the build method by the manipulatorApplier.
    // If the manipulatorApplier itself changes, or if external animation values driving it change,
    // a rebuild of this PIS widget will cause the new logic/values to be applied.
  }

  Map<int, int> _calculateStackingOrder(List<int?> effectiveIndices) {
    final Map<int, int> childOriginalIndexToStackingOrder = {};
    if (widget.children.isEmpty) {
      return childOriginalIndexToStackingOrder;
    }
    for (int order = 0; order < effectiveIndices.length; order++) {
      final int? childIdx = effectiveIndices[order];
      if (childIdx != null && childIdx >= 0 && childIdx < widget.children.length) {
        if (!childOriginalIndexToStackingOrder.containsKey(childIdx)) {
          childOriginalIndexToStackingOrder[childIdx] = order;
        }
      }
    }
    return childOriginalIndexToStackingOrder;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIndices = widget.indices.map((index) => index == -1 ? null : index).toList();
    final childOriginalIndexToStackingOrder = _calculateStackingOrder(effectiveIndices);

    // Apply manipulations via callback for all children.
    // The user's manipulatorApplier is responsible for setting the desired
    // opacity/transform on the controller based on its logic (static, animated, etc.).
    if (widget.manipulatorApplier != null) {
      if (_controllers.length == widget.children.length) {
        // Safety check
        for (int i = 0; i < widget.children.length; i++) {
          final bool isActiveInStack = effectiveIndices.any((idx) => idx == i);
          final int? stackingOrder = isActiveInStack ? childOriginalIndexToStackingOrder[i] : null;

          // Call the applier for every child. It will update the controller.
          widget.manipulatorApplier!(context, i, stackingOrder, isActiveInStack, _controllers[i]);
        }
      }
    } else {
      // If no applier is provided, ensure all controllers are reset to default.
      if (_controllers.length == widget.children.length) {
        // Safety check
        for (final controller in _controllers) {
          controller.resetProperties();
        }
      }
    }

    final List<Widget> processedChildren = List.generate(widget.children.length, (int i) {
      // Determine if this child's RenderObject should be painted.
      final bool isActuallyPainted = effectiveIndices.any((idx) => idx != null && idx == i);

      return Visibility.maintain(
        // key: ValueKey('pis_visibility_$i'), // Generally not needed
        visible: isActuallyPainted,
        child: ChildVisualProxy(
          // key: ValueKey('pis_proxy_$i'), // Generally not needed
          controller: _controllers[i],
          child: _keyedOriginalChildren[i], // The KeyedSubtree-wrapped original child
        ),
      );
    }, growable: false);

    return _RawPrioritizedIndexedStack(
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      clipBehavior: widget.clipBehavior,
      sizing: widget.sizing,
      indices: effectiveIndices,
      children: processedChildren, // List<Visibility.maintain(child: ChildVisualProxy(...))>
    );
  }
}

// The _RawPrioritizedIndexedStack, RenderPrioritizedIndexedStack, _PrioritizedIndexedStackElement,
// and _debugCheckHasDirectionality helper remain UNCHANGED from your original code.
// They operate on the 'children' list they receive, which will now be the
// List<Visibility.maintain(child: ChildVisualProxy(...))>

// It's good practice to use foundation.listEquals if possible,
// but the original code had a custom one inside RenderPrioritizedIndexedStack.
// For this solution, I'll keep the custom listEquals as per the original structure.
// If foundation.listEquals is preferred, the custom one can be removed and foundation.listEquals used instead.

/// A callback that allows wrapping an active child widget in [PrioritizedIndexedStack].
///
/// - [context]: The build context.
/// - [childOriginalIndex]: The index of the child in the main `children` list.
/// - [stackingOrder]: The order of the child in the current stack (0 for topmost, 1 for next, etc.).
///   This is based on the child's first appearance in the `indices` list.
/// - [child]: The child widget to be wrapped.
///
/// Returns a [Widget] that typically wraps the provided [child].
typedef IndexedWidgetWrapperBuilder =
    Widget Function(BuildContext context, int childOriginalIndex, int stackingOrder, Widget child);

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
    if (listEquals(_indices, value)) return; // Using the custom listEquals from the class
    _indices = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  // Helper to check list equality (as provided in the original code)
  // This is part of the RenderPrioritizedIndexedStack class.
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

    for (var i = _indices.length - 1; i >= 0; i--) {
      final childIndex = _indices[i];
      if (childIndex != null) {
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
        assert(child.parentData == childParentData);
        return child.hitTest(result, position: transformedPosition);
      },
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null || _indices.isEmpty) {
      return false;
    }

    for (var i = 0; i < _indices.length; i++) {
      final childIndex = _indices[i];
      if (childIndex != null) {
        final childToTest = _getChildRenderBox(childIndex);
        if (childToTest != null) {
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
      return;
    }
    final effectiveIndices = widget.indices;
    if (effectiveIndices.isEmpty) {
      return;
    }
    // ignore: prefer_collection_literals
    final visitedChildIndices = LinkedHashSet<int>();
    for (final targetIndex in effectiveIndices) {
      if (targetIndex != null && targetIndex >= 0 && targetIndex < children.length) {
        if (visitedChildIndices.add(targetIndex)) {
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
