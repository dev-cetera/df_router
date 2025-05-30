import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// For testing, you might need:
// import 'package:flutter/material.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef Picture = ui.Picture;

/// Captures a ui.Picture of the widget identified by the BuildContext synchronously.
///
/// IMPORTANT: For this function to reliably capture content, especially from
/// lazy-loading lists (like ListView.builder), the target widget MUST have been
/// scrolled into view and rendered by Flutter in a previous frame.
///
/// This method should be called on a BuildContext associated with a RepaintBoundary.
///
/// WARNING: This function accesses `RenderObject.layer`, a protected member, which may
/// change or break in future Flutter versions. It may return null or an incomplete
/// picture if the widget has not been fully painted yet.
///
/// The re-compositing logic for complex layer trees is a simplification and might not
/// capture all advanced effects or deeply nested non-transformed offsets perfectly.
Picture? captureWidgetPictureSync(BuildContext context) {
  if (!context.mounted) {
    debugPrint('[captureWidgetPictureSync] Context is not mounted at call time.');
    return null;
  }

  final renderObject = context.findRenderObject();

  if (renderObject == null) {
    debugPrint('[captureWidgetPictureSync] RenderObject is null.');
    return null;
  }

  if (renderObject is! RenderRepaintBoundary) {
    debugPrint(
      '[captureWidgetPictureSync] RenderObject is not a RenderRepaintBoundary. It is a ${renderObject.runtimeType}.',
    );
    return null;
  }

  final rrb = renderObject;

  // Check if the RepaintBoundary has a size and has been painted.
  // The layer check is crucial.
  if (!rrb.hasSize || rrb.debugNeedsLayout) {
    debugPrint(
      '[captureWidgetPictureSync] RenderRepaintBoundary not ready (no size or needs layout). Size: ${rrb.size}, NeedsLayout: ${rrb.debugNeedsLayout}',
    );
    // It's possible it has size but no layer if it's empty or just became visible.
  }

  // ignore: invalid_use_of_protected_member
  final Layer? rrbRootLayer = rrb.layer;

  if (rrbRootLayer == null && rrb.hasSize && rrb.size != Size.zero) {
    // It has a size, but no layer. This implies it hasn't been painted yet or is truly empty.
    // If it's supposed to have content, this is where things go wrong for lazy items.
    debugPrint(
      '[captureWidgetPictureSync] RenderRepaintBoundary has size ${rrb.size} but no layer. Has it been painted? Or is it genuinely empty?',
    );
    // Proceeding will result in a blank picture of these bounds.
  }

  final bounds = Offset.zero & rrb.size;
  // It's valid for a RepaintBoundary to have zero size.
  // If bounds are empty, the resulting picture will also be empty, which is correct.

  final pictureRecorder = ui.PictureRecorder();
  final canvas = ui.Canvas(pictureRecorder, bounds); // Use RRB's bounds for the new picture

  if (rrbRootLayer != null) {
    debugPrint(
      '[captureWidgetPictureSync] RRB root layer is ${rrbRootLayer.runtimeType}. Attempting to re-composite.',
    );
    // The root layer of the RepaintBoundary (often an OffsetLayer) is already at the correct
    // position relative to the RepaintBoundary's origin (0,0). So, we start compositing
    // it with an initial offset of Offset.zero onto our new canvas.
    _compositeLayerTreeToCanvas(canvas, rrbRootLayer, Offset.zero);
  } else {
    debugPrint(
      '[captureWidgetPictureSync] RRB has no root layer. Canvas will be empty (or background if one was set).',
    );
    // This means the RepaintBoundary was either empty or not painted.
    // The canvas created with `bounds` will result in an appropriately sized (possibly empty) picture.
  }

  return pictureRecorder.endRecording();
}

