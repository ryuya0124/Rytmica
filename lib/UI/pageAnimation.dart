import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import 'dart:io';

/// プラットフォームに応じたページ遷移
/// Android: MaterialPageRoute（予測型戻る対応）
/// iOS/macOS: CupertinoPageRoute（iOS風スライドアニメーション）
Future<T?> pushPage<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? name,
}) {
  if (kIsWeb || Platform.isAndroid) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute<T>(
        builder: builder,
        settings: RouteSettings(name: name),
      ),
    );
  }
  return Navigator.push<T>(
    context,
    CupertinoPageRoute<T>(
      builder: builder,
      settings: RouteSettings(name: name),
    ),
  );
}

Future<T?> pushDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? name,
}) {
  final nav = Navigator.of(context, rootNavigator: true);
  if (kIsWeb || Platform.isAndroid) {
    return nav.push<T>(
      MaterialPageRoute<T>(
        builder: builder,
        settings: RouteSettings(name: name),
        fullscreenDialog: true,
      ),
    );
  }
  return nav.push<T>(
    CupertinoPageRoute<T>(
      builder: builder,
      settings: RouteSettings(name: name),
      fullscreenDialog: true,
    ),
  );
}
