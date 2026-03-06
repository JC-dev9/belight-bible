import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';
import '../data/models/dynamic_models.dart';

/// Tela de Perfil — carrega stats reais e perfil editável do Supabase.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _nameController = TextEditingController();
  
  UserProfile? _profile;
  int _highlightCount = 0;
  int _noteCount = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final results = await Future.wait([
      _service.getProfile(),
      _service.countHighlights(),
      _service.countNotes(),
      _service.getReadingProgress(),
    ]);

    if (mounted) {
      final profile = results[0] as UserProfile?;
      final progress = results[3] as ReadingProgress?;
      setState(() {
        _profile = profile;
        _highlightCount = results[1] as int;
        _noteCount = results[2] as int;
        _streak = progress?.currentStreak ?? 0;
        _nameController.text = profile?.fullName ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await _service.updateProfile(fullName: _nameController.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil salvo com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    final stats = [
      {'label': 'Dias seguidos', 'value': '$_streak', 'icon': Icons.local_fire_department, 'color': Colors.orange},
      {'label': 'Destaques', 'value': '$_highlightCount', 'icon': Icons.highlight, 'color': Colors.blue},
      {'label': 'Anotações', 'value': '$_noteCount', 'icon': Icons.edit, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.yellow.shade800,
                    child: Text(
                      (_nameController.text.isNotEmpty 
                          ? _nameController.text[0]
                          : user?.email?.substring(0, 1) ?? 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isNotEmpty 
                        ? _nameController.text
                        : user?.email?.split('@')[0] ?? 'Usuário',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats Grid (dinâmico)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: stats.map((stat) => _buildStatItem(context, stat)).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Formulário
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome Completo',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: TextEditingController(text: user?.email ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.yellow.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
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
}
