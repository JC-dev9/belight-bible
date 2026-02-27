import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/dynamic_models.dart';

/// Card do versículo diário — design refinado com gradiente subtil.
class DailyVerseCard extends StatelessWidget {
  final DailyVerse? verse;

  const DailyVerseCard({super.key, this.verse});

  @override
  Widget build(BuildContext context) {
    if (verse == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A1F00), const Color(0xFF1A1200)]
              : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(isDark ? 0.08 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ícone decorativo subtil
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              Icons.format_quote_rounded,
              size: 80,
              color: Colors.amber.withOpacity(isDark ? 0.05 : 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✨ Versículo do Dia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Botão partilhar
                    GestureDetector(
                      onTap: () {
                        Share.share(
                          '"${verse!.text}"\n— ${verse!.reference}\n\nBeLight Bible',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Texto do versículo
                Text(
                  '"${verse!.text}"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.amber.shade100 : Colors.brown.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                // Referência
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— ${verse!.reference}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
