import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🍓 GLOBAL BACKGROUND
        Positioned.fill(
          child: CustomPaint(
            painter: StrawberryPatternPainter(),
          ),
        ),

        // 🔝 SCREEN CONTENT
        child,
      ],
    );
  }
}

class StrawberryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 🍓 Light strawberry background
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF3F3);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // 🍓 Watermark pattern
    const double gap = 64;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (double x = -20; x < size.width + gap; x += gap) {
      for (double y = -20; y < size.height + gap; y += gap) {
        textPainter.text = const TextSpan(
          text: '🍓',
          style: TextStyle(
            fontSize: 16,
            color: Color(0x33E53935),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (y % (gap * 2) == 0 ? 10 : 0), y),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
