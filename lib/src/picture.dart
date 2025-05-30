import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// For testing, you might need:
// import 'package:flutter/material.dart'; // Example: for Color

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
  try {
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

    // --- kDebugMode guarded section for robust release mode operation ---
    bool logAsPotentiallyNotReady = !rrb.hasSize;
    String layoutDebugInfoForLog = '';

    if (kDebugMode) {
      // Only in debug mode, check debugNeedsLayout if rrb has size
      if (rrb.hasSize) {
        // Only check layout if it has size
        if (rrb.debugNeedsLayout) {
          logAsPotentiallyNotReady = true; // Mark for logging that it might not be ideal
          layoutDebugInfoForLog = ', NeedsLayout: true (debug check)';
        } else {
          layoutDebugInfoForLog = ', NeedsLayout: false (debug check)';
        }
      }
      // If !rrb.hasSize, logAsPotentiallyNotReady is already true, no need to check layout.
    }
    // In release mode, logAsPotentiallyNotReady is solely based on !rrb.hasSize,
    // and layoutDebugInfoForLog remains empty. No access to rrb.debugNeedsLayout occurs.

    if (logAsPotentiallyNotReady) {
      // This debugPrint is primarily for debugging. In release, layoutDebugInfoForLog will be empty.
      debugPrint(
        '[captureWidgetPictureSync] RenderRepaintBoundary status check: Size: ${rrb.size}$layoutDebugInfoForLog. Proceeding with capture.',
      );
    }
    // --- End of kDebugMode guarded section ---

    // ignore: invalid_use_of_protected_member
    final Layer? rrbRootLayer = rrb.layer;

    if (rrbRootLayer == null && rrb.hasSize && rrb.size != Size.zero) {
      debugPrint(
        '[captureWidgetPictureSync] RenderRepaintBoundary has size ${rrb.size} but no layer. Has it been painted as empty? Or is it genuinely empty?',
      );
    }

    final bounds = Offset.zero & rrb.size;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder, bounds);

    if (rrbRootLayer != null) {
      _compositeLayerTreeToCanvas(canvas, rrbRootLayer, Offset.zero);
    } else {
      debugPrint(
        '[captureWidgetPictureSync] RRB has no root layer (or size is zero). Canvas will reflect this (e.g., empty picture).',
      );
    }

    return pictureRecorder.endRecording();
  } catch (e, stackTrace) {
    debugPrint('[captureWidgetPictureSync] Error capturing widget picture: $e\n$stackTrace');
    return null;
  }
}

// ... (Rest of your _compositeLayerTreeToCanvas, LayerDebugging, PicturePainter, PictureWidget code remains the same) ...

/// Recursively re-draws layers onto the provided canvas.
void _compositeLayerTreeToCanvas(ui.Canvas canvas, Layer layer, Offset parentAccumulatedOffset) {
  canvas.save();
  var currentGlobalOffset = parentAccumulatedOffset;

  if (layer is OffsetLayer) {
    canvas.translate(layer.offset.dx, layer.offset.dy);
    currentGlobalOffset = currentGlobalOffset + layer.offset;
  }

  if (layer is TransformLayer) {
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
  } else if (layer is OpacityLayer) {
    final alpha = layer.alpha;
    if (alpha != null) {
      if (alpha == 0) {
        canvas.restore(); // Pop state for this layer
        return; // Nothing more to draw for this layer or its children
      }
      if (alpha != 255) {
        var layerBounds = layer.describeClipBounds();
        canvas.saveLayer(layerBounds, ui.Paint()..color = ui.Color.fromARGB(alpha, 0, 0, 0));
        // Children drawn into this temp layer, then opacity applied on restore.
      }
    }
  } else if (layer is ColorFilterLayer) {
    if (layer.colorFilter != null) {
      canvas.saveLayer(layer.describeClipBounds(), ui.Paint()..colorFilter = layer.colorFilter);
    }
  } else if (layer is ImageFilterLayer) {
    if (layer.imageFilter != null) {
      canvas.saveLayer(layer.describeClipBounds(), ui.Paint()..imageFilter = layer.imageFilter);
    }
  }

  // Draw content or recurse
  if (layer is PictureLayer) {
    if (layer.picture != null) {
      canvas.drawPicture(layer.picture!);
    } else {
      debugPrint(
        '[_compositeLayerTreeToCanvas] PictureLayer has null picture. CanvasBounds: ${layer.canvasBounds}, Path: ${layer.debugCreatorPathToLayer}',
      );
    }
  } else if (layer is TextureLayer) {
    debugPrint(
      '[_compositeLayerTreeToCanvas] Encountered TextureLayer (id: ${layer.textureId}). Drawing placeholder.',
    );
    final placeholderPaint =
        Paint()
          ..color = const Color(0x80FF00FF) // Bright pink with 50% alpha
          ..style = PaintingStyle.fill;
    canvas.drawRect(layer.rect, placeholderPaint);
  } else if (layer is PlatformViewLayer) {
    debugPrint('[_compositeLayerTreeToCanvas] Encountered PlatformViewLayer. Skipping.');
  } else if (layer is ContainerLayer) {
    // Base for layers with children
    var child = layer.firstChild;
    while (child != null) {
      _compositeLayerTreeToCanvas(canvas, child, currentGlobalOffset);
      child = child.nextSibling;
    }
  }
  // Specific container types like AnnotatedRegionLayer, LeaderLayer, FollowerLayer
  // are already handled by 'is ContainerLayer' if they don't have specific drawing logic
  // beyond their children. If they do, they'd need their own 'else if'.
  // The provided code had them as separate else-ifs, which is fine for clarity
  // or if they might get special handling later.
  // For this example, assuming ContainerLayer handles their children traversal.
  else if (layer is! PictureLayer && layer is! TextureLayer && layer is! PlatformViewLayer) {
    // Catch-all for unhandled non-ContainerLayer
    debugPrint('[_compositeLayerTreeToCanvas] Unhandled layer type: ${layer.runtimeType}');
  }

  // Restore for layers that used saveLayer
  if ((layer is OpacityLayer && layer.alpha != null && layer.alpha != 0 && layer.alpha != 255) ||
      (layer is ColorFilterLayer && layer.colorFilter != null) ||
      (layer is ImageFilterLayer && layer.imageFilter != null)) {
    canvas.restore(); // Matches the saveLayer
  }

  canvas.restore(); // Matches the initial canvas.save()
}

extension LayerDebugging on Layer {
  String get debugCreatorPathToLayer {
    final path = <String>[];
    Layer? current = this;
    while (current != null) {
      var layerDesc = current.runtimeType.toString();
      if (current.debugCreator != null) {
        var creatorDesc = current.debugCreator.runtimeType.toString();
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
