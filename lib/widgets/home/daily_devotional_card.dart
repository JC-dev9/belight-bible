import 'package:flutter/material.dart';

class DailyDevotionalCard extends StatelessWidget {
  const DailyDevotionalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee, size: 20, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              Text(
                'Devocional Diário',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '3 min',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Confie no Processo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Muitas vezes queremos que as coisas aconteçam no nosso tempo, mas Deus tem o tempo perfeito para tudo. A paciência não é apenas esperar, mas como nos comportamos enquanto esperamos...',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Open full devotional
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Theme.of(context).dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Ler Tudo'),
            ),
          ),
        ],
      ),
    );
  }
}
