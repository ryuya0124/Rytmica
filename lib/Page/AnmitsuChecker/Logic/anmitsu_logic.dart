import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../ParamData/judgment.dart';
import '../../../ParamData/notes.dart';
import 'anmitsu_models.dart';

class AnmitsuLogic {
  static Color getResultColor(double value) {
    if (value <= 0) return Colors.red;
    if (value <= 10) return Colors.orange;
    if (value <= 25) return Colors.amber;
    if (value < 40) return Colors.yellow;
    if (value < 50) return Colors.green;
    return Colors.blue;
  }

  static String getResultText(BuildContext context, double value) {
    if (value <= 0) return AppLocalizations.of(context)!.impossible;
    if (value <= 10) return AppLocalizations.of(context)!.veryHard;
    if (value <= 25) return AppLocalizations.of(context)!.hard;
    if (value < 40) return AppLocalizations.of(context)!.manageable;
    if (value < 50) return AppLocalizations.of(context)!.easy;
    return AppLocalizations.of(context)!.veryEasy;
  }

  static double calculateAnmitsuValue(
    double earlierNoteEarlyWindow,
    double earlierNoteLateWindow,
    double laterNoteEarlyWindow,
    double laterNoteLateWindow,
    double noteLengthMs,
  ) {
    final start = math.max(
      -earlierNoteEarlyWindow,
      noteLengthMs - laterNoteEarlyWindow,
    );
    final end = math.min(
      earlierNoteLateWindow,
      noteLengthMs + laterNoteLateWindow,
    );
    return (end - start) / 2;
  }

  static SelectionSnapshot resolveSelection(
    Map<String, List<JudgmentPreset>> grouped,
    String? selectedGame,
    String? selectedEarlyPresetId,
    String? selectedLatePresetId, {
    bool syncState = false,
    Function(String?, JudgmentPreset?, JudgmentPreset?)? onSync,
  }) {
    if (grouped.isEmpty) {
      if (syncState && onSync != null) {
        onSync(null, null, null);
      }
      return const SelectionSnapshot(
        game: null,
        presets: [],
        earlyPreset: null,
        latePreset: null,
      );
    }

    final keys = grouped.keys.toList();
    final resolvedGame =
        (selectedGame != null && grouped.containsKey(selectedGame))
        ? selectedGame
        : keys.first;
    final presets = grouped[resolvedGame] ?? [];

    JudgmentPreset? resolvedEarly;
    JudgmentPreset? resolvedLate;
    if (presets.isNotEmpty) {
      resolvedEarly =
          _findPresetById(presets, selectedEarlyPresetId) ?? presets.first;
      resolvedLate =
          _findPresetById(presets, selectedLatePresetId) ?? resolvedEarly;
    }

    if (syncState &&
        onSync != null &&
        (resolvedGame != selectedGame ||
            resolvedEarly?.id != selectedEarlyPresetId ||
            resolvedLate?.id != selectedLatePresetId)) {
      onSync(resolvedGame, resolvedEarly, resolvedLate);
    }

    return SelectionSnapshot(
      game: resolvedGame,
      presets: presets,
      earlyPreset: resolvedEarly,
      latePreset: resolvedLate ?? resolvedEarly,
    );
  }

  static JudgmentPreset? _findPresetById(
    List<JudgmentPreset> presets,
    String? presetId,
  ) {
    if (presetId == null) return null;
    for (final preset in presets) {
      if (preset.id == presetId) {
        return preset;
      }
    }
    return null;
  }

  static AnmituCalcResult? calculateResult({
    required SelectionSnapshot selection,
    required double bpm,
    required double noteType,
    required bool isDotted,
    String languageCode = 'ja',
  }) {
    final earlyPreset = selection.earlyPreset;
    final latePreset = selection.latePreset ?? earlyPreset;

    if (earlyPreset == null ||
        latePreset == null ||
        !bpm.isFinite ||
        !noteType.isFinite ||
        bpm <= 0 ||
        noteType <= 0) {
      return null;
    }

    final quarterNoteLengthMs = 60000.0 / bpm;
    final noteLengthMs = calculateNoteLength(
      quarterNoteLengthMs,
      noteType,
      isDotted: isDotted,
    );
    if (!quarterNoteLengthMs.isFinite ||
        !noteLengthMs.isFinite ||
        noteLengthMs <= 0) {
      return null;
    }

    // Intersect both complete intervals: either window can contain the other.
    // Using only the inward-facing sides overstates overlap in that case.
    final earlierNoteLateWindow = earlyPreset.lateMs;
    final laterNoteEarlyWindow = latePreset.earlyMs;
    final anmituValue = calculateAnmitsuValue(
      earlyPreset.earlyMs,
      earlierNoteLateWindow,
      laterNoteEarlyWindow,
      latePreset.lateMs,
      noteLengthMs,
    );
    final overlapDurationMs = anmituValue * 2;
    final color = getResultColor(anmituValue);

    return AnmituCalcResult(
      gameName: selection.game ?? '',
      earlyPresetLabel: earlyPreset.labelFor(languageCode),
      latePresetLabel: latePreset.labelFor(languageCode),
      earlierNoteEarlyWindow: earlyPreset.earlyMs,
      earlierNoteLateWindow: earlierNoteLateWindow,
      laterNoteEarlyWindow: laterNoteEarlyWindow,
      laterNoteLateWindow: latePreset.lateMs,
      noteLengthMs: noteLengthMs,
      overlapDurationMs: overlapDurationMs,
      anmituValue: anmituValue,
      color: color,
    );
  }
}
