import 'package:flutter/material.dart';

class BibleHeader extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String book;
  final String version;
  final Color activeColor;
  final VoidCallback onVersionTap;
  final VoidCallback onBookTap;
  final VoidCallback onSettingsTap;
  final VoidCallback? onSearchTap;

  const BibleHeader({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.book,
    required this.version,
    required this.activeColor,
    required this.onVersionTap,
    required this.onBookTap,
    required this.onSettingsTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: textColor.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão de Versão
          TextButton(
            onPressed: onVersionTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: textColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              version.toUpperCase(),
              style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
            ),
          ),

          // Seletor de Livro
          GestureDetector(
            onTap: onBookTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    book,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: textColor),
                ],
              ),
            ),
          ),

          // Acções: Pesquisa + Definições
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSearchTap != null)
                IconButton(
                  icon: Icon(Icons.search, color: textColor),
                  onPressed: onSearchTap,
                  tooltip: 'Pesquisar',
                ),
              IconButton(
                icon: Icon(Icons.text_format, color: textColor),
                onPressed: onSettingsTap,
                tooltip: 'Ajustar texto',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
