import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class RadialGradientTransform extends GradientTransform {
  final Offset anchor;
  final double scaleX;
  final double scaleY;
  final double rotation;
  final Size size;

  const RadialGradientTransform(
      {required this.anchor,
      this.scaleX = 1.0,
      this.scaleY = 1.0,
      this.rotation = 0.0,
      required this.size});
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    Matrix4 matrix = Matrix4.identity();
    matrix.translate(
        Vector3(anchor.dx * size.width, anchor.dy * size.height, 0.0));
    matrix.setRotationZ(rotation);
    matrix.scale(scaleX, scaleY);
    return matrix;
  }
}
