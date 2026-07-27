import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Soma o tamanho real dos arquivos que o app grava localmente — banco de
/// progresso (Drift) e preferências pessoais (JSON) — para a tela de
/// Definição > Dados. Nunca estima ou inventa um valor: arquivo ausente
/// conta como 0 bytes.
class StorageUsageService {
  Future<int> totalBytes({
    Future<Directory> Function()? directoryProvider,
  }) async {
    final dir = await (directoryProvider ?? getApplicationDocumentsDirectory)();
    final files = [
      File(p.join(dir.path, 'calisthenics_rpg.sqlite')),
      File(p.join(dir.path, 'calisthenics_rpg_settings.json')),
    ];
    var total = 0;
    for (final file in files) {
      if (await file.exists()) total += await file.length();
    }
    return total;
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
