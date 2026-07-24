import 'dart:math';

import 'package:flutter/material.dart';

/// Celebração de subida de nível: explosão de partículas + selo com
/// escala elástica. Só Flutter puro (`CustomPainter` + `AnimationController`),
/// sem pacote de confete externo.
class LevelUpCelebration extends StatefulWidget {
  const LevelUpCelebration({super.key, required this.level});

  final int level;

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = Curves.elasticOut.transform(_controller.value.clamp(0, 1));
        return SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 160),
                painter: _BurstPainter(
                  progress: _controller.value,
                  color: colorScheme.tertiary,
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech, color: colorScheme.tertiary, size: 48),
                    Text(
                      'Nível ${widget.level}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _particleCount = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0, 1));
    final maxDistance = size.width / 2;

    for (var i = 0; i < _particleCount; i++) {
      final angle = (2 * pi / _particleCount) * i;
      final distance = progress * maxDistance;
      final dx = center.dx + distance * cos(angle);
      final dy = center.dy + distance * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
