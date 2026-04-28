import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Card do versículo do dia — visual editorial com aspas decorativas.
class DailyVerseCard extends StatelessWidget {
  final String? verseText;
  final String? reference;

  const DailyVerseCard({
    super.key,
    this.verseText,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = verseText ?? 'Carregando...';
    final ref = reference ?? '';

    final gradient = isDark
        ? const [Color(0xFF2A2418), Color(0xFF1F1B14)]
        : const [Color(0xFFFFF8E7), Color(0xFFFCEEC8)];

    final accent = isDark
        ? const Color(0xFFE0B86E)
        : const Color(0xFFB8862F);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.18 : 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : accent).withOpacity(isDark ? 0.30 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Aspas decorativas grandes em marca d'água.
            Positioned(
              right: 16,
              top: -28,
              child: Text(
                '"',
                style: TextStyle(
                  fontSize: 180,
                  height: 1,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.w900,
                  color: accent.withOpacity(isDark ? 0.10 : 0.12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(isDark ? 0.20 : 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 12, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              'VERSÍCULO DO DIA',
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Share.share('"$text" $ref — BeLight Bible');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.ios_share_rounded,
                              color: accent,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    text,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF2E9D8)
                          : const Color(0xFF2C2418),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                      fontFamily: 'Serif',
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        height: 1,
                        width: 28,
                        color: accent.withOpacity(0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ref,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
