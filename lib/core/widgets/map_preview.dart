import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MapPreview extends StatelessWidget {
  const MapPreview({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF30383D)),
    ),
    child: Stack(
      children: [
        CustomPaint(size: Size.infinite, painter: MapPainter()),
        Positioned(
          top: 13,
          left: 13,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xE61A2025),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              children: [
                Icon(Icons.my_location, size: 13, color: AppTheme.amber),
                SizedBox(width: 6),
                Text(
                  'Ikeja, Lagos',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 13,
          right: 13,
          child: Column(
            children: [
              MapLegend(color: AppTheme.danger, label: 'High'),
              SizedBox(height: 5),
              MapLegend(color: AppTheme.amber, label: 'Medium'),
            ],
          ),
        ),
      ],
    ),
  );
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF202B2D),
    );
    final line = Paint()
      ..color = const Color(0xFF334342)
      ..strokeWidth = 1.2;
    for (var x = -size.height; x < size.width + size.height; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
    }
    for (var y = 25.0; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 35), line);
    }
    canvas.drawOval(
      Rect.fromLTWH(size.width * .55, -40, size.width * .7, 115),
      Paint()..color = const Color(0xFF183236),
    );
    _pin(
      canvas,
      Offset(size.width * .31, size.height * .48),
      AppTheme.danger,
      10,
    );
    _pin(
      canvas,
      Offset(size.width * .64, size.height * .32),
      AppTheme.amber,
      8,
    );
    _pin(
      canvas,
      Offset(size.width * .72, size.height * .68),
      AppTheme.amber,
      7,
    );
    _pin(
      canvas,
      Offset(size.width * .47, size.height * .78),
      AppTheme.danger,
      8,
    );
  }

  void _pin(Canvas canvas, Offset point, Color color, double radius) {
    canvas.drawCircle(
      point,
      radius * 1.9,
      Paint()..color = color.withAlpha(35),
    );
    canvas.drawCircle(point, radius, Paint()..color = color);
    canvas.drawCircle(
      point,
      radius * .35,
      Paint()..color = const Color(0xFF202B2D),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFFD0D6D8)),
      ),
    ],
  );
}