/// Recursively re-draws layers onto the provided canvas.
/// `canvas`: The canvas to draw onto.
/// `layer`: The current layer to process.
/// `parentAccumulatedOffset`: The offset of this layer's parent relative to the
///                            RepaintBoundary's origin. This is NOT the layer's own offset.
///                            For the initial root layer, this is Offset.zero.
void _compositeLayerTreeToCanvas(ui.Canvas canvas, Layer layer, Offset parentAccumulatedOffset) {
  canvas.save();

  var currentGlobalOffset = parentAccumulatedOffset;

  // Apply layer-specific effects and transformations.
  // The order of these checks can matter if layers inherit from each other.
  // Generally, check for more specific types before more general types if there's overlap.

  if (layer is OffsetLayer) {
    // OffsetLayer has an `offset` property. This offset is relative to its parent.
    // We need to translate the canvas by this amount.
    canvas.translate(layer.offset.dx, layer.offset.dy);
    currentGlobalOffset = currentGlobalOffset + layer.offset;
  }
  // Note: TransformLayer, OpacityLayer, etc., often extend OffsetLayer.
  // Their specific properties are applied *after* their intrinsic offset.

  if (layer is TransformLayer) {
    // If it's a TransformLayer, it might also be an OffsetLayer.
    // Its `offset` would have been handled by the `OffsetLayer` check if it came first.
    // Here we apply its specific `transform`.
    // The engine logic is roughly: apply offset, then apply transform.
    // If `OffsetLayer` was already handled, `layer.offset` is already part of the CTM.
    // If `TransformLayer` is handled *before* `OffsetLayer` (if it's a direct subclass, not via OffsetLayer),
    // then its own offset would need to be handled here too.
    // Given `TransformLayer extends OffsetLayer`, the OffsetLayer case handles its `offset`.
    // Now, apply its `transform` property.
    if (layer.transform != null) {
      canvas.transform(layer.transform!.storage);
    }
  } else if (layer is ClipRectLayer) {
    if (layer.clipRect != null) {
      canvas.clipRect(layer.clipRect!, doAntiAlias: layer.clipBehavior != Clip.hardEdge);
    }
  } else if (layer is ClipRRectLayer) {
    if (layer.clipRRect != null) {
      canvas.clipRRect(layer.clipRRect!, doAntiAlias: layer.clipBehavior != Clip.hardEdge);
    }
  } else if (layer is ClipPathLayer) {
    if (layer.clipPath != null) {
      canvas.clipPath(layer.clipPath!, doAntiAlias: layer.clipBehavior != Clip.hardEdge);
    }
  }
  // OpacityLayer extends OffsetLayer, so its offset is handled by the `is OffsetLayer` block.
  // Here, we handle the opacity itself.
  else if (layer is OpacityLayer) {
    final alpha = layer.alpha;
    if (alpha != null) {
      if (alpha == 0) {
        canvas.restore(); // Pop the save for this layer's state (including its offset)
        return; // Nothing more to draw for this layer or its children
      }
      if (alpha != 255) {
        // The bounds for saveLayer should be relative to the current canvas transform.
        // OpacityLayer.describeClipBounds() can be null.
        // If null, it applies to the current clip.
        var layerBounds = layer.describeClipBounds();
        // DescribeClipBounds are in parent coords. Canvas is already there.
        canvas.saveLayer(layerBounds, ui.Paint()..color = ui.Color.fromARGB(alpha, 0, 0, 0));
        // Children drawn into this temp layer, then opacity applied on restore.
      }
    }
  } else if (layer is ColorFilterLayer) {
    if (layer.colorFilter != null) {
      canvas.saveLayer(layer.describeClipBounds(), ui.Paint()..colorFilter = layer.colorFilter);
    }
  } else if (layer is ImageFilterLayer) {
    // ImageFilterLayer extends OffsetLayer. Its offset is handled.
    if (layer.imageFilter != null) {
      canvas.saveLayer(layer.describeClipBounds(), ui.Paint()..imageFilter = layer.imageFilter);
    }
  }
  // Add other specific layer types like ShaderMaskLayer if needed.

  // Draw content of this layer or recurse for its children.
  if (layer is PictureLayer) {
    // PictureLayer is painted at Offset.zero in its coordinate system.
    // Its position on canvas is determined by ancestor transforms/offsets.
    if (layer.picture != null) {
      canvas.drawPicture(layer.picture!);
    } else {
      debugPrint(
        '[_compositeLayerTreeToCanvas] PictureLayer has null picture. CanvasBounds: ${layer.canvasBounds}, Path: ${layer.debugCreatorPathToLayer}',
      );
    }
  } else if (layer is TextureLayer) {
    // TextureLayer has its own rect.
    // We cannot directly draw a texture to a ui.Picture. Draw a placeholder.
    debugPrint(
      '[_compositeLayerTreeToCanvas] Encountered TextureLayer (id: ${layer.textureId}). Cannot draw to ui.Picture. Drawing placeholder.',
    );
    final placeholderPaint =
        Paint()
          ..color = const Color(0xFFFF00FF).withValues(alpha: 0.5) // Bright pink placeholder
          ..style = PaintingStyle.fill;
    // TextureLayer.rect is in its parent's coordinate system.
    // Since we've already applied parent transforms (like OffsetLayer),
    // we draw rect directly.
    canvas.drawRect(layer.rect, placeholderPaint);
  } else if (layer is PlatformViewLayer) {
    debugPrint(
      '[_compositeLayerTreeToCanvas] Encountered PlatformViewLayer. Cannot draw platform views to ui.Picture. Skipping.',
    );
  }
  // ContainerLayer is the base for layers that have children.
  // OffsetLayer, Clip*, Opacity*, etc., are all ContainerLayers.
  else if (layer is ContainerLayer) {
    var child = layer.firstChild;
    while (child != null) {
      // The child's position is relative to this ContainerLayer.
      // If this ContainerLayer was an OffsetLayer, its offset was already applied to the canvas.
      // So, the child starts from the new origin of the canvas.
      // The `currentGlobalOffset` is the global position of *this* layer's origin.
      _compositeLayerTreeToCanvas(canvas, child, currentGlobalOffset);
      child = child.nextSibling;
    }
  } else if (layer is AnnotatedRegionLayer) {
    // AnnotatedRegionLayer is a ContainerLayer. It doesn't paint itself but its children.
    // This case might be hit if it's not caught by `is ContainerLayer` first,
    // but ContainerLayer should catch it. Handle children:
    var child = layer.firstChild;
    while (child != null) {
      _compositeLayerTreeToCanvas(canvas, child, currentGlobalOffset);
      child = child.nextSibling;
    }
  } else if (layer is LeaderLayer) {
    // LeaderLayer extends ContainerLayer
    // Its offset is handled by OffsetLayer case if it's also an OffsetLayer
    // (LeaderLayer does extend OffsetLayer via ContainerLayer -> OffsetLayer).
    // Then recurse for children.
    var child = layer.firstChild;
    while (child != null) {
      _compositeLayerTreeToCanvas(canvas, child, currentGlobalOffset); // Pass current global offset
      child = child.nextSibling;
    }
  } else if (layer is FollowerLayer) {
    // FollowerLayer extends ContainerLayer
    // FollowerLayer calculates its own transform based on its linked LeaderLayer.
    // This is complex to replicate perfectly without engine internals.
    // A simple approach is to draw its children at its current position.
    // Its `_lastTransform` is internal.
    // For a synchronous capture, we assume its current painted state is what we get.
    // It's also an OffsetLayer effectively, if its _lastTransform is applied.
    // This is a known difficult case for simple layer tree traversal.
    // We will effectively draw its children as if it's a regular ContainerLayer
    // at its last painted offset/transform.
    // The `canvas.save()` and `canvas.restore()` at the start/end of this function
    // handle the local transform scope. If `FollowerLayer` has a complex transform
    // not captured by `TransformLayer` type, it might not be perfect.
    var child = layer.firstChild;
    while (child != null) {
      _compositeLayerTreeToCanvas(canvas, child, currentGlobalOffset);
      child = child.nextSibling;
    }
  } else {
    debugPrint('[_compositeLayerTreeToCanvas] Unhandled layer type: ${layer.runtimeType}');
  }

  // Restore for layers that used saveLayer (e.g. Opacity, ColorFilter, ImageFilter)
  if ((layer is OpacityLayer && layer.alpha != null && layer.alpha != 0 && layer.alpha != 255) ||
      (layer is ColorFilterLayer && layer.colorFilter != null) ||
      (layer is ImageFilterLayer && layer.imageFilter != null)) {
    canvas.restore();
  }

  canvas.restore(); // Pop the save for this layer's transformations/clips
}

