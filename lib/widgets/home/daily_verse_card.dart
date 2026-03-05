import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Card do versículo do dia — recebe texto e referência dinâmicos do Supabase.
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
    final text = verseText ?? 'Carregando...';
    final ref = reference ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF3E3E3E)
                : const Color(0xFFF9F1E5),
            Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2C2C2C)
                : const Color(0xFFF0E6D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculo decorativo
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VERSÍCULO DO DIA',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.share_outlined, 
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black.withOpacity(0.6), 
                          size: 20),
                      onPressed: () {
                         Share.share('"$text" $ref - BeLight Bible');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '"$text"',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 20, 
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontFamily: 'Serif', 
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '- $ref',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
