import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import 'note_card.dart';

class NotesList extends StatelessWidget {
  final Stream<List<Map<String, String>>> notesStream;
  final Map<String, bool> enabledNotes;
  final void Function(Map<String, String> note) onNoteTap;

  const NotesList({
    super.key,
    required this.notesStream,
    required this.enabledNotes,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<List<Map<String, String>>>(
        stream: notesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.home_instruction,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 有効な音符のみをフィルタリング
          final filteredNotes = snapshot.data!
              .where((note) => enabledNotes[note['name']] == true)
              .toList();

          if (filteredNotes.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.home_instruction,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // 画面幅（constraints.maxWidth）に基づいて列数を決定
              // カードの最小幅を基準に動的に計算
              final double width = constraints.maxWidth;
              const double minCardWidth = 280.0;
              final int crossAxisCount = (width / minCardWidth).floor().clamp(
                1,
                4,
              );
              final contentWidth = constraints.maxWidth.clamp(0.0, 1240.0);

              if (crossAxisCount == 1) {
                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        return NoteCard(
                          note: filteredNotes[index],
                          onTap: () => onNoteTap(filteredNotes[index]),
                        );
                      },
                    ),
                  ),
                );
              }

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: GridView.builder(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 3.25,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return NoteCard(
                        note: filteredNotes[index],
                        onTap: () => onNoteTap(filteredNotes[index]),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
