import 'package:flutter/material.dart';

enum ReadingTheme { light, dark, sepia }

class AppColors {
  // Tema Sépia (Estilo Papel Antigo - Ajustado para ser mais suave)
  static const sepiaBg = Color(0xFFFBF0D9);
  static const sepiaText = Color(0xFF5F4B32);
  static const sepiaAccent = Color(0xFF8D6E63);

  // Tema Dark
  static const darkBg = Color(0xFF1E1E1E);
  static const darkSurface = Color(0xFF2C2C2C);
  
  // Cores do NavigationBar
  static const navSepia = Color(0xFFF0E4CA); 
  static const navDark = Color(0xFF252525);  
  
  // Destaque (Highlight)
  static const highlightColor = Color(0xFFFFE082); // Amarelo bem clarinho para o marca-texto
}

class AppTheme {
  // Cores
  static const Color creamBackground = Color(0xFFFBF9F5);
  static const Color darkBackground = Color(0xFF1A1A1A);
  
  // AQUI ESTÁ A MUDANÇA:
  // Antes era: 0xFFD4AF37 (Dourado escuro/velho)
  // Agora é: 0xFFFFC107 (Amarelo Ambar Vibrante - Estilo Google/Luz)
  static const Color accentGold = Color(0xFFFFC107); 
  
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFFE0E0E0);
  
  // Estilo de botões e inputs
  static InputDecoration inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: AppTheme.accentGold, width: 2.0),
      ),
    );
  }
}