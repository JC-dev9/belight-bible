import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    // Mock stats
    const stats = [
      {'label': 'Dias seguidos', 'value': '12', 'icon': Icons.local_fire_department, 'color': Colors.orange},
      {'label': 'Capítulos', 'value': '48', 'icon': Icons.menu_book, 'color': Colors.blue},
      {'label': 'Anotações', 'value': '15', 'icon': Icons.edit, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Big
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.yellow.shade800,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.email?.split('@')[0] ?? 'Usuário',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 32),
            
            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: stats.map((stat) => _buildStatItem(context, stat)).toList(),
              ),
            ),

            const SizedBox(height: 32),
            
            // Edit Form (Read-only for now)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildTextField(label: 'Nome Completo', value: 'Usuário Exemplo'),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Email', value: user?.email ?? ''),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.yellow.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, Map<String, dynamic> stat) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(stat['icon'] as IconData, color: stat['color'], size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          stat['value'],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          stat['label'],
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required String value}) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      readOnly: true, // For now
    );
  }
}
