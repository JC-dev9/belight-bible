import 'package:flutter/material.dart';

/// Card "Continuar Leitura" — exibe a última posição de leitura do Supabase.
class ContinueReadingCard extends StatelessWidget {
  final String book;
  final int chapter;
  final VoidCallback onTap;

  const ContinueReadingCard({
    super.key,
    required this.book,
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF332D20)
                    : const Color(0xFFFFF7DF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF5A4416)
                      : const Color(0xFFFFE082),
                ),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continuar Leitura',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$book $chapter',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
            ),
          ],
        ),
      ),
    );
  }
}
