import 'package:flutter/material.dart';
import '../../data/models/dynamic_models.dart';
import '../../data/supabase_service.dart';
import '../plan_detail_screen.dart';

/// Tab de Planos de Leitura — exibe planos disponíveis e inscritos.
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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allPlans = await _service.getReadingPlans();
      final userPlans = await _service.getUserPlans();
      if (mounted) {
        setState(() {
          _allPlans = allPlans;
          _userPlans = userPlans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  UserReadingPlan? _getUserPlan(String planId) {
    try {
      return _userPlans.firstWhere((up) => up.planId == planId);
    } catch (_) {
      return null;
    }
  }

  void _openPlanDetail(ReadingPlan plan) async {
    final userPlan = _getUserPlan(plan.id);
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailScreen(plan: plan, userPlan: userPlan),
      ),
    );
    if (changed == true) _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txt = theme.textTheme.bodyMedium?.color ?? Colors.black;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    // Separar planos inscritos e disponíveis
    final enrolledPlanIds = _userPlans.map((p) => p.planId).toSet();
    final enrolledPlans = _allPlans
        .where((p) => enrolledPlanIds.contains(p.id))
        .toList();
    final availablePlans = _allPlans
        .where((p) => !enrolledPlanIds.contains(p.id))
        .toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: Colors.amber,
        onRefresh: _loadPlans,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planos de Leitura',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: txt,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organize a sua leitura bíblica com planos guiados',
                      style: TextStyle(fontSize: 14, color: txt.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Meus Planos
            if (enrolledPlans.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'MEUS PLANOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: txt.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: enrolledPlans.length,
                  itemBuilder: (_, i) {
                    final plan = enrolledPlans[i];
                    final userPlan = _getUserPlan(plan.id)!;
                    return _buildEnrolledPlanCard(plan, userPlan, txt);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // Header de Planos Disponíveis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  enrolledPlans.isEmpty ? 'PLANOS DISPONÍVEIS' : 'EXPLORAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: txt.withOpacity(0.4),
                  ),
                ),
              ),
            ),

            // Lista de planos disponíveis (lazy) ou mensagem vazia
            if (availablePlans.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Você está inscrito em todos os planos! 🎉',
                      style: TextStyle(color: txt.withOpacity(0.5)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.builder(
                  itemCount: availablePlans.length,
                  itemBuilder: (_, i) =>
                      _buildAvailablePlanCard(availablePlans[i], txt),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledPlanCard(
    ReadingPlan plan,
    UserReadingPlan userPlan,
    Color txt,
  ) {
    final color = _parseColor(plan.color);
    final progress = userPlan.progress;
    final isCompleted = userPlan.completedAt != null;
    final currentPassage = plan.getPassageForDay(userPlan.currentDay + 1);

    return GestureDetector(
      onTap: () => _openPlanDetail(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIconData(plan.icon), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: txt,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? 'Concluído ✅'
                            : 'Dia ${userPlan.currentDay} de ${plan.totalDays}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted
                              ? Colors.green
                              : txt.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: txt.withOpacity(0.3),
                ),
              ],
            ),

            if (!isCompleted) ...[
              const SizedBox(height: 14),
              // Barra de progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: txt.withOpacity(0.06),
                  color: color,
                  minHeight: 6,
                ),
              ),

              // Próxima leitura
              if (currentPassage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Próximo: $currentPassage',
                        style: TextStyle(
                          fontSize: 12,
                          color: txt.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlanCard(ReadingPlan plan, Color txt) {
    final color = _parseColor(plan.color);

    return GestureDetector(
      onTap: () => _openPlanDetail(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: txt.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: txt.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIconData(plan.icon), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.totalDays} dias • ${plan.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: txt.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ver',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calendar_today':
        return Icons.calendar_today_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      case 'local_library':
        return Icons.local_library_outlined;
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      case 'mail':
        return Icons.mail_outline;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
