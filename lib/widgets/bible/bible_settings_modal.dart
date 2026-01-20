import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class BibleSettingsSheet extends StatelessWidget {
  final ReadingTheme currentTheme;
  final double fontSize;
  final Function(double) onFontSizeChanged;
  final Function(ReadingTheme) onThemeChanged;

  const BibleSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
  });

  Color _getModalBg() {
    switch (currentTheme) {
      case ReadingTheme.dark:
        return AppColors.darkSurface;
      case ReadingTheme.sepia:
        return AppColors.sepiaBg;
      default:
        return Colors.white;
    }
  }

  Color _getModalText() {
    switch (currentTheme) {
      case ReadingTheme.dark:
        return Colors.white;
      case ReadingTheme.sepia:
        return AppColors.sepiaText;
      default:
        return Colors.black;
    }
  }

  Color _getActiveColor() {
     return currentTheme == ReadingTheme.sepia ? AppColors.sepiaAccent : AppTheme.accentGold;
  }

  @override
  Widget build(BuildContext context) {
    // Usamos StatefulBuilder internamente se quisermos que o arrasto seja suave sem reconstruir o pai?
    // Na verdade, se o pai reconstruir, este widget reconstrói.
    // No entanto, o Slider precisa de atualizar visualmente de forma suave. 
    // Se passarmos onFontSizeChanged, o pai define o estado, este widget reconstrói. Deve funcionar bem.
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getModalBg(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aparência',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _getModalText())),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.text_fields, size: 16, color: _getModalText()),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 12,
                  max: 30,
                  divisions: 18,
                  activeColor: _getActiveColor(),
                  inactiveColor: _getModalText().withOpacity(0.2),
                  label: fontSize.round().toString(),
                  onChanged: onFontSizeChanged,
                ),
              ),
              Icon(Icons.text_fields, size: 28, color: _getModalText()),
            ],
          ),

          const SizedBox(height: 20),
          Text('Tema',
              style: TextStyle(fontWeight: FontWeight.w600, color: _getModalText())),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeOption(ReadingTheme.light, Colors.white, Colors.black, 'Claro'),
              _buildThemeOption(ReadingTheme.sepia, AppColors.sepiaBg, AppColors.sepiaText, 'Papel'),
              _buildThemeOption(ReadingTheme.dark, AppColors.darkBg, Colors.white, 'Escuro'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildThemeOption(ReadingTheme theme, Color bg, Color text, String label) {
    final isSelected = currentTheme == theme;
    return GestureDetector(
      onTap: () => onThemeChanged(theme),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _getActiveColor() : Colors.grey.shade400,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text('Aa', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: _getModalText())),
        ],
      ),
    );
  }
}
