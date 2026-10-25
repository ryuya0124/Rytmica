import 'package:material_ui/material_ui.dart';

class NumericInputColumnWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String titleText;
  final Function(String) onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const NumericInputColumnWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.titleText,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ソフトウェア的な画面の横幅を取得
    final screenWidth = MediaQuery.of(context).size.width;

    // ソフトウェア的な横幅に基づいてボタン表示を制御
    final showButtons = screenWidth >= 420; // 420dp以上ならボタンを表示

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 左右の要素を分ける
      crossAxisAlignment: CrossAxisAlignment.center, // 縦方向で中央揃え
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 16,
          ),
          maxLines: 2, // 必要に応じて最大行数を設定
          overflow: TextOverflow.ellipsis, // 長い場合に省略を設定（必要なら）
          softWrap: true, // 自動改行を許可
        ),
        const SizedBox(width: 8), // テキストと入力欄の間に少しスペースを追加
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min, // 最小サイズに設定
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 90), // 幅を90に制限
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4), // 入力欄とボタンの間のスペース
                if (showButtons) // 最小幅または解像度に基づいてボタンを表示
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: colorScheme.primary,
                        onPressed: onIncrement,
                      ),
                      const SizedBox(width: 4), // プラス・マイナスボタン間のスペース
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: colorScheme.primary,
                        onPressed: onDecrement,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
