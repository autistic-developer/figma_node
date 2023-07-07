import 'package:figma_node/src/fill/fill.dart';

enum StrokeAlign { inside, center, outside }

class Stroke extends Fill {
  const Stroke(
      {super.fillType,
      super.opacity,
      super.gradient,
      super.color,
      super.blendMode,
      super.visible});
}
