import 'package:flutter/material.dart';
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
    double earlierNoteLateWindow,
    double laterNoteEarlyWindow,
    double noteLengthMs,
  ) {
    final totalWindow = earlierNoteLateWindow + laterNoteEarlyWindow;
    return (totalWindow - noteLengthMs) / 2;
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

    // A simultaneous hit must be late enough for the earlier note and early
    // enough for the later note. The opposite sides of both judgment windows
    // do not participate in their intersection.
    final earlierNoteLateWindow = earlyPreset.lateMs;
    final laterNoteEarlyWindow = latePreset.earlyMs;
    final overlapDurationMs =
        earlierNoteLateWindow + laterNoteEarlyWindow - noteLengthMs;
    final anmituValue = overlapDurationMs / 2;
    final color = getResultColor(anmituValue);

    return AnmituCalcResult(
      gameName: selection.game ?? '',
      earlyPresetLabel: earlyPreset.label,
      latePresetLabel: latePreset.label,
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
