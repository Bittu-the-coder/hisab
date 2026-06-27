import 'package:flutter/material.dart';

class HisabLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const HisabLogo({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(color: c),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final s = r * 0.55;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = color.withAlpha(20)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.save();

    final leftX = cx - s * 0.35;
    const barW = 1.8;

    final bar1 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(leftX, cy), width: barW, height: s * 1.5),
      const Radius.circular(1),
    );
    canvas.drawRRect(bar1, paint);

    final bar2 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + s * 0.35, cy), width: barW, height: s * 1.5),
      const Radius.circular(1),
    );
    canvas.drawRRect(bar2, paint);

    final crossbar = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + s * 0.02, cy - s * 0.05), width: s * 0.85, height: barW),
      const Radius.circular(1),
    );
    canvas.drawRRect(crossbar, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.color != color;
}
