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

  // Estado dinâmico
  ReadingProgress? _readingProgress;
  DailyVerse? _dailyVerse;
  Devotional? _devotional;
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.getReadingProgress(),
      _service.getDailyVerse(),
      _service.getTodayDevotional(),
      _service.getProfile(),
    ]);

    if (mounted) {
      setState(() {
        _readingProgress = results[0] as ReadingProgress?;
        _dailyVerse = results[1] as DailyVerse?;
        _devotional = results[2] as Devotional?;
        _profile = results[3] as UserProfile?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
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
}
