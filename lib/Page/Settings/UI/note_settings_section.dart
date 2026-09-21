import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

import '../../../ParamData/settings_model.dart';

import 'settings_section_card.dart';

class NoteSettingsSection extends StatelessWidget {
  const NoteSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionCard(
          title: loc.note_settings,
          child: _buildNoteSettingsContent(context),
        ),
        SettingsSectionCard(
          title: loc.custom_notes,
          child: const CustomNotesContent(),
        ),
      ],
    );
  }

  Widget _buildNoteSettingsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...context.watch<SettingsModel>().enabledNotes.keys.map((noteKey) {
          return SwitchListTile(
            title: Text(AppLocalizations.of(context)!.getTranslation(noteKey)),
            value: context.watch<SettingsModel>().enabledNotes[noteKey]!,
            onChanged: (bool value) {
              context.read<SettingsModel>().toggleNoteEnabled(noteKey);
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}

class CustomNotesContent extends StatefulWidget {
  const CustomNotesContent({super.key});

  @override
  State<CustomNotesContent> createState() => _CustomNotesContentState();
}

class _CustomNotesContentState extends State<CustomNotesContent> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomNotesList(context),
        const SizedBox(height: 16),
        _buildNoteInputSection(context),
      ],
    );
  }

  Widget _buildCustomNotesList(BuildContext context) {
    final customNotes = context.watch<SettingsModel>().customNotes;
    final colorScheme = Theme.of(context).colorScheme;

    if (customNotes.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.no_custom_notes,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: customNotes.map((note) {
        return ListTile(
          title: Text(note.name),
          subtitle: Text('1/${note.note}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () {
              context.read<SettingsModel>().removeCustomNote(note.name);
            },
          ),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildNoteInputSection(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: loc.note_name,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: valueController,
          decoration: InputDecoration(
            labelText: loc.note_value,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                (nameController.text.isNotEmpty &&
                    valueController.text.isNotEmpty)
                ? () {
                    final name = nameController.text;
                    final value = double.tryParse(valueController.text);
                    if (value != null && value > 0) {
                      context.read<SettingsModel>().addCustomNote(name, value);
                      nameController.clear();
                      valueController.clear();
                      setState(() {});
                    }
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(loc.add_note),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
