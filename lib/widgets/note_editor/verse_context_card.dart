import 'package:flutter/material.dart';

class VerseContextCard extends StatelessWidget {
  final String book;
  final int chapter;
  final int verseNumber;
  final String verseText;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;

  const VerseContextCard({
    super.key,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.verseText,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_outline, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                "$book $chapter:$verseNumber",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verseText,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
