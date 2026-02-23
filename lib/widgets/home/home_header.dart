import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Header da Home — exibe nome dinâmico e streak real do Supabase.
class HomeHeader extends StatelessWidget {
  final String displayName;
  final int streak;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter
    final name = displayName.isEmpty ? 'Visitante' : displayName;
    final capitalizedName = '${name[0].toUpperCase()}${name.substring(1)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá,',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              capitalizedName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        
        // Streak Counter (dinâmico)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              const SizedBox(width: 6),
              Text(
                '$streak',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                streak == 1 ? 'dia' : 'dias',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
