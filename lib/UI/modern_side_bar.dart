import 'package:flutter/material.dart';

class ModernSideBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ModernSideBarItem> destinations;
  final bool isExtended;

  const ModernSideBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 拡張時は幅広、通常時はアイコンのみの幅
    final width = isExtended ? 240.0 : 88.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubicEmphasized,
      width: width,
      height: double.infinity,
      clipBehavior: Clip.hardEdge, // 遷移中のオーバーフローをクリップ
      decoration: BoxDecoration(
        color: colorScheme.surface, // 背景色
      ),
      child: SafeArea(
        right: false, // 右側はコンテンツに続くためSafeArea不要
        child: Column(
          children: [
            const SizedBox(height: 32), // 上部余白
            // リストアイテム
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      for (int i = 0; i < destinations.length; i++)
                        _buildItem(context, i),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = destinations[index];
    final isSelected = index == selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;

    // アニメーション用カラー
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : const Color(0x00000000); // 透明
    final iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final textColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(16),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            clipBehavior: Clip.hardEdge, // 遷移中のオーバーフローをクリップ
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              // 選択時にわずかなボーダーを表示してもお洒落かもしれないが、
              // 今回は背景色（Container）で強調するMaterial 3スタイル
            ),
            padding: EdgeInsets.symmetric(
              vertical: isExtended ? 16.0 : 8.0, // アイコンのみの時はコンパクトに
              horizontal: isExtended ? 0 : 12.0, // アイコンのみの時は横にパディング
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 実際の幅に基づいてテキストを表示するか決定
                // アニメーション中は幅が狭いのでテキストを非表示
                final showText = constraints.maxWidth > 150;

                return Row(
                  mainAxisSize: isExtended
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: isExtended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    // アイコン部分
                    if (isExtended && showText)
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: iconColor,
                          size: 26,
                        ),
                      )
                    else
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: iconColor,
                        size: 24,
                      ),
                    // ラベル部分（幅が十分ある時のみ表示）
                    if (showText && isExtended) ...[
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                            color: textColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (isSelected) const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ModernSideBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const ModernSideBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