// Helper for debugging layer path
extension LayerDebugging on Layer {
  String get debugCreatorPathToLayer {
    final path = <String>[];
    Layer? current = this;
    while (current != null) {
      var layerDesc = current.runtimeType.toString();
      if (current.debugCreator != null) {
        // debugCreator is often a RenderObject.
        // We might want a shorter description of it.
        var creatorDesc = current.debugCreator.runtimeType.toString();
        if (current.debugCreator is RenderObject) {
          // This can be verbose
          //final ro = current.debugCreator as RenderObject;
          // creatorDesc = ro.toStringShort();
        }
        layerDesc += '(creator: $creatorDesc)';
      }
      path.add(layerDesc);
      current = current.parent;
    }
    return path.reversed.join(' -> ');
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PicturePainter extends CustomPainter {
  final Picture picture;
  final Size? expectedSize;

  PicturePainter(this.picture, {this.expectedSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (expectedSize != null &&
        expectedSize != Size.zero &&
        !expectedSize!.isEmpty &&
        size != Size.zero &&
        !size.isEmpty) {
      final scaleX = size.width / expectedSize!.width;
      final scaleY = size.height / expectedSize!.height;
      final scale = math.min(scaleX, scaleY);

      final scaledWidth = expectedSize!.width * scale;
      final scaledHeight = expectedSize!.height * scale;

      final dx = (size.width - scaledWidth) / 2;
      final dy = (size.height - scaledHeight) / 2;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.scale(scale, scale);
      canvas.drawPicture(picture);
      canvas.restore();
    } else {
      canvas.drawPicture(picture);
    }
  }

  @override
  bool shouldRepaint(covariant PicturePainter oldDelegate) =>
      oldDelegate.picture != picture || oldDelegate.expectedSize != expectedSize;
}

class PictureWidget extends StatelessWidget {
  final Picture? picture;
  final Size? size; // The original size of the picture when captured

  const PictureWidget({super.key, required this.picture, this.size});

  @override
  Widget build(BuildContext context) {
    if (picture == null) return const SizedBox.shrink();
    return CustomPaint(
      size:
          size ??
          Size.infinite, // Allow PicturePainter to determine size based on picture content if size is null
      painter: PicturePainter(picture!, expectedSize: size),
    );
  }
}
