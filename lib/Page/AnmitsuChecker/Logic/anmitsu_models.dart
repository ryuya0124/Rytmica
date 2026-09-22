import 'package:flutter/material.dart';

import '../../../ParamData/judgment.dart';

class ResultRow {
  final String title;
  final String value;
  final Color? valueColor;

  const ResultRow({
    required this.title,
    required this.value,
    this.valueColor,
  });
}

class SelectionSnapshot {
  final String? game;
  final List<JudgmentPreset> presets;
  final JudgmentPreset? earlyPreset;
  final JudgmentPreset? latePreset;

  const SelectionSnapshot({
    required this.game,
    required this.presets,
    required this.earlyPreset,
    required this.latePreset,
  });
}

/// 計算結果データを保持するクラス
class AnmituCalcResult {
  final String gameName;
  final String earlyPresetLabel;
  final String latePresetLabel;
  final double earlierNoteEarlyWindow;
  final double earlierNoteLateWindow;
  final double laterNoteEarlyWindow;
  final double laterNoteLateWindow;
  final double noteLengthMs;
  final double overlapDurationMs;
  final double anmituValue;
  final Color color;

  const AnmituCalcResult({
    required this.gameName,
    required this.earlyPresetLabel,
    required this.latePresetLabel,
    required this.earlierNoteEarlyWindow,
    required this.earlierNoteLateWindow,
    required this.laterNoteEarlyWindow,
    required this.laterNoteLateWindow,
    required this.noteLengthMs,
    required this.overlapDurationMs,
    required this.anmituValue,
    required this.color,
  });

  bool get isPossible => overlapDurationMs > 0;

  double get relevantWindowTotal =>
      earlierNoteLateWindow + laterNoteEarlyWindow;

  double get shortfallMs => overlapDurationMs < 0 ? -overlapDurationMs : 0;
}
