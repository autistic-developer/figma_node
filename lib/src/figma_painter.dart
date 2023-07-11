import 'dart:ui';

import 'package:figma_node/src/effects/effects.dart';
import 'package:figma_node/src/fill/fill.dart';
import 'package:figma_node/src/stroke/stroke.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' as mat;

class FigmaPainter extends CustomPainter {
  final double rotation;
  final Offset rotationOrigin;
  final Rect rect;
  final Path path;
  final Path? strokePath;
  final List<Fill>? fills;
  final List<Stroke>? strokes;
  final double strokeWeight;
  final StrokeAlign strokeAlign;
  final StrokeJoin? strokeJoin;
  final StrokeCap? strokeCap;
  final double? strokeMiterLimit;
  final List<InnerShadowEffect>? innerShadows;
  final List<DropShadowEffect>? dropShadows;
  final LayerBlurEffect? layerBlur;
  final bool Function(FigmaPainter painter) shouldRepaintCall;
  const FigmaPainter({
    required this.shouldRepaintCall,
    required this.rotation,
    required this.rotationOrigin,
    required this.rect,
    required this.path,
    this.strokePath,
    this.fills,
    this.strokes,
    this.strokeWeight = 0,
    required this.strokeAlign,
    this.strokeJoin,
    this.strokeCap,
    this.strokeMiterLimit,
    this.innerShadows,
    this.dropShadows,
    this.layerBlur,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final (scaledPath, blackMatter) = _scalePath(size);
    final (strokeMask, strokePaint) = _setStrokePaint(scaledPath);
    final Paint fillPaint = Paint();

    //layer-blur open
    if (layerBlur != null && layerBlur!.visible && layerBlur!.blurRadius != 0) {
      final sigma = _convertRadiusToSigma(layerBlur!.blurRadius);
      canvas.saveLayer(
          null,
          Paint()
            ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
    }

    _offShederAndFilters(strokePaint, fillPaint);
    // drop-shadow
    if (dropShadows != null && dropShadows!.isNotEmpty) {
      for (DropShadowEffect dropShadow in dropShadows!) {
        if (dropShadow.visible &&
            (dropShadow.offset != Offset.zero && dropShadow.blurRadius != 0)) {
          _applyDropShadowEffect(canvas, dropShadow, blackMatter, fillPaint);
        }
      }
    }

    // fills
    if (fills != null) {
      for (Fill fill in fills!) {
        if (fill.visible) {
          _fillPath(canvas, fill, scaledPath, fillPaint);
        }
      }
    }

    _offShederAndFilters(strokePaint, fillPaint);
    // inner-shadow
    if (innerShadows != null && innerShadows!.isNotEmpty) {
      for (InnerShadowEffect innerShadow in innerShadows!) {
        if (innerShadow.visible &&
            (innerShadow.offset != Offset.zero &&
                innerShadow.blurRadius != 0)) {
          _applyInnerShadowEffect(canvas, innerShadow, blackMatter, fillPaint);
        }
      }
    }

    // strokes
    if (strokeWeight != 0 && strokes != null && strokes!.isNotEmpty) {
      if (strokeMask != null) {
        canvas.save();
        canvas.clipPath(strokeMask);
      }
      for (Stroke stroke in strokes!) {
        if (stroke.visible) {
          _fillStroke(canvas, stroke, scaledPath, strokePaint);
        }
      }
      if (strokeMask != null) {
        canvas.restore();
      }
    }

    //layer-blur close
    if (layerBlur != null && layerBlur!.visible && layerBlur!.blurRadius != 0) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return shouldRepaintCall(oldDelegate as FigmaPainter);
  }

  Matrix4 _setRotationMatrix(Size size) {
    return Matrix4.translation(
        mat.Vector3(rotationOrigin.dx, rotationOrigin.dy, 0.0))
      ..rotateZ(_degreesToRadians(rotation))
      ..translate(mat.Vector3(-rotationOrigin.dx, -rotationOrigin.dy, 0.0));
  }

  void _offShederAndFilters(Paint strokePaint, Paint fillPaint) {
    strokePaint.colorFilter = null;
    strokePaint.shader = null;
    fillPaint.colorFilter = null;
    fillPaint.shader = null;
  }

  void _applyDropShadowEffect(Canvas canvas, DropShadowEffect dropShadow,
      Path blackMatter, Paint fillPaint) {
    canvas.saveLayer(null, Paint()..blendMode = dropShadow.blendMode);
    _drawBlackMatter(canvas, Colors.black, blackMatter, fillPaint);

    final double sigma = _convertRadiusToSigma(dropShadow.blurRadius);

    final shadowPaint = Paint()
      ..blendMode = BlendMode.srcOut
      ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    canvas
      ..saveLayer(null, shadowPaint)
      ..translate(dropShadow.offset.dx, dropShadow.offset.dy);

    _drawBlackMatter(canvas, Colors.black, blackMatter, fillPaint);

    canvas.restore();

    canvas.saveLayer(
        null,
        Paint()
          ..blendMode = BlendMode.srcIn
          ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));

    canvas.drawPaint(Paint()..color = dropShadow.color!);
    canvas.restore();

    canvas.restore();
  }

  void _applyInnerShadowEffect(Canvas canvas, InnerShadowEffect innerShadow,
      Path blackMatter, Paint fillPaint) {
    canvas.saveLayer(null, Paint()..blendMode = innerShadow.blendMode);
    _drawBlackMatter(canvas, innerShadow.color!, blackMatter, fillPaint);

    final double sigma = _convertRadiusToSigma(innerShadow.blurRadius);
    final shadowPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

    canvas
      ..saveLayer(null, shadowPaint)
      ..translate(innerShadow.offset.dx, innerShadow.offset.dy);

    _drawBlackMatter(canvas, Colors.black, blackMatter, fillPaint);

    canvas.restore();
    canvas.restore();
  }

  void _drawBlackMatter(
      Canvas canvas, Color color, Path blackMatter, Paint fillPaint) {
    canvas.drawPath(blackMatter, fillPaint..color = color);
  }

  double _convertRadiusToSigma(radius) {
    return radius > 0 ? radius * 0.57735 + 0.5 : 0;
  }

  (Path?, Paint) _setStrokePaint(Path scaledPath) {
    Path? strokMask;
    final strokePaint = Paint()..style = PaintingStyle.stroke;
    if (strokeWeight != 0) {
      strokePaint.strokeWidth = strokeWeight;
      if (strokeAlign != StrokeAlign.center) {
        strokMask = (strokeAlign == StrokeAlign.outside)
            ? Path.combine(PathOperation.difference,
                Path()..addRect(Rect.largest), scaledPath)
            : Path.from(scaledPath);
        strokePaint.strokeWidth *= 2.0;
      }
    }
    if (strokeCap != null) {
      strokePaint.strokeCap = strokeCap!;
    }
    if (strokeJoin != null) {
      strokePaint.strokeJoin = strokeJoin!;
    }
    if (strokeMiterLimit != null) {
      strokePaint.strokeMiterLimit = strokeMiterLimit!;
    }
    return (strokMask, strokePaint);
  }

  (Path, Path) _scalePath(Size size) {
    final double canvasWidth = size.width;
    final Rect pathBounds = path.getBounds();

    final double scaleX = canvasWidth / pathBounds.width;

    Matrix4 matrix = Matrix4.identity()..scale(scaleX, scaleX);
    Path scaledPath = path.transform(matrix.storage);
    Path blackMatter =
        _setBlackMatter(scaledPath, pathBounds, canvasWidth, matrix);

    if (rotation != 0) {
      scaledPath = scaledPath
          .transform(_setRotationMatrix(scaledPath.getBounds().size).storage);
      _setRotationMatrix(blackMatter.getBounds().size);
      blackMatter = blackMatter
          .transform(_setRotationMatrix(scaledPath.getBounds().size).storage);
    }
    return (scaledPath, blackMatter);
  }

  Path _setBlackMatter(
      Path scaledPath, Rect pathBounds, double canvasWidth, Matrix4 matrix) {
    if (strokeAlign == StrokeAlign.inside || strokeWeight == 0) {
      return Path.from(scaledPath);
    }
    if (strokeAlign == StrokeAlign.outside) {
      final double scaleX = (canvasWidth + strokeWeight * 2) / pathBounds.width;
      matrix = Matrix4.identity()..scale(scaleX, scaleX);
    }
    pathBounds = strokePath!.getBounds();

    return Path.combine(
        PathOperation.union, scaledPath, strokePath!.transform(matrix.storage));
  }

  void _fillStroke(
      Canvas canvas, Stroke stroke, Path scaledPath, Paint strokePaint) {
    if (stroke.blendMode != null) {
      canvas.saveLayer(null, Paint()..blendMode = stroke.blendMode!);
    }
    if (stroke.color != null) {
      strokePaint.color = stroke.color!;
    } else {
      strokePaint.shader = stroke.gradient!.createShader(rect);
      if (stroke.opacity != null) {
        strokePaint.colorFilter = ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          stroke.opacity!,
          0,
        ]);
      }
    }

    canvas.drawPath(scaledPath, strokePaint);
    if (stroke.blendMode != null) {
      canvas.restore();
    }
    strokePaint.shader = null;
    strokePaint.colorFilter = null;
  }

  void _fillPath(Canvas canvas, Fill fill, Path scaledPath, Paint fillPaint) {
    if (fill.blendMode != null) {
      canvas.saveLayer(null, Paint()..blendMode = fill.blendMode!);
    }
    if (fill.color != null) {
      fillPaint.color = fill.color!;
    } else {
      fillPaint.shader = fill.gradient!.createShader(rect);
      if (fill.opacity != null) {
        fillPaint.colorFilter = ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          fill.opacity!,
          0,
        ]);
      }
    }

    canvas.drawPath(scaledPath, fillPaint);
    if (fill.blendMode != null) {
      canvas.restore();
    }
    fillPaint.shader = null;
    fillPaint.colorFilter = null;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
