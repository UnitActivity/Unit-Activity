import 'package:flutter/material.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(painter: PersonPushingPainter()),
            ),
            const SizedBox(height: 40),

            // Main Error Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OPSS! ',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue[700],
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
                Text(
                  'PAGE NOT FOUND',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue[600],
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              '404 - PAGE NOT FOUND',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 60),

            // Back to Home Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the person pushing illustration
class PersonPushingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.25),
      size.width * 0.08,
      fillPaint,
    );

    // Body
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.33),
      Offset(size.width * 0.25, size.height * 0.6),
      paint,
    );

    // Arms (pushing gesture)
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.4),
      paint,
    );

    // Legs
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.15, size.height * 0.85),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.6),
      Offset(size.width * 0.35, size.height * 0.85),
      paint,
    );

    // Motion lines
    final motionPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * 0.52 + (i * 8), size.height * 0.35 + (i * 5)),
        Offset(size.width * 0.58 + (i * 8), size.height * 0.35 + (i * 5)),
        motionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
