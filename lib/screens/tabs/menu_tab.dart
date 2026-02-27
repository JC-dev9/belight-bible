import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile_screen.dart';
import '../saved_data_screen.dart';
import '../connections_screen.dart';

class MenuTab extends StatelessWidget {
  final Function(String, int, int) onNavigateToVerse;
  final VoidCallback onDataChanged;

  const MenuTab({
    super.key,
    required this.onNavigateToVerse,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mais', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Perfil Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.yellow.shade800,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email?.split('@')[0] ?? 'Usuário',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'email@exemplo.com',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Minha Biblioteca',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          _buildMenuTile(
            context,
            icon: Icons.bookmarks,
            color: Colors.orange,
            title: 'Salvos e Destaques',
            subtitle: 'Seus versículos marcados e anotações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedDataScreen(
                    onNavigateToVerse: (book, chapter, verse) {
                      Navigator.pop(context);
                      onNavigateToVerse(book, chapter, verse); 
                    },
                    onDataChanged: onDataChanged,
                  ),
                ),
              );
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.hub,
            color: Colors.blue,
            title: 'Conexões',
            subtitle: 'Visualize as relações entre conceitos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConnectionsScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Configurações',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          _buildMenuTile(
            context,
            icon: Icons.settings,
            color: Colors.grey,
            title: 'Preferências',
            onTap: () {
              // TODO: Implement settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações em breve')),
              );
            },
          ),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            color: Colors.red,
            title: 'Sair',
            textColor: Colors.red,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                 Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            color: textColor
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
