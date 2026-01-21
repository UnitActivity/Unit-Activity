import 'package:flutter/material.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final fontSize = isMobile ? 24.0 : 60.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                SizedBox(
                  width: isMobile ? 100 : 150,
                  height: isMobile ? 100 : 150,
                  child: CustomPaint(painter: PersonPushingPainter()),
                ),
                const SizedBox(height: 40),

                // Main Error Text - Responsive
                if (isMobile)
                  Column(
                    children: [
                      Text(
                        'OPSS!',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue[700],
                          letterSpacing: 2,
                          height: 1,
                        ),
                      ),
                      Text(
                        'PAGE NOT FOUND',
                        style: TextStyle(
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue[600],
                          letterSpacing: 2,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'OPSS! ',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue[700],
                          letterSpacing: 2,
                          height: 1,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'PAGE NOT FOUND',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue[600],
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  '404 - PAGE NOT FOUND',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 16,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),

                // Back to Home Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
