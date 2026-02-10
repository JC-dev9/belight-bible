import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Modern Gradient - Softer & More Elegant
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF3E3E3E) // Darker variant for dark mode
                : const Color(0xFFF9F1E5), // Soft elegant cream/gold for light
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
            color: Colors.black.withOpacity(0.05), // Softer shadow
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circle (subtle)
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
                         Share.share('"Porque Deus amou o mundo de tal maneira..." João 3:16 - App Bíblia');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '"Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito, para que todo aquele que nele crê não pereça, mas tenha a vida eterna."',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18, 
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    fontFamily: 'Serif', 
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'João 3:16',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14,
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
