import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LicencePage extends StatelessWidget {
  const LicencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final package = snapshot.data;
        final version = package == null
            ? ''
            : '${package.version} (${package.buildNumber})';
        return LicensePage(
          applicationName: loc.title,
          applicationVersion: version,
          applicationIcon: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icon/icon/icon.jpg',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          applicationLegalese: 'MIT License © 2024–2026 ryuya0124',
        );
      },
    );
  }
}
