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

    // 設定画面以外
    if (selectedIndex != 4 && selectedIndex != 5) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.music_note_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
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
            tooltip: AppLocalizations.of(context)!.settings,
          ),
        ],
      );
    } else {
      // 設定またはメトロノーム画面
      return AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        title: Text(
          tabNames[selectedIndex], // 現在のタブ名を表示
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 戻るボタン
          },
        ),
      );
    }
  }
}
