import 'package:flutter/material.dart';
import '../../data/supabase_service.dart';
import '../../data/models/dynamic_models.dart';

/// Aba de Planos de Leitura — carrega planos dinâmicos do Supabase.
class PlansTab extends StatefulWidget {
  const PlansTab({super.key});

  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  final SupabaseService _service = SupabaseService();
  
  List<ReadingPlan> _allPlans = [];
  List<UserReadingPlan> _userPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final results = await Future.wait([
      _service.getReadingPlans(),
      _service.getUserPlans(),
    ]);

    if (mounted) {
      setState(() {
        _allPlans = results[0] as List<ReadingPlan>;
        _userPlans = results[1] as List<UserReadingPlan>;
        _isLoading = false;
      });
    }
  }

  /// Verifica se o utilizador já está inscrito num plano.
  UserReadingPlan? _getUserPlan(String planId) {
    try {
      return _userPlans.firstWhere((up) => up.planId == planId);
    } catch (_) {
      return null;
    }
  }

  /// Ícone baseado no nome do ícone do plano.
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'calendar_today': return Icons.calendar_today;
      case 'favorite': return Icons.favorite;
      case 'local_library': return Icons.local_library;
      case 'auto_stories': return Icons.auto_stories;
      case 'mail': return Icons.mail;
      default: return Icons.book;
    }
  }

  /// Cor baseada no hex string do plano.
  Color _getColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _enrollInPlan(String planId) async {
    await _service.enrollInPlan(planId);
    await _loadPlans();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscrito no plano com sucesso!')),
      );
    }
  }

  Future<void> _advanceDay(UserReadingPlan userPlan) async {
    final plan = userPlan.plan;
    if (plan == null) return;

    final newDay = userPlan.currentDay + 1;
    final completed = newDay >= plan.totalDays;

    await _service.updatePlanProgress(userPlan.id, newDay, completed: completed);
    await _loadPlans();

    if (mounted && completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Parabéns! Plano concluído!')),
      );
    }
  }

  Future<void> _leavePlan(String userPlanId) async {
    await _service.leavePlan(userPlanId);
    await _loadPlans();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: _allPlans.isEmpty
                  ? const Center(child: Text('Nenhum plano disponível.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allPlans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final plan = _allPlans[index];
                        final userPlan = _getUserPlan(plan.id);
                        return _buildPlanCard(context, plan, userPlan);
                      },
                    ),
            ),
    );
  }

  Widget _buildPlanCard(BuildContext context, ReadingPlan plan, UserReadingPlan? userPlan) {
    final color = _getColor(plan.color);
    final icon = _getIcon(plan.icon);
    final isEnrolled = userPlan != null;
    final progress = userPlan?.progress ?? 0.0;
    final isCompleted = userPlan?.completedAt != null;

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
                      plan.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu de ações (se inscrito)
              if (isEnrolled)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'leave') _leavePlan(userPlan!.id);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'leave', child: Text('Sair do plano')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEnrolled) ...[
            // Progresso
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted 
                      ? '✅ Concluído!'
                      : 'Dia ${userPlan!.currentDay} de ${plan.totalDays}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _advanceDay(userPlan!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Marcar dia como lido'),
                ),
              ),
            ],
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _enrollInPlan(plan.id),
                child: const Text('Iniciar'),
              ),
            ),
        ],
      ),
    );
  }
}
