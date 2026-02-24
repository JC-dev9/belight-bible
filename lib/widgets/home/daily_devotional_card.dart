import 'package:flutter/material.dart';
import '../../screens/devotional_reader_screen.dart';

/// Card do devocional diário — recebe dados dinâmicos do Supabase.
class DailyDevotionalCard extends StatelessWidget {
  final String? title;
  final String? content;
  final int readingTimeMin;
  final DateTime? publishDate;
  final String? devotionalId;

  const DailyDevotionalCard({
    super.key,
    this.title,
    this.content,
    this.readingTimeMin = 3,
    this.publishDate,
    this.devotionalId,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null && content == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee, size: 20, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              Text(
                'Devocional Diário',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$readingTimeMin min',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'Devocional',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DevotionalReaderScreen(
                      title: title ?? 'Devocional',
                      content: content ?? '',
                      readingTimeMin: readingTimeMin,
                      publishDate: publishDate,
                      devotionalId: devotionalId,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Theme.of(context).dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Ler Tudo'),
            ),
          ),
        ],
      ),
    );
  }
}
