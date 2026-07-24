import 'dart:math';

import 'package:flutter/material.dart';

/// Famílias de movimento — agrupam os padrões oficiais de
/// EXERCISE_SCHEMA.md §3 em silhuetas de animação parecidas, para não
/// precisar de uma ilustração única por padrão.
enum MovementFamily { horizontalPush, squatHinge, core, overhead, mobility }

MovementFamily movementFamilyForPattern(String pattern) {
  switch (pattern) {
    case 'push_horizontal':
    case 'pull_horizontal':
      return MovementFamily.horizontalPush;
    case 'squat':
    case 'hinge_posterior_chain':
      return MovementFamily.squatHinge;
    case 'core_anti_extension':
      return MovementFamily.core;
    case 'push_vertical':
    case 'support_dip':
    case 'hand_balance':
      return MovementFamily.overhead;
    default:
      return MovementFamily.mobility;
  }
}

/// Ilustração animada e minimalista (bonequinho de traços) representando
/// a família de movimento de um padrão. Não é uma demonstração técnica
/// real — é uma estilização de "game" para dar contexto visual rápido
/// enquanto o catálogo editorial completo com mídia real não existe
/// (EXERCISE_SCHEMA.md §5, `exercise_catalog.dart`).
class PatternIllustration extends StatefulWidget {
  const PatternIllustration({super.key, required this.pattern, this.size = 120});

  final String pattern;
  final double size;

  @override
  State<PatternIllustration> createState() => _PatternIllustrationState();
}

class _PatternIllustrationState extends State<PatternIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final family = movementFamilyForPattern(widget.pattern);
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _StickFigurePainter(
          family: family,
          t: Curves.easeInOut.transform(_controller.value),
          color: color,
        ),
      ),
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  _StickFigurePainter({required this.family, required this.t, required this.color});

  final MovementFamily family;

  /// 0..1, sobe e desce (`repeat(reverse: true)`).
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = color;

    final w = size.width;
    final h = size.height;
    final headRadius = w * 0.09;

    var neck = Offset(w * 0.5, h * 0.32);
    var hip = Offset(w * 0.5, h * 0.58);
    var leftHand = Offset(w * 0.28, h * 0.5);
    var rightHand = Offset(w * 0.72, h * 0.5);
    var leftFoot = Offset(w * 0.38, h * 0.92);
    var rightFoot = Offset(w * 0.62, h * 0.92);
    var headCenter = Offset(w * 0.5, h * 0.18);
    var scale = 1.0;

    switch (family) {
      case MovementFamily.horizontalPush:
        final extend = t;
        leftHand = Offset(w * _lerp(0.42, 0.12, extend), h * 0.48);
        rightHand = Offset(w * _lerp(0.58, 0.88, extend), h * 0.48);
      case MovementFamily.squatHinge:
        final dip = t;
        final hipY = _lerp(0.55, 0.72, dip);
        hip = Offset(w * 0.5, h * hipY);
        neck = Offset(w * 0.5, h * _lerp(0.30, 0.42, dip));
        headCenter = Offset(w * 0.5, h * _lerp(0.16, 0.28, dip));
        leftHand = Offset(w * 0.22, h * _lerp(0.5, 0.58, dip));
        rightHand = Offset(w * 0.78, h * _lerp(0.5, 0.58, dip));
      case MovementFamily.core:
        scale = 1 + 0.04 * sin(t * pi);
        leftHand = Offset(w * 0.25, h * 0.55);
        rightHand = Offset(w * 0.75, h * 0.55);
        leftFoot = Offset(w * 0.2, h * 0.9);
        rightFoot = Offset(w * 0.8, h * 0.9);
      case MovementFamily.overhead:
        final raise = t;
        leftHand =
            Offset(w * _lerp(0.25, 0.32, raise), h * _lerp(0.55, 0.06, raise));
        rightHand =
            Offset(w * _lerp(0.75, 0.68, raise), h * _lerp(0.55, 0.06, raise));
      case MovementFamily.mobility:
        final angle = t * 2 * pi;
        leftHand = Offset(
          w * 0.5 + w * 0.28 * cos(angle),
          h * 0.35 + h * 0.28 * sin(angle),
        );
        rightHand = Offset(
          w * 0.5 + w * 0.28 * cos(angle + pi),
          h * 0.35 + h * 0.28 * sin(angle + pi),
        );
    }

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(scale);
    canvas.translate(-w / 2, -h / 2);

    canvas.drawLine(neck, hip, linePaint);
    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawLine(neck, leftHand, linePaint);
    canvas.drawLine(neck, rightHand, linePaint);
    canvas.drawLine(hip, leftFoot, linePaint);
    canvas.drawLine(hip, rightFoot, linePaint);

    canvas.restore();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.family != family;
}
