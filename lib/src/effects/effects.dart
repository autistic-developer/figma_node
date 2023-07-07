import 'package:flutter/material.dart';

abstract class FigmaEffectShadow {
  final Offset offset;
  final double blurRadius;
  final BlendMode blendMode;
  final Color? color;
  final bool visible;

  const FigmaEffectShadow(
      {this.color = Colors.transparent,
      this.offset = Offset.zero,
      this.blurRadius = 0,
      this.blendMode = BlendMode.srcOver,
      this.visible = true});
}

abstract class FigmaEffectBlur {
  final double blurRadius;
  final bool visible;

  const FigmaEffectBlur({required this.blurRadius, this.visible = true});
}

class DropShadowEffect extends FigmaEffectShadow {
  const DropShadowEffect(
      {super.color,
      super.offset,
      super.blurRadius,
      super.blendMode,
      super.visible});
}

class InnerShadowEffect extends FigmaEffectShadow {
  const InnerShadowEffect(
      {super.color,
      super.offset,
      super.blurRadius,
      super.blendMode,
      super.visible});
}

class LayerBlurEffect extends FigmaEffectBlur {
  LayerBlurEffect({required super.blurRadius, super.visible});
}

class BackgroundBlurEffect extends FigmaEffectBlur {
  BackgroundBlurEffect({required super.blurRadius, super.visible});
}
