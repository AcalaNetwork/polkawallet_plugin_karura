import 'dart:async';
import 'package:flutter/material.dart';

class MultiplySliderThumbShape extends SliderComponentShape {
  MultiplySliderThumbShape({this.isShow = true});

  final isShow;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(28, 28);
  }

  @override
  Future<void> paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) async {
    final Canvas canvas = context.canvas;
    if (this.isShow) {
      final rrect = RRect.fromLTRBR(center.dx - 10, center.dy - 10,
          center.dx + 10, center.dy + 10, Radius.circular(6.67));
      canvas.drawShadow(
          Path()
            ..addRRect(
              RRect.fromLTRBR(rrect.left - 4, rrect.top - 4, rrect.right + 4,
                  rrect.bottom + 4, Radius.circular(8)),
            )
            ..close(),
          Color(0x80FFFFFF),
          0.5,
          true);
      canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
    } else {
      final rrect = RRect.fromLTRBR(center.dx - 2, center.dy - 7, center.dx + 2,
          center.dy + 7, Radius.circular(1));
      canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
    }
  }
}
