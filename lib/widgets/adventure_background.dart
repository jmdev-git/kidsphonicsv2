import 'package:flutter/material.dart';

/// Page background with gradient + static organic blob shapes + decorative elements.
class AdventureBackground extends StatelessWidget {
  const AdventureBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6DCFF), // soft lavender
              Color(0xFFDFF8F4), // mint teal
              Color(0xFFFFEBCB), // warm peach
            ],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BlobBackgroundPainter())),
          ),
          child,
        ]),
      );
}

class _BlobBackgroundPainter extends CustomPainter {
  const _BlobBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Large background blobs ────────────────────────────────────────────
    // Each blob is a closed cubic bezier path — soft organic shapes.
    final blobPaint = Paint()..style = PaintingStyle.fill;

    // Blob 1 — top-left, lavender-purple
    blobPaint.color = const Color(0xFF9A71DD).withValues(alpha: .13);
    final blob1 = Path();
    blob1.moveTo(w * -0.05, h * 0.05);
    blob1.cubicTo(w * 0.18, h * -0.04, w * 0.42, h * 0.08, w * 0.38, h * 0.28);
    blob1.cubicTo(w * 0.34, h * 0.48, w * 0.06, h * 0.44, w * -0.04, h * 0.30);
    blob1.cubicTo(w * -0.14, h * 0.16, w * -0.28, h * 0.14, w * -0.05, h * 0.05);
    blob1.close();
    canvas.drawPath(blob1, blobPaint);

    // Blob 2 — bottom-right, teal
    blobPaint.color = const Color(0xFF00BFA5).withValues(alpha: .10);
    final blob2 = Path();
    blob2.moveTo(w * 1.05, h * 0.72);
    blob2.cubicTo(w * 0.88, h * 0.58, w * 0.62, h * 0.68, w * 0.64, h * 0.84);
    blob2.cubicTo(w * 0.66, h * 1.00, w * 0.90, h * 1.06, w * 1.04, h * 0.96);
    blob2.cubicTo(w * 1.18, h * 0.86, w * 1.22, h * 0.86, w * 1.05, h * 0.72);
    blob2.close();
    canvas.drawPath(blob2, blobPaint);

    // Blob 3 — centre, warm orange/peach
    blobPaint.color = const Color(0xFFFFB347).withValues(alpha: .09);
    final blob3 = Path();
    blob3.moveTo(w * 0.55, h * 0.38);
    blob3.cubicTo(w * 0.72, h * 0.28, w * 0.92, h * 0.38, w * 0.90, h * 0.55);
    blob3.cubicTo(w * 0.88, h * 0.72, w * 0.68, h * 0.72, w * 0.55, h * 0.65);
    blob3.cubicTo(w * 0.42, h * 0.58, w * 0.38, h * 0.48, w * 0.55, h * 0.38);
    blob3.close();
    canvas.drawPath(blob3, blobPaint);

    // Blob 4 — bottom-left, pink accent
    blobPaint.color = const Color(0xFFFF6B9D).withValues(alpha: .08);
    final blob4 = Path();
    blob4.moveTo(w * -0.08, h * 0.78);
    blob4.cubicTo(w * 0.08, h * 0.65, w * 0.28, h * 0.70, w * 0.26, h * 0.86);
    blob4.cubicTo(w * 0.24, h * 1.02, w * 0.02, h * 1.05, w * -0.10, h * 0.95);
    blob4.cubicTo(w * -0.22, h * 0.85, w * -0.24, h * 0.91, w * -0.08, h * 0.78);
    blob4.close();
    canvas.drawPath(blob4, blobPaint);

    // Blob 5 — top-right, light blue
    blobPaint.color = const Color(0xFF64B5F6).withValues(alpha: .10);
    final blob5 = Path();
    blob5.moveTo(w * 0.72, h * -0.04);
    blob5.cubicTo(w * 0.92, h * -0.06, w * 1.10, h * 0.08, w * 1.06, h * 0.22);
    blob5.cubicTo(w * 1.02, h * 0.36, w * 0.82, h * 0.30, w * 0.72, h * 0.20);
    blob5.cubicTo(w * 0.62, h * 0.10, w * 0.52, h * 0.06, w * 0.72, h * -0.04);
    blob5.close();
    canvas.drawPath(blob5, blobPaint);

    // ── White cloud clusters (kept from original) ─────────────────────────
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .60);
    for (final point in [
      const Offset(.06, .12),
      const Offset(.94, .48),
      const Offset(.12, .88)
    ]) {
      final center = Offset(w * point.dx, h * point.dy);
      canvas.drawCircle(center, 30, cloudPaint);
      canvas.drawCircle(center.translate(28, 8), 22, cloudPaint);
      canvas.drawCircle(center.translate(-24, 10), 18, cloudPaint);
    }

    // ── Diamond star shapes ────────────────────────────────────────────────
    final starPaint = Paint()
      ..color = const Color(0xFF9A71DD).withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    for (final point in [
      const Offset(.88, .09),
      const Offset(.08, .43),
      const Offset(.9, .8)
    ]) {
      final x = w * point.dx;
      final y = h * point.dy;
      canvas.drawPath(
          Path()
            ..moveTo(x, y - 10)
            ..lineTo(x + 3, y - 3)
            ..lineTo(x + 10, y)
            ..lineTo(x + 3, y + 3)
            ..lineTo(x, y + 10)
            ..lineTo(x - 3, y + 3)
            ..lineTo(x - 10, y)
            ..lineTo(x - 3, y - 3)
            ..close(),
          starPaint);
    }

    // ── Confetti dots ──────────────────────────────────────────────────────
    const confetti = [Color(0xFFFFB84D), Color(0xFFF582AD), Color(0xFF51BDB0)];
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 12; i++) {
      dotPaint.color = confetti[i % confetti.length].withValues(alpha: .32);
      final center = Offset(
          w * (i.isEven ? .025 : .975), h * ((i + .5) / 12));
      canvas.drawCircle(center, i % 3 == 0 ? 6 : 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_BlobBackgroundPainter oldDelegate) => false;
}

class AdventureMascot extends StatelessWidget {
  const AdventureMascot({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 116,
          height: 116,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    shape: BoxShape.circle)),
            const Icon(Icons.star_rounded, size: 116, color: Color(0xFFFFD76A)),
            const Positioned(
                top: 49,
                child: Row(children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                ])),
            const Positioned(
                top: 56,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 25, color: Color(0xFF49315D))),
          ]),
        ),
      );
}
