import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UserSettings {
  const UserSettings({
    this.displayName = 'Aventureiro',
    this.highContrast = false,
    this.textScale = 1,
    this.reduceMotion = false,
    this.language = 'pt-BR',
    this.soundEnabled = true,
    this.voiceEnabled = false,
    this.vibrationEnabled = true,
    this.autoStartRest = true,
    this.countdownSeconds = 3,
    this.defaultRestSeconds = 60,
  });

  final String displayName;
  final bool highContrast;
  final double textScale;
  final bool reduceMotion;
  final String language;
  final bool soundEnabled;
  final bool voiceEnabled;
  final bool vibrationEnabled;
  final bool autoStartRest;
  final int countdownSeconds;
  final int defaultRestSeconds;

  UserSettings copyWith({
    String? displayName,
    bool? highContrast,
    double? textScale,
    bool? reduceMotion,
    String? language,
    bool? soundEnabled,
    bool? voiceEnabled,
    bool? vibrationEnabled,
    bool? autoStartRest,
    int? countdownSeconds,
    int? defaultRestSeconds,
  }) => UserSettings(
    displayName: displayName ?? this.displayName,
    highContrast: highContrast ?? this.highContrast,
    textScale: textScale ?? this.textScale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    language: language ?? this.language,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    autoStartRest: autoStartRest ?? this.autoStartRest,
    countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
  );

  Map<String, Object> toJson() => {
    'displayName': displayName,
    'highContrast': highContrast,
    'textScale': textScale,
    'reduceMotion': reduceMotion,
    'language': language,
    'soundEnabled': soundEnabled,
    'voiceEnabled': voiceEnabled,
    'vibrationEnabled': vibrationEnabled,
    'autoStartRest': autoStartRest,
    'countdownSeconds': countdownSeconds,
    'defaultRestSeconds': defaultRestSeconds,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    displayName: json['displayName'] as String? ?? 'Aventureiro',
    highContrast: json['highContrast'] as bool? ?? false,
    textScale: (json['textScale'] as num?)?.toDouble() ?? 1,
    reduceMotion: json['reduceMotion'] as bool? ?? false,
    language: json['language'] as String? ?? 'pt-BR',
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    voiceEnabled: json['voiceEnabled'] as bool? ?? false,
    vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    autoStartRest: json['autoStartRest'] as bool? ?? true,
    countdownSeconds: json['countdownSeconds'] as int? ?? 3,
    defaultRestSeconds: json['defaultRestSeconds'] as int? ?? 60,
  );
}

class SettingsRepository {
  SettingsRepository({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final directory = await _directoryProvider();
    return File(p.join(directory.path, 'calisthenics_rpg_settings.json'));
  }

  Future<UserSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const UserSettings();
    try {
      return UserSettings.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on FormatException {
      return const UserSettings();
    }
  }

  Future<void> save(UserSettings settings) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    final encoded = jsonEncode(settings.toJson());
    await temporary.writeAsString(encoded, flush: true);
    try {
      await temporary.rename(file.path);
    } on FileSystemException {
      // Rename replace-on-existing can be blocked by locks (e.g. AV scanners)
      // on some Windows setups. Fall back to a direct write so a save never
      // silently loses the previous preferences file.
      await file.writeAsString(encoded, flush: true);
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}
