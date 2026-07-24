import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

/// Escolha do usuário ao reabrir o app com uma série por tempo em
/// andamento (SETTINGS_AND_TIMED_EXERCISES.md §13.3: "nunca marcar
/// automaticamente como válida sem confirmação").
enum TimedSetRecoveryChoice { resume, markInterrupted, discard }

/// Diálogo de recuperação: aparece quando `activeTimedSetFor` encontra
/// uma série por tempo que ficou pendente (app fechado, processo morto,
/// tela bloqueada por tempo demais).
Future<TimedSetRecoveryChoice?> showTimedSetRecoveryDialog(
  BuildContext context, {
  required ActiveTimedSetRecord active,
  required String exerciseNamePtBr,
}) {
  final elapsedSeconds = active.activeElapsedMs ~/ 1000;

  return showDialog<TimedSetRecoveryChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sessão por tempo interrompida'),
      content: Text(
        'Você tinha uma série de "$exerciseNamePtBr" em andamento '
        '($elapsedSeconds s de ${active.targetSeconds} s) quando o app '
        'fechou ou a tela bloqueou. O que deseja fazer?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(TimedSetRecoveryChoice.discard),
          child: const Text('Descartar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(
            dialogContext,
          ).pop(TimedSetRecoveryChoice.markInterrupted),
          child: const Text('Registrar como interrompida'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(TimedSetRecoveryChoice.resume),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
