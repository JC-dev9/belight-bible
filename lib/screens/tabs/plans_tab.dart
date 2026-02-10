import 'package:flutter/material.dart';

class PlansTab extends StatelessWidget {
  const PlansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Planos de Leitura', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlanCard(
            context,
            title: 'Bíblia em 1 Ano',
            subtitle: 'Leia toda a bíblia em 365 dias',
            progress: 0.15,
            color: Colors.blue,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context,
            title: 'Salmos e Provérbios',
            subtitle: 'Sabedoria diária para sua vida',
            progress: 0.0,
            color: Colors.teal,
            icon: Icons.favorite,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context,
            title: 'Novo Testamento',
            subtitle: 'A vida e obra de Jesus',
            progress: 0.45,
            color: Colors.purple,
            icon: Icons.local_library,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Novo Plano'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.yellow.shade800,
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (progress > 0) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toInt()}% concluído',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Iniciar'),
              ),
            ),
        ],
      ),
    );
  }
}
