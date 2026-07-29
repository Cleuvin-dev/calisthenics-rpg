import 'package:flutter/material.dart';

/// Navegação inferior da tela de execução (seção 6 do pedido do
/// usuário): pular série, voltar ao exercício anterior e avançar. "Anterior"
/// nunca apaga séries já salvas (só move o índice local de exibição, o
/// histórico vive no banco por sessão+exercício). "Próximo" fica
/// desabilitado até a regra da sessão permitir avançar (todas as séries
/// do exercício atual registradas); no último exercício, o rótulo vira
/// "Finalizar treino".
class ExerciseBottomNavigation extends StatelessWidget {
  const ExerciseBottomNavigation({
    super.key,
    required this.onSkipSet,
    required this.onPrevious,
    required this.onNext,
    required this.isLastExercise,
  });

  final VoidCallback? onSkipSet;
  final VoidCallback? onPrevious;

  /// `null` quando a regra da sessão ainda não permite avançar (nem
  /// todas as séries do exercício atual foram registradas).
  final VoidCallback? onNext;
  final bool isLastExercise;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSkipSet,
            child: const Text('Pular série'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onPrevious,
            child: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onNext,
            child: Text(isLastExercise ? 'Finalizar treino' : 'Próximo'),
          ),
        ),
      ],
    );
  }
}
