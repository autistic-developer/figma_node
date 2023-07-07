import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

abstract class GradientShader {}

enum FillType {
  solid,
  linearGradient,
  radialGradient,
  sweepGradient,
  diamondGradient,
}

class Fill {
  final FillType? fillType;
  final Gradient? gradient;
  final Color? color;
  final BlendMode? blendMode;
  final double? opacity;
  final bool visible;
  const Fill(
      {this.fillType,
      this.opacity,
      this.gradient,
      this.color,
      this.blendMode,
      this.visible = true});
}
