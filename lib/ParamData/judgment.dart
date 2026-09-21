import 'dart:math';

/// 音楽ゲームの判定幅プリセット
class JudgmentPreset {
  final String id;
  final String game;
  final String label;
  final double earlyMs;
  final double lateMs;
  final bool isCustom;

  const JudgmentPreset({
    required this.id,
    required this.game,
    required this.label,
    required this.earlyMs,
    required this.lateMs,
    this.isCustom = false,
  }) : assert(earlyMs >= 0),
       assert(lateMs >= 0);

  double get totalWindowMs => earlyMs + lateMs;

  Map<String, dynamic> toJson() => {
    'id': id,
    'game': game,
    'label': label,
    'earlyMs': earlyMs,
    'lateMs': lateMs,
    'isCustom': isCustom,
  };

  factory JudgmentPreset.fromJson(Map<String, dynamic> json) => JudgmentPreset(
    id: json['id'] as String,
    game: json['game'] as String,
    label: json['label'] as String,
    earlyMs: (json['earlyMs'] as num).toDouble(),
    lateMs: (json['lateMs'] as num).toDouble(),
    isCustom: json['isCustom'] as bool? ?? true,
  );

  JudgmentPreset copyWith({
    String? id,
    String? game,
    String? label,
    double? earlyMs,
    double? lateMs,
    bool? isCustom,
  }) {
    return JudgmentPreset(
      id: id ?? this.id,
      game: game ?? this.game,
      label: label ?? this.label,
      earlyMs: earlyMs ?? this.earlyMs,
      lateMs: lateMs ?? this.lateMs,
      isCustom: isCustom ?? this.isCustom,
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

const List<JudgmentPreset> defaultJudgmentPresets = [
  JudgmentPreset(
    id: 'proseca_white_notes',
    game: 'プロセカ',
    label: '白 ノーツ',
    earlyMs: 41.6,
    lateMs: 41.6,
  ),
  JudgmentPreset(
    id: 'proseca_green_long_start',
    game: 'プロセカ',
    label: '緑 ロング始点',
    earlyMs: 41.6,
    lateMs: 41.6,
  ),
  JudgmentPreset(
    id: 'proseca_red_flick',
    game: 'プロセカ',
    label: '赤 フリック',
    earlyMs: 41.6,
    lateMs: 41.6,
  ),
  JudgmentPreset(
    id: 'proseca_yellow_notes',
    game: 'プロセカ',
    label: '黄 ノーツ',
    earlyMs: 55.0,
    lateMs: 55.0,
  ),
  JudgmentPreset(
    id: 'proseca_yellow_long_start',
    game: 'プロセカ',
    label: '黄 ロング始点',
    earlyMs: 55.0,
    lateMs: 55.0,
  ),
  JudgmentPreset(
    id: 'proseca_yellow_flick',
    game: 'プロセカ',
    label: '黄 フリック',
    earlyMs: 58.3,
    lateMs: 58.3,
  ),
  JudgmentPreset(
    id: 'proseca_green_long_end',
    game: 'プロセカ',
    label: '緑 ロング終点',
    earlyMs: 58.3,
    lateMs: 66.6,
  ),
  JudgmentPreset(
    id: 'proseca_green_long_end_flick',
    game: 'プロセカ',
    label: '緑 終点フリック',
    earlyMs: 58.3,
    lateMs: 66.6,
  ),
  JudgmentPreset(
    id: 'proseca_yellow_long_end',
    game: 'プロセカ',
    label: '黄 ロング終点',
    earlyMs: 58.3,
    lateMs: 66.6,
  ),
  JudgmentPreset(
    id: 'proseca_yellow_long_end_flick',
    game: 'プロセカ',
    label: '黄 終点フリック',
    earlyMs: 58.3,
    lateMs: 66.6,
  ),
  JudgmentPreset(
    id: 'yumeste_perfect_plus',
    game: 'ユメステ',
    label: 'PERFECT+',
    earlyMs: 25.0,
    lateMs: 25.0,
  ),
  JudgmentPreset(
    id: 'yumeste_perfect',
    game: 'ユメステ',
    label: 'PERFECT',
    earlyMs: 40.0,
    lateMs: 40.0,
  ),
  JudgmentPreset(
    id: 'garupa_perfect',
    game: 'ガルパ',
    label: 'PERFECT',
    earlyMs: 41.67,
    lateMs: 41.67,
  ),
  JudgmentPreset(
    id: 'd4dj_internal_perfect',
    game: 'D4DJ グルミク',
    label: 'PERFECT (内部)',
    earlyMs: 25.0,
    lateMs: 25.0,
  ),
  JudgmentPreset(
    id: 'd4dj_perfect',
    game: 'D4DJ グルミク',
    label: 'PERFECT',
    earlyMs: 50.0,
    lateMs: 50.0,
  ),
  JudgmentPreset(
    id: 'deemo_default',
    game: 'Deemo',
    label: 'Default',
    earlyMs: 50.0,
    lateMs: 50.0,
  ),
  JudgmentPreset(
    id: 'arcaea_internal_pure',
    game: 'Arcaea',
    label: 'PURE (内部)',
    earlyMs: 25.0,
    lateMs: 25.0,
  ),
  JudgmentPreset(
    id: 'arcaea_pure',
    game: 'Arcaea',
    label: 'PURE',
    earlyMs: 50.0,
    lateMs: 50.0,
  ),
  JudgmentPreset(
    id: 'takumi_rainbow_just',
    game: 'TAKUMI³',
    label: '虹JUST',
    earlyMs: 40.0,
    lateMs: 40.0,
  ),
  JudgmentPreset(
    id: 'takumi_just',
    game: 'TAKUMI³',
    label: 'JUST',
    earlyMs: 60.0,
    lateMs: 60.0,
  ),
  JudgmentPreset(
    id: 'cytus_tp_perfect',
    game: 'Cytus/Cytus II',
    label: 'TP PERFECT',
    earlyMs: 70.0,
    lateMs: 70.0,
  ),
  JudgmentPreset(
    id: 'kalpa_perfect',
    game: 'KALPA',
    label: 'PERFECT',
    earlyMs: 67.0,
    lateMs: 67.0,
  ),
  JudgmentPreset(
    id: 'phigros_normal_perfect',
    game: 'Phigros',
    label: '通常 Perfect',
    earlyMs: 80.0,
    lateMs: 80.0,
  ),
  JudgmentPreset(
    id: 'phigros_challenge_perfect',
    game: 'Phigros',
    label: '課題 Perfect',
    earlyMs: 40.0,
    lateMs: 40.0,
  ),
  JudgmentPreset(
    id: 'mltd_om_perfect',
    game: 'ミリシタ',
    label: 'PERFECT (OM)',
    earlyMs: 28.0,
    lateMs: 28.0,
  ),
  JudgmentPreset(
    id: 'mltd_mm_perfect',
    game: 'ミリシタ',
    label: 'PERFECT (MM以下)',
    earlyMs: 50.0,
    lateMs: 50.0,
  ),
  JudgmentPreset(
    id: 'deresute_perfect',
    game: 'デレステ',
    label: 'PERFECT (Mas以上)',
    earlyMs: 70.0,
    lateMs: 70.0,
  ),
];
