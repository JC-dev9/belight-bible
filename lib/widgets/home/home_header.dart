import 'package:flutter/material.dart';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Olá, $capitalizedName',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 360 ? 20 : 26,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 12),
        
        // Streak Counter (dinâmico)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF332D20)
                : const Color(0xFFFFF7DF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF5A4416)
                  : const Color(0xFFFFE082),
            ),
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
