import 'package:flutter/material.dart';

class BibleBottomControls extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final int currentChapter;
  final bool isFirstChapter;
  final bool isLastChapter;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onChapterTap;

  const BibleBottomControls({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.currentChapter,
    required this.isFirstChapter,
    required this.isLastChapter,
    required this.onPrevious,
    required this.onNext,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            label: 'Anterior',
            color: textColor,
            onTap: isFirstChapter ? null : onPrevious,
          ),
          GestureDetector(
            onTap: onChapterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Capítulo $currentChapter',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right,
            label: 'Próximo',
            color: textColor,
            isRight: true,
            onTap: isLastChapter ? null : onNext,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isRight = false,
  }) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
