import 'dart:io';

import 'package:calisthenics_rpg/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
