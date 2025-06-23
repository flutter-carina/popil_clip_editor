import 'package:flutter/material.dart';

class AppSliderShape extends SliderComponentShape {
  final double thumbRadius;

  const AppSliderShape({
    required this.thumbRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF1D1D1D)
      ..style = PaintingStyle.fill;

    final mainRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: 35,
        height: 25,
      ),
      const Radius.circular(13),
    );
    canvas.drawRRect(mainRect, backgroundPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF26272B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(mainRect, borderPaint);

    // Draw orange line (top)

    // Draw two gray lines
    final grayLinePaint = Paint()
      ..color = const Color(0xFF34393F)
      ..style = PaintingStyle.fill;

    // First gray line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(-6, 0),
          width: 2,
          height: 14,
        ),
        const Radius.circular(1),
      ),
      grayLinePaint,
    );

    // Second gray line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(-1, 0),
          width: 2,
          height: 14,
        ),
        const Radius.circular(1),
      ),
      grayLinePaint,
    );
    final orangePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(5, 0), // Moved left for horizontal layout
          width: 3,
          height: 14,
        ),
        const Radius.circular(1.5),
      ),
      orangePaint,
    );
  }
}
