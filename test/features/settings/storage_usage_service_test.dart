import 'dart:io';

import 'package:calisthenics_rpg/features/settings/data/storage_usage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'soma o tamanho real dos arquivos existentes, ignora ausentes',
    () async {
      final dir = await Directory.systemTemp.createTemp('storage_usage_');
      addTearDown(() => dir.delete(recursive: true));

      await File(
        '${dir.path}/calisthenics_rpg.sqlite',
      ).writeAsBytes(List.filled(1000, 0));
      // calisthenics_rpg_settings.json não existe: deve contar como 0, não
      // falhar.

      final total = await StorageUsageService().totalBytes(
        directoryProvider: () async => dir,
      );

      expect(total, 1000);
    },
  );

  test('formatBytes usa a unidade legível mais próxima', () {
    expect(formatBytes(500), '500 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
  });
}
