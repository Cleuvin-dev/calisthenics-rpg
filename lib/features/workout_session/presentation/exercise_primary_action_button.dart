import 'package:flutter/material.dart';

/// Botão principal verde-neon da tela de execução — o rótulo é sempre
/// decidido por quem chama a partir do estado real (INICIAR/PAUSAR/
/// CONTINUAR/CONCLUIR SÉRIE/CONCLUIR EXERCÍCIO), nunca um texto fixo
/// "CONCLUÍDO" enquanto a ação ainda não aconteceu (seção 6 do pedido do
/// usuário).
class ExercisePrimaryActionButton extends StatelessWidget {
  const ExercisePrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
        onPressed: onPressed,
        child: Text(label.toUpperCase()),
      ),
    );
  }
}
