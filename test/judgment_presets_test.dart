import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/Logic/anmitsu_logic.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/Logic/anmitsu_models.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/anmitsu_checker_page.dart';
import 'package:musical_note_calculator/ParamData/judgment.dart';
import 'package:musical_note_calculator/ParamData/settings_model.dart';
import 'package:musical_note_calculator/UI/judgment_preset_details.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

JudgmentPreset preset(String id) =>
    defaultJudgmentPresets.singleWhere((preset) => preset.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrects known values without rounding frame fractions in storage', () {
    expect(preset('proseca_white_notes').earlyMs, closeTo(125 / 3, 1e-10));
    expect(preset('proseca_green_long_end').lateMs, closeTo(200 / 3, 1e-10));
    expect(preset('garupa_perfect').earlyMs, closeTo(125 / 3, 1e-10));
    expect(preset('takumi_rainbow_just').earlyMs, closeTo(125 / 3, 1e-10));
    expect(preset('takumi_0').earlyMs, 25);
    expect(preset('d4dj_internal_perfect').label, 'JUST PERFECT');
    expect(preset('yumeste_perfect_plus').label, contains('PERFECT★'));
  });

  test('preserves asymmetric windows instead of averaging them', () {
    expect(preset('arccreate_0').earlyMs, 25);
    expect(preset('arccreate_0').lateMs, 24);
    expect(preset('holodori_normal_1').earlyMs, closeTo(200 / 3, 1e-10));
    expect(preset('holodori_normal_1').lateMs, 50);
    expect(preset('ournotes_end_flick_assist3_1').earlyMs, 98);
    expect(preset('ournotes_end_flick_assist3_1').lateMs, 58);
    expect(preset('ournotes_flick_assist3_1').lateMs, 67);
    expect(preset('proseca_red_flick_1').earlyMs, closeTo(325 / 3, 1e-10));
    expect(preset('proseca_red_flick_1').lateMs, 125);
  });

  test(
    'or-better windows include higher grades across zero/repeated sides',
    () {
      expect(
        preset('shinycolors_slide_end_2').earlyMs,
        closeTo(275 / 3, 1e-10),
      );
      expect(preset('shinycolors_slide_end_2').lateMs, closeTo(200 / 3, 1e-10));
      expect(preset('ournotes_flick_assist0_2').earlyMs, 83);
      expect(preset('ournotes_flick_assist0_2').lateMs, 83);
      expect(preset('ournotes_flick_assist0_2').label, contains('GREAT以上'));
      expect(preset('astrodx_touch_2').earlyMs, 150);
      expect(preset('astrodx_touch_2').lateMs, 250);
    },
  );

  test('challenge references account for frame duration and disclose it', () {
    expect(
      preset('phigros_challenge_perfect').earlyMs,
      closeTo(48 + 1 / 3, 1e-10),
    );
    expect(
      preset('phigros_challenge_120_0').earlyMs,
      closeTo(44 + 1 / 6, 1e-10),
    );
    expect(
      preset('phigros_challenge_perfect').context!.noteJa,
      contains('表示Hz'),
    );
    expect(preset('phigros_normal_perfect').earlyMs, 80);
  });

  test('Phigros BAD-or-better excludes the late MISS region', () {
    expect(preset('phigros_normal_2').earlyMs, 220);
    expect(preset('phigros_normal_2').lateMs, 180);
    expect(
      preset('phigros_challenge_60_2').earlyMs,
      closeTo(148 + 1 / 3, 1e-10),
    );
    expect(preset('phigros_challenge_60_2').lateMs, closeTo(98 + 1 / 3, 1e-10));
    expect(
      preset('phigros_challenge_120_2').lateMs,
      closeTo(94 + 1 / 6, 1e-10),
    );
  });

  test(
    'nested windows cannot produce more overlap than either full window',
    () {
      final narrow = preset('ournotes_normal_assist0_0');
      final wide = preset('ournotes_normal_assist0_4');
      for (final pair in [(narrow, wide), (wide, narrow)]) {
        final result = AnmitsuLogic.calculateResult(
          selection: SelectionSnapshot(
            game: narrow.game,
            presets: [narrow, wide],
            earlyPreset: pair.$1,
            latePreset: pair.$2,
          ),
          bpm: 240,
          noteType: 16,
          isDotted: false,
        )!;
        expect(result.overlapDurationMs, 4);
        expect(result.anmituValue, 2);
        expect(result.overlapEndMs - result.overlapStartMs, 4);
        expect(
          result.overlapDurationMs,
          lessThanOrEqualTo(pair.$1.totalWindowMs),
        );
        expect(
          result.overlapDurationMs,
          lessThanOrEqualTo(pair.$2.totalWindowMs),
        );
      }
    },
  );

  test(
    'chart samples stay separate and release bonuses respect input caps',
    () {
      expect(preset('mltd_thanky_2lane23_6lane123_tap_0').earlyMs, 50);
      expect(
        preset('mltd_bnthtr_6lane2_tap_0').earlyMs,
        closeTo(100 / 3, 1e-10),
      );
      expect(
        preset('mltd_thanky_2lane23_6lane123_release_2').earlyMs,
        closeTo(550 / 3, 1e-10),
      );
      expect(
        preset('mltd_thanky_2lane23_6lane123_tap_0').context!.noteJa,
        contains('全曲共通ではありません'),
      );
      expect(
        defaultJudgmentPresets.any((p) => p.id == 'mltd_om_perfect'),
        isFalse,
      );
      expect(
        defaultJudgmentPresets.any((p) => p.id == 'mltd_mm_perfect'),
        isFalse,
      );
    },
  );

  test('mode-specific source formulas retain distinct values', () {
    expect(preset('malody_key_0_0').earlyMs, 65);
    expect(preset('malody_key_4_0').earlyMs, 29);
    expect(preset('malody_key_2_2').earlyMs, 130);
    expect(preset('malody_key_fair_2_2').earlyMs, 120);
    expect(preset('malody_lovelive_4_2').earlyMs, 128);
    expect(preset('osu_standard_od5_0').earlyMs, 49.5);
    expect(preset('osu_standard_od10_0').earlyMs, 19.5);
    expect(preset('osu_taiko_od10_1').earlyMs, 49.5);
    expect(preset('osu_mania_od5_0').earlyMs, 19.5);
    expect(preset('osu_mania_od10_0').earlyMs, 13.5);
  });

  test(
    'does not invent fixed windows or include failure deadlines as grades',
    () {
      expect(
        defaultJudgmentPresets.any(
          (p) => p.game == 'Sonolus' || p.game == 'Piano Tiles 2',
        ),
        isFalse,
      );
      for (final p in defaultJudgmentPresets) {
        expect(p.label, isNot(contains('MISS')));
        expect(p.label, isNot(contains('LOST')));
        expect(p.label, isNot(contains('EXCELLENT')));
        expect(p.label, isNot(contains('POOR')));
        expect(p.earlyMs.isFinite && p.earlyMs > 0, isTrue, reason: p.id);
        expect(p.lateMs.isFinite && p.lateMs > 0, isTrue, reason: p.id);
      }
      expect(
        defaultJudgmentPresets.map((p) => p.id).toSet().length,
        defaultJudgmentPresets.length,
      );
      expect(preset('deemo_default').context!.checkedOn, isNull);
      expect(preset('deemo_default').context!.noteJa, contains('未確認'));
    },
  );

  test('catalog ordering starts with the highest grade rather than BAD', () {
    final grouped = SettingsModel().judgmentPresetsByGame;
    expect(grouped['ガルパ']!.first.id, 'garupa_perfect');
    expect(grouped['ユメステ']!.first.id, 'yumeste_perfect_plus');
    expect(grouped['Phigros']!.first.id, 'phigros_normal_perfect');
  });

  test('old custom JSON and visibility preferences remain usable', () async {
    final legacyJson = {
      'id': 'custom_saved',
      'game': 'My game',
      'label': 'My judgment',
      'earlyMs': 12.5,
      'lateMs': 27.0,
    };
    SharedPreferences.setMockInitialValues({
      'customJudgmentPresets': [jsonEncode(legacyJson)],
      'hiddenJudgmentPresetIds': ['garupa_perfect', 'proseca_white_notes'],
    });
    final settings = SettingsModel();
    await settings.initialize();
    final custom = settings.findJudgmentPresetById('custom_saved')!;
    expect(custom.earlyMs, 12.5);
    expect(custom.lateMs, 27);
    expect(custom.labelFor('en'), 'My judgment');
    expect(custom.isCustom, isTrue);
    expect(settings.isPresetHidden('garupa_perfect'), isTrue);
    expect(
      settings.visibleJudgmentPresets.any((p) => p.id == 'garupa_perfect'),
      isFalse,
    );
    final reference = preset('arccreate_0');
    final restored = JudgmentPreset.fromJson(
      jsonDecode(jsonEncode(reference.toJson())),
    );
    expect(restored.toJson(), reference.toJson());
    expect(restored.copyWith(lateMs: 23).context, restored.context);
  });

  test('uses actual asymmetric references in overlap calculation', () {
    final arc = preset('arccreate_0');
    final result = AnmitsuLogic.calculateResult(
      selection: SelectionSnapshot(
        game: arc.game,
        presets: [arc],
        earlyPreset: arc,
        latePreset: arc,
      ),
      bpm: 1250,
      noteType: 4,
      isDotted: false,
    )!;
    expect(result.noteLengthMs, 48);
    expect(result.relevantWindowTotal, 49);
    expect(result.overlapDurationMs, 1);
  });

  for (final locale in ['ja', 'en']) {
    testWidgets('reference conditions fit compact large-text UI in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bpm = TextEditingController(text: '120');
      final focus = FocusNode();
      addTearDown(bpm.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SettingsModel(),
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: AnmituCheckerPage(bpmController: bpm, bpmFocusNode: focus),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('game-Arcaea')),
      );
      game.onChanged!('ミリシタ');
      await tester.pumpAndSettle();
      expect(find.byType(JudgmentPresetDetails), findsNWidgets(2));
      expect(
        find.textContaining(
          locale == 'ja' ? '全曲共通ではありません' : 'not universal across songs',
        ),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
