import 'dart:math';

part 'judgment_catalog.dart';

/// Version and limitations of a timing-window reference, not a latency test.
class JudgmentPresetContext {
  final String version;
  final String noteJa;
  final String noteEn;
  final String? checkedOn;

  const JudgmentPresetContext({
    required this.version,
    required this.noteJa,
    required this.noteEn,
    this.checkedOn,
  });

  String describe(String languageCode) => [
    if (version.isNotEmpty) version,
    ?checkedOn,
    languageCode.startsWith('ja') ? noteJa : noteEn,
  ].join(' · ');

  Map<String, dynamic> toJson() => {
    'version': version,
    'noteJa': noteJa,
    'noteEn': noteEn,
    if (checkedOn != null) 'checkedOn': checkedOn,
  };

  factory JudgmentPresetContext.fromJson(Map<String, dynamic> json) =>
      JudgmentPresetContext(
        version: json['version'] as String,
        noteJa: json['noteJa'] as String,
        noteEn: json['noteEn'] as String,
        checkedOn: json['checkedOn'] as String?,
      );
}

/// 音楽ゲームの判定幅プリセット
class JudgmentPreset {
  final String id;
  final String game;
  final String label;
  final double earlyMs;
  final double lateMs;
  final bool isCustom;
  final String? labelEn;
  final JudgmentPresetContext? context;

  const JudgmentPreset({
    required this.id,
    required this.game,
    required this.label,
    required this.earlyMs,
    required this.lateMs,
    this.isCustom = false,
    this.labelEn,
    this.context,
  }) : assert(earlyMs >= 0),
       assert(lateMs >= 0);

  double get totalWindowMs => earlyMs + lateMs;

  String labelFor(String languageCode) =>
      languageCode.startsWith('ja') ? label : labelEn ?? label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'game': game,
    'label': label,
    'earlyMs': earlyMs,
    'lateMs': lateMs,
    'isCustom': isCustom,
    if (labelEn != null) 'labelEn': labelEn,
    if (context != null) 'context': context!.toJson(),
  };

  factory JudgmentPreset.fromJson(Map<String, dynamic> json) => JudgmentPreset(
    id: json['id'] as String,
    game: json['game'] as String,
    label: json['label'] as String,
    earlyMs: (json['earlyMs'] as num).toDouble(),
    lateMs: (json['lateMs'] as num).toDouble(),
    isCustom: json['isCustom'] as bool? ?? true,
    labelEn: json['labelEn'] as String?,
    context: json['context'] == null
        ? null
        : JudgmentPresetContext.fromJson(
            Map<String, dynamic>.from(json['context'] as Map),
          ),
  );

  JudgmentPreset copyWith({
    String? id,
    String? game,
    String? label,
    double? earlyMs,
    double? lateMs,
    bool? isCustom,
    String? labelEn,
    JudgmentPresetContext? context,
  }) {
    return JudgmentPreset(
      id: id ?? this.id,
      game: game ?? this.game,
      label: label ?? this.label,
      earlyMs: earlyMs ?? this.earlyMs,
      lateMs: lateMs ?? this.lateMs,
      isCustom: isCustom ?? this.isCustom,
      labelEn: labelEn ?? this.labelEn,
      context: context ?? this.context,
    );
  }

  factory JudgmentPreset.custom({
    required String game,
    required String label,
    required double earlyMs,
    required double lateMs,
  }) {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(1 << 16);
    return JudgmentPreset(
      id: 'custom_${seed}_$salt',
      game: game,
      label: label,
      earlyMs: earlyMs,
      lateMs: lateMs,
      isCustom: true,
    );
  }
}
