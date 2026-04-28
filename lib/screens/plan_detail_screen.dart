import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/dynamic_models.dart';
import '../data/supabase_service.dart';
import 'plan_reader_screen.dart';

/// Tela de detalhes do plano de leitura — dia a dia com datas reais, checkboxes e leitor focado.
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
  late int _selectedDay; // 1-based
  late ScrollController _dayScrollController;

  // Passagens marcadas como lidas para o dia selecionado (localmente no UI)
  final Set<String> _checkedPassages = {};

  // Sinaliza ao PlansTab que os dados mudaram e precisam de ser recarregados.
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _userPlan = widget.userPlan;
    _dayScrollController = ScrollController();
    _selectedDay = _computeTodayDay();

    // Scroll para o dia selecionado após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Computed Properties
  // ===========================================================================

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

  /// Calcula qual dia do plano corresponde a "hoje" baseado na data de início.
  int _computeTodayDay() {
    if (_userPlan == null) return 1;
    final startDate = DateUtils.dateOnly(_userPlan!.startedAt);
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(startDate).inDays + 1; // Dia 1 = primeiro dia
    return diff.clamp(1, widget.plan.totalDays);
  }

  /// Retorna a data real para um dia do plano.
  DateTime _dateForDay(int day) {
    if (_userPlan == null) return DateTime.now();
    final startDate = DateUtils.dateOnly(_userPlan!.startedAt);
    return startDate.add(Duration(days: day - 1));
  }

  /// Verifica se o dia está "em dia" ou "atrasado".
  String? _dayStatusLabel() {
    if (!_isEnrolled || _isCompleted) return null;
    final todayDay = _computeTodayDay();
    if (_currentDay >= todayDay) return 'EM DIA';
    if (_currentDay < todayDay - 2) return 'ATRASADO';
    return null;
  }

  /// Divide a passagem do dia em passagens individuais separadas por ";"
  List<String> _getPassagesForDay(int day) {
    final passage = widget.plan.getPassageForDay(day);
    if (passage == null) return [];
    return passage.split(';').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  void _scrollToSelectedDay() {
    if (!_dayScrollController.hasClients) return;
    const itemWidth = 72.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = ((_selectedDay - 1) * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _dayScrollController.animateTo(
      offset.clamp(0, _dayScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  // ===========================================================================
  // Actions
  // ===========================================================================

  Future<void> _enrollInPlan() async {
    setState(() => _isLoading = true);
    try {
      await _service.enrollInPlan(widget.plan.id);
      final plans = await _service.getUserPlans();
      final updated = plans.firstWhere(
        (p) => p.planId == widget.plan.id,
        orElse: () => UserReadingPlan(
          id: '', userId: '', planId: widget.plan.id, startedAt: DateTime.now(),
        ),
      );
      _dataChanged = true;
      setState(() {
        _userPlan = updated;
        _selectedDay = _computeTodayDay();
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao iniciar o plano')),
        );
      }
    }
  }

  Future<void> _markDayComplete() async {
    if (_userPlan == null) return;
    setState(() => _isLoading = true);
    try {
      final nextDay = _selectedDay;
      // Marca todos os dias até o selecionado (caso o user esteja a marcar dias atrasados)
      final targetDay = nextDay > _currentDay ? nextDay : _currentDay;
      final isCompleted = targetDay >= widget.plan.totalDays;
      await _service.updatePlanProgress(
        _userPlan!.id,
        targetDay,
        completed: isCompleted,
      );
      final plans = await _service.getUserPlans();
      final updated = plans.firstWhere(
        (p) => p.planId == widget.plan.id,
        orElse: () => _userPlan!,
      );
      _dataChanged = true;
      setState(() {
        _userPlan = updated;
        _checkedPassages.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leavePlan() async {
    if (_userPlan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do Plano'),
        content: const Text('Tens a certeza que queres sair deste plano? Todo o progresso será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await _service.leavePlan(_userPlan!.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao sair do plano')),
          );
        }
      }
    }
  }

  void _openPassageReader(String passage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanReaderScreen(
          planTitle: widget.plan.title,
          passage: passage,
          planColor: _planColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final txt = isDark ? Colors.grey.shade300 : Colors.grey.shade900;
    final subtxt = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: txt),
              onPressed: () => Navigator.pop(context, _dataChanged),
            ),
            title: Text(
              widget.plan.title,
              style: TextStyle(color: txt, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (_isEnrolled)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: txt),
                  color: cardBg,
                  onSelected: (value) {
                    if (value == 'leave') _leavePlan();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Sair do Plano', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar (enrolled only)
                if (_isEnrolled && !_isCompleted) ...[
                  _buildProgressBar(txt),
                ],

                // Day Selector (enrolled only)
                if (_isEnrolled && !_isCompleted) ...[
                  _buildDaySelector(txt, subtxt, cardBg),
                  const SizedBox(height: 4),
                ],

                // Not enrolled: show description + enroll button
                if (!_isEnrolled) ...[
                  _buildNotEnrolledSection(txt, subtxt, cardBg),
                ] else if (_isCompleted) ...[
                  _buildCompletedSection(txt),
                ] else ...[
                  // Day header
                  _buildDayHeader(txt, subtxt),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          // Passage list for the selected day
          if (_isEnrolled && !_isCompleted)
            _buildPassageList(txt, subtxt, cardBg),

          // Complete day button
          if (_isEnrolled && !_isCompleted)
            SliverToBoxAdapter(
              child: _buildCompleteDayButton(txt),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ===========================================================================
  // Progress Bar
  // ===========================================================================

  Widget _buildProgressBar(Color txt) {
    final progress = _currentDay / widget.plan.totalDays;
    final percentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dia $_currentDay de ${widget.plan.totalDays}',
                style: TextStyle(
                  fontSize: 13,
                  color: txt.withAlpha(150),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _planColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: txt.withAlpha(20),
              color: _planColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Day Selector
  // ===========================================================================

  Widget _buildDaySelector(Color txt, Color subtxt, Color cardBg) {
    final todayDay = _computeTodayDay();
    final dateFormat = DateFormat('d MMM', 'pt_BR');

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _dayScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.plan.totalDays,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == _selectedDay;
          final isCompleted = day <= _currentDay;
          final isToday = day == todayDay;
          final date = _dateForDay(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
                _checkedPassages.clear();
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? _planColor
                    : isCompleted
                        ? _planColor.withAlpha(20)
                        : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: _planColor, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : isCompleted
                              ? _planColor
                              : txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withAlpha(200)
                          : subtxt,
                    ),
                  ),
                  if (isCompleted && !isSelected) ...[
                    const SizedBox(height: 2),
                    Icon(Icons.check_circle, size: 12, color: _planColor),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Day Header
  // ===========================================================================

  Widget _buildDayHeader(Color txt, Color subtxt) {
    final statusLabel = _dayStatusLabel();
    final isDayCompleted = _selectedDay <= _currentDay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'Dia $_selectedDay de ${widget.plan.totalDays}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: txt,
            ),
          ),
          const Spacer(),
          if (isDayCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'CONCLUÍDO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else if (statusLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusLabel == 'EM DIA'
                    ? _planColor.withAlpha(25)
                    : Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusLabel == 'EM DIA' ? _planColor : Colors.orange,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Passage List
  // ===========================================================================

  Widget _buildPassageList(Color txt, Color subtxt, Color cardBg) {
    final passages = _getPassagesForDay(_selectedDay);
    final isDayCompleted = _selectedDay <= _currentDay;

    if (passages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Sem passagens para este dia.',
              style: TextStyle(color: subtxt),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final passage = passages[index];
            final isChecked = isDayCompleted || _checkedPassages.contains(passage);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isChecked
                      ? _planColor.withAlpha(40)
                      : txt.withAlpha(15),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openPassageReader(passage),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: isDayCompleted
                              ? null
                              : () {
                                  setState(() {
                                    if (_checkedPassages.contains(passage)) {
                                      _checkedPassages.remove(passage);
                                    } else {
                                      _checkedPassages.add(passage);
                                    }
                                  });
                                },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked
                                  ? _planColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isChecked ? _planColor : txt.withAlpha(60),
                                width: 2,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Passage text
                        Expanded(
                          child: Text(
                            passage,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isChecked ? txt.withAlpha(120) : txt,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),

                        // Chevron
                        Icon(
                          Icons.chevron_right,
                          color: txt.withAlpha(60),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: passages.length,
        ),
      ),
    );
  }

  // ===========================================================================
  // Complete Day Button
  // ===========================================================================

  Widget _buildCompleteDayButton(Color txt) {
    final passages = _getPassagesForDay(_selectedDay);
    final isDayCompleted = _selectedDay <= _currentDay;
    final allChecked = passages.isNotEmpty &&
        passages.every((p) => _checkedPassages.contains(p));

    if (isDayCompleted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (allChecked && !_isLoading) ? _markDayComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _planColor,
            disabledBackgroundColor: txt.withAlpha(15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  allChecked ? 'Marcar Dia Como Concluído' : 'Leia todas as passagens',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: allChecked ? Colors.white : txt.withAlpha(80),
                  ),
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Not Enrolled Section
  // ===========================================================================

  Widget _buildNotEnrolledSection(Color txt, Color subtxt, Color cardBg) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan icon + info
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _planColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIconData(widget.plan.icon),
                  color: _planColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.plan.totalDays} dias de leitura',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _planColor,
                      ),
                    ),
                    if (widget.plan.goal != null && widget.plan.goal!.isNotEmpty)
                      Text(
                        widget.plan.goal!,
                        style: TextStyle(fontSize: 13, color: subtxt),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            widget.plan.description,
            style: TextStyle(
              fontSize: 15,
              color: txt.withAlpha(200),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Passages preview
          Text(
            'PASSAGENS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: subtxt,
            ),
          ),
          const SizedBox(height: 10),
          ...widget.plan.passages.take(5).map((entry) {
            final day = entry['day'] as int;
            final passage = entry['passage'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtxt),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(passage, style: TextStyle(fontSize: 14, color: txt.withAlpha(180))),
                ],
              ),
            );
          }),
          if (widget.plan.passages.length > 5)
            Text(
              '...e mais ${widget.plan.passages.length - 5} dias',
              style: TextStyle(fontSize: 13, color: subtxt),
            ),
          const SizedBox(height: 24),

          // Enroll button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _enrollInPlan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text(
                'Iniciar Plano',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _planColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Completed Section
  // ===========================================================================

  Widget _buildCompletedSection(Color txt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Plano Concluído!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: txt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Parabéns! Completaste todos os ${widget.plan.totalDays} dias de leitura. 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: txt.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

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
