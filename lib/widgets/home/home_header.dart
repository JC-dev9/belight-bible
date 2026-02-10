import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    // Tenta pegar o nome do metadata, se não tiver, usa parte do email
    final String name = user?.userMetadata?['name'] ?? 
                        user?.email?.split('@').first ?? 
                        'Visitante';

    // Capitalize first letter
    final displayName = name.isEmpty ? 'Visitante' : 
        '${name[0].toUpperCase()}${name.substring(1)}';

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
              displayName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800, // Extra bold for impact
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        
        // Streak Counter
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
              const Text(
                '3', // Mock data
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'dias',
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
