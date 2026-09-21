import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 520;

    // ナビゲーションバーを透明に設定
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent, // ナビゲーションバーを透明に
        systemNavigationBarDividerColor: Colors.transparent, // 区切り線も透明に
        systemNavigationBarIconBrightness:
            colorScheme.surface.computeLuminance() > 0.5
            ? Brightness
                  .dark // 背景が明るい場合
            : Brightness.light, // 背景が暗い場合
      ),
    );

    // 選択時の背景色に基づいて適切なアイコンの色を決定
    Color getSelectedIconColor() {
      return colorScheme.primaryContainer.computeLuminance() > 0.5
          ? colorScheme
                .onPrimaryContainer // 背景が明るい場合
          : colorScheme.primary; // 背景が暗い場合
    }

    return NavigationBar(
      selectedIndex: selectedIndex, // 現在選択されているタブのインデックス
      onDestinationSelected: onTabSelected, // タブ選択時のコールバック
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.music_note, color: colorScheme.onSurface), // 未選択時の色
          selectedIcon: Icon(
            Icons.music_note,
            color: getSelectedIconColor(),
          ), // 選択時の色
          label: AppLocalizations.of(context)!.note_spacing, // ラベル
        ),
        NavigationDestination(
          icon: Icon(
            Icons.music_note_outlined,
            color: colorScheme.onSurface,
          ), // 未選択時の色
          selectedIcon: Icon(
            Icons.music_note_outlined,
            color: getSelectedIconColor(),
          ), // 選択時の色
          label: AppLocalizations.of(context)!.note_count, // ラベル
        ),
        NavigationDestination(
          icon: Icon(Icons.calculate, color: colorScheme.onSurface), // 未選択時の色
          selectedIcon: Icon(
            Icons.calculate,
            color: getSelectedIconColor(),
          ), // 選択時の色
          label: AppLocalizations.of(context)!.calculator, // ラベル
        ),
        NavigationDestination(
          icon: Icon(
            Icons.music_note_sharp,
            color: colorScheme.onSurface,
          ), // 未選択時の色
          selectedIcon: Icon(
            Icons.music_note_sharp,
            color: getSelectedIconColor(),
          ), // 選択時の色
          label: AppLocalizations.of(context)!.anmitu, // ラベル
        ),
      ],
      backgroundColor: colorScheme.surface, // ナビゲーションバーの背景色
      indicatorColor: colorScheme.primaryContainer, // 選択中インジケータの色
      // Long localized labels wrap on compact and folded displays. Keep the
      // selected label visible while preserving all four touch targets.
      labelBehavior: isNarrow
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}
