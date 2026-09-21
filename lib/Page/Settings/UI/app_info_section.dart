import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dart:io';

import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../licence_page.dart';
import '../../../UI/pageAnimation.dart';

class AppInfoSection extends StatelessWidget {
  const AppInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 20),
        // アプリアイコンまたはロゴ
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/icon/icon/icon.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // アプリ名とバージョン
        Text(
          'Rytmica',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 32),
        // GitHubリンク
        ElevatedButton.icon(
          onPressed: () => _moveGithub(context),
          icon: const Icon(Icons.code),
          label: Text(loc.view_on_github),
        ),
        const SizedBox(height: 32),
        // 各種リンク
        _buildLinkItem(
          context,
          icon: Icons.description,
          label: loc.licenceInfo,
          onTap: () => _navigateToLicense(context),
        ),
        _buildLinkItem(
          context,
          icon: Icons.privacy_tip,
          label: loc.privacy_policy,
          onTap: () =>
              _launchUrl(context, "https://rytmica.ryuya-dev.net/privacy"),
        ),
        _buildLinkItem(
          context,
          icon: Icons.article,
          label: loc.terms_of_service,
          onTap: () =>
              _launchUrl(context, "https://rytmica.ryuya-dev.net/terms"),
        ),
        _buildLinkItem(
          context,
          icon: Icons.support_agent,
          label: loc.support,
          onTap: () =>
              _launchUrl(context, "https://rytmica.ryuya-dev.net/support"),
        ),
      ],
    );
  }

  Widget _buildLinkItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        label,
        style: TextStyle(color: colorScheme.primary),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _navigateToLicense(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LicencePage()),
      );
    } else {
      pushPage<void>(
        context,
        (BuildContext context) {
          return const LicencePage();
        },
        name: "/root/settings/licence",
      );
    }
  }

  Future<void> _moveGithub(BuildContext context) async {
    _launchUrl(context, "https://github.com/ryuya0124/musical_note_calculator");
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open the URL: $e')),
        );
      }
    }
  }
}
