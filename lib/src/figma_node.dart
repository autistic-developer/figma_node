import 'dart:ui';

import 'package:figma_node/src/effects/effects.dart';
import 'package:figma_node/src/figma_painter.dart';
import 'package:figma_node/src/fill/fill.dart';
import 'package:figma_node/src/stroke/stroke.dart';
import 'package:flutter/material.dart';

import 'package:svg_path_parser/svg_path_parser.dart';
import 'dart:math' as math;

class Effects {
  final List<InnerShadowEffect>? innerShadows;
  final List<DropShadowEffect>? dropShadows;
  final LayerBlurEffect? layerBlur;
  final BackgroundBlurEffect? backgroundBlur;
  Effects(
      {this.dropShadows,
      this.backgroundBlur,
      this.layerBlur,
      this.innerShadows});
}

class FigmaNode extends StatelessWidget {
  static bool _defaultShouldRepaint(FigmaPainter painter) {
    return false;
  }

  FigmaNode(
      {super.key,
      bool Function(FigmaPainter painter) shouldRepaintCall =
          _defaultShouldRepaint,
      this.stackAlign = Alignment.center,
      this.stackClip = Clip.none,
      this.rotation = 0,
      this.rotationOrigin,
      this.opacity = 1,
      required this.size,
      required String path,
      List<Fill>? fills,
      List<Stroke>? strokes,
      String? strokePath,
      this.strokeWeight = 0,
      this.strokeAlign = StrokeAlign.inside,
      StrokeJoin? strokeJoin = StrokeJoin.miter,
      StrokeCap? strokeCap,
      double? strokeMiterLimit,
      Effects? effects,
      this.child,
      this.childs})
      : path = parseSvgPath(path),
        assert(
            (effects?.backgroundBlur != null)
                ? ((strokeAlign != StrokeAlign.inside)
                    ? strokePath != null
                    : true)
                : true,
            "strokePath can't be null when strokeAlign is StrokeAlign.center or StrokeAlign.outside"),
        strokePath = strokePath != null ? parseSvgPath(strokePath) : null,
        painter = (fills == null && strokes == null)
            ? null
            : FigmaPainter(
                shouldRepaintCall: shouldRepaintCall,
                rotation: rotation,
                rotationOrigin:
                    rotationOrigin ?? Offset(size.width / 2, size.height / 2),
                rect: Offset.zero & size,
                path: parseSvgPath(path),
                fills: fills,
                strokes: strokes,
                strokeJoin: strokeJoin,
                strokeCap: strokeCap,
                strokeMiterLimit: strokeMiterLimit,
                strokeWeight: strokeWeight,
                strokeAlign: strokeAlign,
                innerShadows: effects?.innerShadows,
                dropShadows: effects?.dropShadows,
                layerBlur: effects?.layerBlur,
              ),
        backgroundBlur = effects?.backgroundBlur;

  final double opacity;
  final double rotation;
  final Offset? rotationOrigin;
  final Size size;
  final BackgroundBlurEffect? backgroundBlur;
  final FigmaPainter? painter;
  final Path path;
  final Path? strokePath;
  final Widget? child;
  final List<Widget>? childs;
  final StrokeAlign strokeAlign;
  final double strokeWeight;
  final AlignmentGeometry stackAlign;
  final Clip stackClip;

  @override
  Widget build(BuildContext context) {
    if (painter == null) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      );
    }
    Widget widget;
    Widget? bgBlur;
    if (backgroundBlur != null && backgroundBlur!.visible) {
      final sigma = convertRadiusToSigma(backgroundBlur!.blurRadius);
      bgBlur = Transform.rotate(
        origin: rotationOrigin != null
            ? rotationOrigin! - Offset(size.width / 2, size.height / 2)
            : null,
        angle: _degreesToRadians(rotation),
        child: ClipPath(
          clipper: GlassClipper(path: _scalePath()),
          clipBehavior: Clip.hardEdge,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
            ),
            child: SizedBox(
              width: size.width,
              height: size.height,
            ),
          ),
        ),
      );
      if (opacity != 1) {
        bgBlur = Opacity(opacity: opacity, child: bgBlur);
      }
    }
    widget = SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: painter,
      ),
    );
    if (opacity != 1) {
      widget = Opacity(opacity: opacity, child: widget);
    }
    widget = Stack(
      alignment: stackAlign,
      clipBehavior: stackClip,
      children: [
        if (bgBlur != null) bgBlur,
        widget,
        if (child != null) child!,
        if (childs != null) ...childs!
      ],
    );

    return Container(alignment: Alignment.center, child: widget);
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  double convertRadiusToSigma(radius) {
    return radius > 0 ? radius * 0.57735 + 0.5 : 0;
  }

  Path _scalePath() {
    final double canvasWidth = size.width;
    Rect pathBounds = path.getBounds();

    double scaleX = canvasWidth / pathBounds.width;

    Matrix4 matrix = Matrix4.identity()..scale(scaleX, scaleX);

    final Path path1 = path.transform(matrix.storage);
    if (strokeAlign == StrokeAlign.inside || strokeWeight == 0) {
      return path1;
    }
    pathBounds = strokePath!.getBounds();

    if (strokeAlign == StrokeAlign.outside) {
      scaleX = (canvasWidth + strokeWeight * 2) / pathBounds.width;
      matrix = Matrix4.identity()..scale(scaleX, scaleX);
      return Path.combine(
          PathOperation.union, path1, strokePath!.transform(matrix.storage));
    }
    //StrokeAlign.center
    return Path.combine(
        PathOperation.union, path1, strokePath!.transform(matrix.storage));
  }
}

class GlassClipper extends CustomClipper<Path> {
  final Path path;

  GlassClipper({required this.path});
  @override
  Path getClip(Size size) {
    return path;
  }

  @override
  bool shouldReclip(GlassClipper oldClipper) {
    return false;
  }
}
