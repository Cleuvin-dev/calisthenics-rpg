import 'dart:io';

import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('preferências pessoais persistem separadas do progresso', () async {
    final directory = await Directory.systemTemp.createTemp('rpg_settings_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = SettingsRepository(
      directoryProvider: () async => directory,
    );

    const expected = UserSettings(
      displayName: 'Atleta',
      highContrast: true,
      textScale: 1.3,
      reduceMotion: true,
      soundEnabled: false,
      vibrationEnabled: false,
    );
    await repository.save(expected);
    final loaded = await repository.load();

    expect(loaded.displayName, 'Atleta');
    expect(loaded.highContrast, isTrue);
    expect(loaded.textScale, 1.3);
    expect(loaded.reduceMotion, isTrue);
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.vibrationEnabled, isFalse);
  });

  test('gravações consecutivas sobrescrevem o arquivo sem perder dados', () async {
    final directory = await Directory.systemTemp.createTemp('rpg_settings_');
    addTearDown(() => directory.delete(recursive: true));
    final repository = SettingsRepository(
      directoryProvider: () async => directory,
    );

    for (var i = 0; i < 5; i++) {
      await repository.save(UserSettings(displayName: 'Atleta $i'));
    }

    final loaded = await repository.load();
    expect(loaded.displayName, 'Atleta 4');

    final settingsFile = File(
      p.join(directory.path, 'calisthenics_rpg_settings.json'),
    );
    final tmpFile = File('${settingsFile.path}.tmp');
    expect(await settingsFile.exists(), isTrue);
    expect(await tmpFile.exists(), isFalse);
  });
}
