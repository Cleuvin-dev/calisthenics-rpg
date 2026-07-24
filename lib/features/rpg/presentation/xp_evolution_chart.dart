import 'package:flutter/material.dart';

/// Gráfico de evolução (barras) de XP nos últimos dias — implementado
/// com widgets Flutter puros (sem pacote de charting), animando a
/// entrada de cada barra.
class XpEvolutionChart extends StatelessWidget {
  const XpEvolutionChart({super.key, required this.dailyTotals});

  /// Do mais antigo ao mais recente, mesmo tamanho de [dailyTotals].
  final List<int> dailyTotals;

  static const _weekdayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final maxValue = dailyTotals.fold<int>(1, (max, v) => v > max ? v : max);
    final now = DateTime.now();
    const chartHeight = 120.0;

    return SizedBox(
      height: chartHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < dailyTotals.length; i++)
            Expanded(
              child: _AnimatedBar(
                value: dailyTotals[i],
                maxValue: maxValue,
                maxHeight: chartHeight,
                label: _weekdayLabels[
                    now.subtract(Duration(days: dailyTotals.length - 1 - i)).weekday - 1],
                isToday: i == dailyTotals.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({
    required this.value,
    required this.maxValue,
    required this.maxHeight,
    required this.label,
    required this.isToday,
  });

  final int value;
  final int maxValue;
  final double maxHeight;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final targetHeight = maxHeight * (value / maxValue).clamp(0.05, 1.0);
    final color = isToday
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetHeight),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, height, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
