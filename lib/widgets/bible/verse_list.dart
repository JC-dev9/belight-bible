import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../utils/theme.dart';
import 'bible_types.dart';

class VerseList extends StatelessWidget {
  final List<Map<String, dynamic>> verses;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Color baseTextColor;
  final double fontSize;
  final HighlightStyle selectedHighlightStyle;
  final int? focusedVerseIndex;
  final Set<int> selectedVerses;
  final Color verseNumColor;
  final Color activeColor;
  final ReadingTheme currentTheme;

  // Funções de Retorno (Callbacks)
  final VoidCallback onClearFocus;
  final Function(int) onVerseTap;
  final Function(int) onVerseLongPress;
  final Function(int) onNoteTap;

  const VerseList({
    super.key,
    required this.verses,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.baseTextColor,
    required this.fontSize,
    required this.selectedHighlightStyle,
    required this.focusedVerseIndex,
    required this.selectedVerses,
    required this.verseNumColor,
    required this.activeColor,
    required this.currentTheme,
    required this.onClearFocus,
    required this.onVerseTap,
    required this.onVerseLongPress,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        onClearFocus();
      },
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        itemCount: verses.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final verse = verses[index];
          final highlightValue = verse['highlighted'];
          final Color? highlightColor = highlightValue is Color
              ? highlightValue
              : (highlightValue == true ? AppTheme.accentGold : null);

          final hasNote =
              verse['note'] != null && verse['note'].toString().isNotEmpty;

          // Determine highlight type from STORED data (not global state)
          // For selected verses, use global tool state. For unselected, use stored type.
          final bool isSelected = selectedVerses.contains(index);
          final String? storedType = verse['highlight_type'];

          final bool isBlock;
          final bool isText;

          if (isSelected) {
            // Selected verses: preview with current tool setting
            isBlock = selectedHighlightStyle == HighlightStyle.fundoVersiculo;
            isText = selectedHighlightStyle == HighlightStyle.fundoTexto;
          } else if (highlightColor != null && storedType != null) {
            // Unselected highlighted verses: use stored type
            isBlock = storedType == 'block';
            isText = storedType == 'text';
          } else {
            // No highlight or no type stored: default to block
            isBlock = true;
            isText = false;
          }

          // Lógica de Foco
          final bool isFocused = focusedVerseIndex == index;
          final bool isDimmed = focusedVerseIndex != null && !isFocused;

          final double opacity = isDimmed ? 0.3 : 1.0;
          final Color textColorWithFocus = baseTextColor.withOpacity(
            isDimmed ? 0.3 : 1.0,
          );

          return RepaintBoundary(
            child: GestureDetector(
              onLongPress: () => onVerseLongPress(index),
              onTap: () => onVerseTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: (highlightColor != null && isBlock)
                      ? highlightColor.withOpacity(
                          isDimmed
                              ? 0.1
                              : (currentTheme == ReadingTheme.dark ? 0.3 : 0.4),
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: hasNote
                        ? BorderSide(
                            color: activeColor.withOpacity(opacity),
                            width: 3,
                          )
                        : BorderSide.none,
                    bottom: isSelected
                        ? BorderSide(color: activeColor, width: 3)
                        : (isFocused
                              ? BorderSide(color: activeColor, width: 2)
                              : BorderSide.none),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.6,
                          color: textColorWithFocus,
                          fontFamily: 'Georgia',
                          backgroundColor: (highlightColor != null && isText)
                              ? highlightColor.withOpacity(isDimmed ? 0.1 : 0.5)
                              : null,
                        ),
                        children: [
                          WidgetSpan(
                            child: Transform.translate(
                              offset: const Offset(0, -4),
                              child: Text(
                                '${verse['number']} ',
                                style: TextStyle(
                                  fontSize: fontSize * 0.6,
                                  fontWeight: FontWeight.bold,
                                  color: verseNumColor.withOpacity(opacity),
                                ),
                              ),
                            ),
                          ),
                          TextSpan(text: verse['text']),
                        ],
                      ),
                    ),
                    if (hasNote)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => onNoteTap(index),
                              child: Icon(
                                Icons.note,
                                size: 14,
                                color: activeColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => onNoteTap(index),
                                child: Text(
                                  verse['note_preview'] as String? ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: baseTextColor.withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
