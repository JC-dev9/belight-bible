import 'package:flutter/material.dart';
import '../data/models/dynamic_models.dart';
import '../data/supabase_service.dart';

/// Tela de detalhes do plano de leitura — mostra descrição, objetivo e passagens diárias.
class PlanDetailScreen extends StatefulWidget {
  final ReadingPlan plan;
  final UserReadingPlan? userPlan;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    this.userPlan,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final SupabaseService _service = SupabaseService();
  UserReadingPlan? _userPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userPlan = widget.userPlan;
  }

  int get _currentDay => _userPlan?.currentDay ?? 0;
  bool get _isEnrolled => _userPlan != null;
  bool get _isCompleted => _userPlan?.completedAt != null;

  Color get _planColor {
    try {
      final hex = widget.plan.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _enrollInPlan() async {
    setState(() => _isLoading = true);
    try {
      await _service.enrollInPlan(widget.plan.id);
      // Recarregar dados do plano do utilizador
      final plans = await _service.getUserReadingPlans();
      final updated = plans.firstWhere(
        (p) => p.planId == widget.plan.id,
        orElse: () => UserReadingPlan(
          id: '',
          userId: '',
          planId: widget.plan.id,
          startedAt: DateTime.now(),
        ),
      );
      setState(() {
        _userPlan = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao iniciar o plano')),
        );
      }
    }
  }

  Future<void> _advanceDay() async {
    if (_userPlan == null) return;
    setState(() => _isLoading = true);
    try {
      await _service.advancePlanDay(_userPlan!.id, widget.plan.totalDays);
      // Recarregar
      final plans = await _service.getUserReadingPlans();
      final updated = plans.firstWhere(
        (p) => p.planId == widget.plan.id,
        orElse: () => _userPlan!,
      );
      setState(() {
        _userPlan = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txt = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Descrição
                Text(
                  widget.plan.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: txt.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Objetivo
                if (widget.plan.goal != null && widget.plan.goal!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _planColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _planColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.flag_outlined, color: _planColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Objetivo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _planColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.plan.goal!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: txt.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Progresso
                if (_isEnrolled && !_isCompleted) ...[
                  _buildProgressSection(txt),
                  const SizedBox(height: 20),
                ],

                // Botão de ação principal
                if (!_isEnrolled)
                  _buildStartButton()
                else if (!_isCompleted)
                  _buildAdvanceDayButton(txt)
                else
                  _buildCompletedBadge(),

                const SizedBox(height: 28),

                // Lista de passagens
                Text(
                  'Passagens Diárias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: txt,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // Lista de passagens
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildPassagesList(txt),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _planColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.plan.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _planColor,
                _planColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconData(widget.plan.icon),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.plan.totalDays} dias',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(Color txt) {
    final progress = _userPlan!.progress;
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: txt.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dia $_currentDay de ${widget.plan.totalDays}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: txt,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _planColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: txt.withOpacity(0.08),
              color: _planColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _enrollInPlan,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text(
          'Iniciar Plano',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _planColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAdvanceDayButton(Color txt) {
    final nextPassage = widget.plan.getPassageForDay(_currentDay + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextPassage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _planColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: _planColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Próxima leitura: $nextPassage',
                    style: TextStyle(
                      color: txt.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _advanceDay,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text(
              'Marcar dia como lido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _planColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.green),
          SizedBox(width: 10),
          Text(
            'Plano concluído! Parabéns! 🎉',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassagesList(Color txt) {
    final passages = widget.plan.passages;
    if (passages.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(
          'Passagens não disponíveis para este plano.',
          style: TextStyle(color: txt.withOpacity(0.5)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = passages[index];
          final day = entry['day'] as int;
          final passage = entry['passage'] as String;
          final isCompleted = day <= _currentDay;
          final isCurrent = day == _currentDay + 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _planColor.withOpacity(0.08)
                  : isCompleted
                      ? txt.withOpacity(0.02)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isCurrent
                  ? Border.all(color: _planColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                // Indicador de dia
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : isCurrent
                            ? _planColor.withOpacity(0.1)
                            : txt.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.green, size: 18)
                        : Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isCurrent ? _planColor : txt.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    passage,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCompleted ? txt.withOpacity(0.4) : txt.withOpacity(0.8),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _planColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HOJE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _planColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: passages.length,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'calendar_today': return Icons.calendar_today_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'local_library': return Icons.local_library_outlined;
      case 'auto_stories': return Icons.auto_stories_outlined;
      case 'mail': return Icons.mail_outline;
      default: return Icons.menu_book_outlined;
    }
  }
}
