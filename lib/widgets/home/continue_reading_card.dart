import 'package:flutter/material.dart';
import '../../data/models/dynamic_models.dart';

/// Card "Continuar Leitura" — design moderno com gradiente e ícone.
class ContinueReadingCard extends StatelessWidget {
  final ReadingProgress? progress;
  final VoidCallback? onTap;

  const ContinueReadingCard({
    super.key,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txt = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? [const Color(0xFF1A2332), const Color(0xFF0F1824)]
                : [const Color(0xFFF0F4FF), const Color(0xFFE3ECFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(isDark ? 0.05 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone do livro
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.book_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Informação
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continuar leitura',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade300,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress!.book} ${progress!.chapter}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txt,
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.blue.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
