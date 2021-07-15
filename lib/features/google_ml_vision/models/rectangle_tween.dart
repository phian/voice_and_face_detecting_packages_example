import 'package:flutter/material.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/models/rectangle.dart';

class RectangleTween extends Tween<Rectangle> {
  RectangleTween(Rectangle begin, Rectangle end)
      : super(begin: begin, end: end);

  @override
  Rectangle lerp(double t) => Rectangle.lerp(begin!, end!, t);
}
