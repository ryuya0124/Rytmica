import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../UI/app_bar.dart';

import 'UI/display_settings_section.dart';
import 'UI/note_settings_section.dart';
import 'UI/judgment_settings_section.dart';
import 'UI/advanced_settings_section.dart';
import 'UI/app_info_section.dart';

// 設定カテゴリの定義
class SettingsCategory {
  final String id;
  final String titleKey;
  final IconData icon;

  const SettingsCategory({
    required this.id,
    required this.titleKey,
    required this.icon,
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  // 選択中のカテゴリインデックス（マスターディテールUI用）
  int _selectedCategoryIndex = 0;

  // カテゴリ定義リスト
  static const List<SettingsCategory> _categories = [
    SettingsCategory(
      id: 'display',
      titleKey: 'display_settings',
      icon: Icons.display_settings_rounded,
    ),
    SettingsCategory(
      id: 'notes',
      titleKey: 'note_settings',
      icon: Icons.music_note_rounded,
    ),
    SettingsCategory(
      id: 'judgment',
      titleKey: 'judgment_presets',
      icon: Icons.timer_outlined,
    ),
    SettingsCategory(
      id: 'advanced',
      titleKey: 'advanced_settings',
      icon: Icons.tune_rounded,
    ),
    SettingsCategory(
      id: 'about',
      titleKey: 'about_app',
      icon: Icons.info_outline_rounded,
    ),
  ];

  final int _selectedIndex = 5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 他の部分をタップしたときにフォーカスを外す
      },
      child: Scaffold(
        appBar: AppBarWidget(selectedIndex: _selectedIndex),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // 800dp以上でマスターディテールレイアウト
            final isWideScreen = constraints.maxWidth >= 800;

            if (isWideScreen) {
              return Row(
                children: [
                  // 左側：カテゴリナビゲーション
                  _buildCategoryNavigation(context, colorScheme, loc),
                  // 区切り線
                  VerticalDivider(
                    thickness: 1,
                    width: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  // 右側：選択したカテゴリの詳細
                  Expanded(
                    child: _buildCategoryDetail(context, colorScheme, loc),
                  ),
                ],
              );
            }

            // 小画面: 従来の縦並びレイアウト
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DisplaySettingsSection(),
                      SizedBox(height: 8),
                      NoteSettingsSection(),
                      SizedBox(height: 8),
                      JudgmentSettingsSection(),
                      SizedBox(height: 8),
                      AdvancedSettingsSection(),
                      SizedBox(height: 8),
                      AppInfoSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // カテゴリナビゲーション（左側）
  Widget _buildCategoryNavigation(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = index == _selectedCategoryIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                selected: isSelected,
                selectedTileColor: colorScheme.secondaryContainer.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  category.icon,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _getCategoryTitle(loc, category.titleKey),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // カテゴリタイトルを取得するヘルパーメソッド
  String _getCategoryTitle(AppLocalizations loc, String titleKey) {
    switch (titleKey) {
      case 'display_settings':
        return loc.display_settings;
      case 'note_settings':
        return loc.note_settings;
      case 'judgment_presets':
        return loc.judgment_presets;
      case 'advanced_settings':
        return loc.advanced_settings;
      case 'about_app':
        return loc.about_app;
      default:
        return titleKey;
    }
  }

  // カテゴリ詳細（右側）
  Widget _buildCategoryDetail(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: _buildSelectedCategoryContent(context, colorScheme),
        ),
      ),
    );
  }

  // 選択されたカテゴリに応じたコンテンツを返す
  Widget _buildSelectedCategoryContent(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final category = _categories[_selectedCategoryIndex];

    switch (category.id) {
      case 'display':
        return const DisplaySettingsSection();
      case 'notes':
        return const NoteSettingsSection();
      case 'judgment':
        return const JudgmentSettingsSection();
      case 'advanced':
        return const AdvancedSettingsSection();
      case 'about':
        return const AppInfoSection();
      default:
        return const SizedBox.shrink();
    }
  }
}
