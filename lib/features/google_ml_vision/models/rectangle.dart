import 'dart:ui';

import 'package:flutter/material.dart';

class Rectangle {
  const Rectangle({this.width, this.height, this.color});

  final double? width;
  final double? height;
  final Color? color;

  static Rectangle lerp(Rectangle begin, Rectangle end, double t) {
    Color? color;
    if (t > .5) {
      color = Color.lerp(begin.color, end.color, (t - .5) / .25);
    } else {
      color = begin.color;
    }

    return Rectangle(
      width: lerpDouble(begin.width, end.width, t),
      height: lerpDouble(begin.height, end.height, t),
      color: color,
    );
  }
}