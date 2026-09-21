import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:io';

/// プラットフォームに応じたページ遷移
/// Android: MaterialPageRoute（予測型戻る対応）
/// iOS/macOS: CupertinoPageRoute（iOS風スライドアニメーション）
Future<T?> pushPage<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? name,
}) {
  if (Platform.isAndroid) {
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
  if (Platform.isAndroid) {
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
