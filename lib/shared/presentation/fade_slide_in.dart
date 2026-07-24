import 'package:flutter/material.dart';

/// Entrada animada (fade + leve deslize de baixo para cima) para dar
/// sensação de "game" aos cards do dashboard, sem depender de pacote de
/// animação externo. Use [index] para escalonar a entrada de uma lista
/// de widgets (cada item começa um pouco depois do anterior).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + 60 * index),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
