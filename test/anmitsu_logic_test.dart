import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/Logic/anmitsu_logic.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/Logic/anmitsu_models.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/UI/judgment_diagram.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/anmitsu_checker_page.dart';
import 'package:musical_note_calculator/ParamData/judgment.dart';
import 'package:musical_note_calculator/ParamData/settings_model.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  const earlier = JudgmentPreset(
    id: 'earlier',
    game: 'Test',
    label: 'Earlier preset',
    earlyMs: 10,
    lateMs: 90,
  );
  const later = JudgmentPreset(
    id: 'later',
    game: 'Test',
    label: 'Later preset',
    earlyMs: 70,
    lateMs: 20,
  );
  const selection = SelectionSnapshot(
    game: 'Test',
    presets: [earlier, later],
    earlyPreset: earlier,
    latePreset: later,
  );

  group('AnmitsuLogic.calculateResult', () {
    test('uses the earlier late and later early windows', () {
      final result = AnmitsuLogic.calculateResult(
        selection: selection,
        bpm: 120,
        noteType: 16,
        isDotted: false,
      );

      expect(result, isNotNull);
      expect(result!.noteLengthMs, 125);
      expect(result.relevantWindowTotal, 160);
      expect(result.overlapDurationMs, 35);
      expect(result.anmituValue, 17.5);
      expect(result.isPossible, isTrue);
    });

    test('reports the gap when the judgment windows do not meet', () {
      const narrow = JudgmentPreset(
        id: 'narrow',
        game: 'Test',
        label: 'Narrow',
        earlyMs: 20,
        lateMs: 20,
      );
      const narrowSelection = SelectionSnapshot(
        game: 'Test',
        presets: [narrow],
        earlyPreset: narrow,
        latePreset: narrow,
      );

      final result = AnmitsuLogic.calculateResult(
        selection: narrowSelection,
        bpm: 120,
        noteType: 16,
        isDotted: false,
      )!;

      expect(result.overlapDurationMs, -85);
      expect(result.shortfallMs, 85);
      expect(result.isPossible, isFalse);
    });

    test('rejects non-finite and invalid numeric input', () {
      for (final values in [
        (double.nan, 16.0),
        (double.infinity, 16.0),
        (120.0, double.nan),
        (120.0, double.infinity),
        (0.0, 16.0),
        (120.0, 0.0),
      ]) {
        expect(
          AnmitsuLogic.calculateResult(
            selection: selection,
            bpm: values.$1,
            noteType: values.$2,
            isDotted: false,
          ),
          isNull,
        );
      }
    });
  });

  group('AnmitsuLogic.resolveSelection', () {
    test('falls back to a valid game and preset', () {
      final result = AnmitsuLogic.resolveSelection(
        const {
          'Test': [earlier, later],
        },
        'Missing',
        'missing-earlier',
        'missing-later',
      );

      expect(result.game, 'Test');
      expect(result.earlyPreset, earlier);
      expect(result.latePreset, earlier);
    });
  });

  testWidgets('renders the redesigned compact checker', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bpmController = TextEditingController(text: '120');
    final bpmFocusNode = FocusNode();
    addTearDown(bpmController.dispose);
    addTearDown(bpmFocusNode.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsModel(),
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnmituCheckerPage(
            bpmController: bpmController,
            bpmFocusNode: bpmFocusNode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('餡蜜チェッカー'), findsOneWidget);
    expect(find.text('音符の分母'), findsOneWidget);
    expect(find.text('1/16'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows results and the diagram together on a wide layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bpmController = TextEditingController(text: '120');
    final bpmFocusNode = FocusNode();
    addTearDown(bpmController.dispose);
    addTearDown(bpmFocusNode.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsModel(),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnmituCheckerPage(
            bpmController: bpmController,
            bpmFocusNode: bpmFocusNode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JudgmentDiagram), findsOneWidget);
    expect(find.text('Usable overlap'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
