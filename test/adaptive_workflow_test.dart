import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/anmitsu_checker_page.dart';
import 'package:musical_note_calculator/Page/Metronome/metronome_content.dart';
import 'package:musical_note_calculator/Page/Settings/settings_page.dart';
import 'package:musical_note_calculator/ParamData/settings_model.dart';
import 'package:musical_note_calculator/UI/modern_side_bar.dart';
import 'package:musical_note_calculator/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final name in ['metronome', 'metronome_tick']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    EdgeInsets insets = EdgeInsets.zero,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsModel(),
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: insets,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const MyApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('folding retains BPM, checker state, and selected tab', (
    tester,
  ) async {
    await mount(tester, const Size(390, 844));
    final input = find.byType(TextField).first;
    await tester.enterText(input, '180');
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    final state = tester.state<AnmituCheckerPageState>(
      find.byType(AnmituCheckerPage),
    );
    state.noteController.text = '24';
    state.isDotted = true;
    for (final size in [
      const Size(900, 720),
      const Size(720, 390),
      const Size(390, 844),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.state(find.byType(AnmituCheckerPage)), same(state));
      expect(state.noteController.text, '24');
      expect(state.isDotted, isTrue);
      expect(state.bpmController.text, '180');
    }
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('playing metronome survives wide to compact resize', (
    tester,
  ) async {
    await mount(tester, const Size(1000, 760));
    await tester.tap(find.byKey(const ValueKey('metronome-toggle')));
    await tester.pumpAndSettle();
    final state = tester.state<MetronomeContentState>(
      find.byType(MetronomeContent),
    );
    state.startMetronome();
    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.state(find.byType(MetronomeContent)), same(state));
    expect(state.isPlaying, isTrue);
    expect(tester.takeException(), isNull);
    state.stopMetronome();
    await tester.pumpAndSettle();
  });

  for (final size in [
    const Size(320, 700),
    const Size(390, 360),
    const Size(900, 720),
    const Size(1280, 800),
  ]) {
    testWidgets('all tools fit ${size.width}x${size.height}', (tester) async {
      await mount(tester, size);
      for (var index = 0; index < 4; index++) {
        if (find.byType(NavigationBar).evaluate().isNotEmpty) {
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .onDestinationSelected!(index);
        } else {
          tester
              .widget<ModernSideBar>(find.byType(ModernSideBar))
              .onDestinationSelected(index);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tool $index at $size');
      }
    });
  }

  testWidgets('settings fits compact and asymmetric camera safe areas', (
    tester,
  ) async {
    await mount(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await mount(
      tester,
      const Size(900, 720),
      insets: const EdgeInsets.only(left: 20, right: 68, bottom: 24),
    );
    final safeArea = find
        .descendant(
          of: find.byType(SettingsPage),
          matching: find.byType(SafeArea),
        )
        .first;
    final rect = tester.getRect(
      find.descendant(of: safeArea, matching: find.byType(LayoutBuilder)).first,
    );
    expect(rect.left, greaterThanOrEqualTo(20));
    expect(rect.right, lessThanOrEqualTo(832));
    expect(tester.takeException(), isNull);
  });

  testWidgets('asymmetric camera safe area keeps controls within bounds', (
    tester,
  ) async {
    await mount(
      tester,
      const Size(900, 720),
      insets: const EdgeInsets.only(left: 20, right: 68, bottom: 24),
    );
    final rect = tester.getRect(find.byKey(const ValueKey('main-workflow')));
    expect(rect.left, greaterThanOrEqualTo(20));
    expect(rect.right, lessThanOrEqualTo(832));
    expect(tester.takeException(), isNull);
  });
}
