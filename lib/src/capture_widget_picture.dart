import 'package:df_widgets/_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

typedef WidgetPicture = ui.Picture;

ui.Picture? captureWidgetPicture(BuildContext context) {
  final renderObject = context.findRenderObject() as RenderRepaintBoundary?;
  if (renderObject == null || renderObject.debugLayer == null) {
    debugPrint('RenderObject or debugLayer is null');
    return null;
  }
  renderObject.markNeedsPaint();
  final pictureLayer = findPictureLayer(renderObject.debugLayer);
  if (pictureLayer == null || pictureLayer.picture == null) {
    debugPrint('No PictureLayer or Picture found');
    return null;
  }
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  try {
    canvas.drawPicture(pictureLayer.picture!);
    final clonedPicture = pictureRecorder.endRecording();
    return clonedPicture;
  } catch (e) {
    debugPrint('Failed to clone picture: $e');
    return null;
  }
}

PictureLayer? findPictureLayer(Layer? layer) {
  if (layer == null) return null;
  if (layer is PictureLayer && layer.picture != null) return layer;
  if (layer is ContainerLayer) {
    var child = layer.firstChild;
    while (child != null) {
      final pictureLayer = findPictureLayer(child);
      if (pictureLayer != null) return pictureLayer;
      child = child.nextSibling;
    }
  }
  return null;
}

class PicturePainter extends CustomPainter {
  final ui.Picture picture;

  PicturePainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PictureWidget extends StatelessWidget {
  final WidgetPicture? picture;
  final Size? size;

  const PictureWidget({super.key, required this.picture, this.size});

  @override
  Widget build(BuildContext context) {
    if (picture == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(size: constraints.biggest, painter: PicturePainter(picture!));
      },
    );
  }
}
