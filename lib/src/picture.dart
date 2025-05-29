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

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef Picture = ui.Picture;

Picture? captureWidgetPicture(BuildContext context) {
  if (!context.mounted) {
    debugPrint('Context is not mounted');
    return null;
  }
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PictureWidget extends StatelessWidget {
  final Picture? picture;
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
