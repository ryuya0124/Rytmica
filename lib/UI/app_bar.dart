import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../Page/Settings/settings_page.dart';
import 'pageAnimation.dart';

import 'dart:io';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;

  final List<Widget>? actions;

  const AppBarWidget({
    super.key,
    required this.selectedIndex,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final List<String> tabNames = [
      AppLocalizations.of(context)!.note_spacing,
      AppLocalizations.of(context)!.note_count,
      AppLocalizations.of(context)!.calculator,
      AppLocalizations.of(context)!.anmitu,
      AppLocalizations.of(context)!.metronome,
      AppLocalizations.of(context)!.settings,
    ];

    final colorScheme = Theme.of(context).colorScheme;

    // テキストの色をダークテーマ・ライトテーマに合わせて設定
    final titleTextColor = colorScheme.primary; // タイトルのテキスト色
    // 設定画面以外
    if (selectedIndex != 4 && selectedIndex != 5) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.onPrimary, // 背景色をテーマの onPrimary に
        foregroundColor: colorScheme.primary, // アイコンの色をテーマの primary に
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: titleTextColor), // タイトルのテキスト色
            ),

            // タブレットの場合はタブ名を非表示
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (Platform.isIOS) {
                // iOSの場合
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              } else {
                // iOS以外の場合
                pushPage<void>(
                  context,
                  (BuildContext context) {
                    return const SettingsPage(); // SettingsPageに遷移
                  },
                  name: "/root/settings", // ルート名を設定
                );
              }
            },
            color: colorScheme.primary, // アイコンの色
          ),
        ],
      );
    } else {
      // 設定またはメトロノーム画面
      return AppBar(
        backgroundColor: colorScheme.onPrimary, // 背景色をテーマの onPrimary に
        foregroundColor: colorScheme.primary, // アイコンの色をテーマの primary に
        title: Text(
          tabNames[selectedIndex], // 現在のタブ名を表示
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: titleTextColor), // 設定画面のタイトル色
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 戻るボタン
          },
          color: colorScheme.primary, // 戻るアイコンの色
        ),
      );
    }
  }
}
