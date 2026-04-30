import 'package:flutter/material.dart';
import '../../data/supabase_service.dart';
import '../../data/models/dynamic_models.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/daily_verse_card.dart';
import '../../widgets/home/continue_reading_card.dart';
import '../../widgets/home/daily_devotional_card.dart';

/// Aba principal — carrega dados dinâmicos do Supabase e passa para os widgets.
class HomeTab extends StatefulWidget {
  final Function(String book, int chapter, int verse)? onNavigateToVerse;

  const HomeTab({super.key, this.onNavigateToVerse});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final SupabaseService _service = SupabaseService();

  // Cache estático — partilhado entre instâncias, válido por 5 minutos.
  static ReadingProgress? _cachedProgress;
  static DailyVerse? _cachedVerse;
  static Devotional? _cachedDevotional;
  static UserProfile? _cachedProfile;
  static DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 5);

  // Estado dinâmico
  ReadingProgress? _readingProgress;
  DailyVerse? _dailyVerse;
  Devotional? _devotional;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final cacheValid = _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl;

    if (!forceRefresh && cacheValid) {
      if (mounted) {
        setState(() {
          _readingProgress = _cachedProgress;
          _dailyVerse = _cachedVerse;
          _devotional = _cachedDevotional;
          _profile = _cachedProfile;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        _service.getReadingProgress(),
        _service.getDailyVerse(),
        _service.getTodayDevotional(),
        _service.getProfile(),
      ]);

      _cachedProgress = results[0] as ReadingProgress?;
      _cachedVerse = results[1] as DailyVerse?;
      _cachedDevotional = results[2] as Devotional?;
      _cachedProfile = results[3] as UserProfile?;
      _cacheTime = DateTime.now();

      if (mounted) {
        setState(() {
          _readingProgress = _cachedProgress;
          _dailyVerse = _cachedVerse;
          _devotional = _cachedDevotional;
          _profile = _cachedProfile;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError && _dailyVerse == null
                ? _buildErrorWidget()
                : RefreshIndicator(
                onRefresh: () => _loadData(forceRefresh: true),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Header (Nome + Streak dinâmico)
                                HomeHeader(
                                  displayName: _profile?.fullName ?? 'Visitante',
                                  streak: _readingProgress?.currentStreak ?? 0,
                                ),
                                const SizedBox(height: 24),

                                // 2. Versículo do Dia (dinâmico)
                                DailyVerseCard(
                                  verseText: _dailyVerse?.text,
                                  reference: _dailyVerse?.reference,
                                ),
                                const SizedBox(height: 24),

                                // 3. Continuar Leitura (dinâmico)
                                ContinueReadingCard(
                                  book: _readingProgress?.book ?? 'Gênesis',
                                  chapter: _readingProgress?.chapter ?? 1,
                                  onTap: () {
                                    if (widget.onNavigateToVerse != null) {
                                      widget.onNavigateToVerse!(
                                        _readingProgress?.book ?? 'Gênesis',
                                        _readingProgress?.chapter ?? 1,
                                        _readingProgress?.verse ?? 1,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),

                                // 4. Devocional Diário (dinâmico)
                                DailyDevotionalCard(
                                  title: _devotional?.title,
                                  content: _devotional?.content,
                                  readingTimeMin: _devotional?.readingTimeMin ?? 3,
                                  publishDate: _devotional?.publishDate,
                                  devotionalId: _devotional?.id,
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sem ligação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Não foi possível carregar os dados.\nVerifique a sua ligação à internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _loadData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
