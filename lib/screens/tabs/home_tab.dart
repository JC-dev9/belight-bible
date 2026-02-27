import 'package:flutter/material.dart';
import '../../data/supabase_service.dart';
import '../../data/models/dynamic_models.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/daily_verse_card.dart';
import '../../widgets/home/continue_reading_card.dart';
import '../../widgets/home/daily_devotional_card.dart';

/// Aba principal — carrega dados dinâmicos do Supabase e passa para os widgets.
/// Recarrega automaticamente sempre que se torna visível.
class HomeTab extends StatefulWidget {
  final Function(String book, int chapter, int verse)? onNavigateToVerse;

  const HomeTab({super.key, this.onNavigateToVerse});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final SupabaseService _service = SupabaseService();

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

  /// Método público para recarregar dados externamente.
  Future<void> refreshData() async => _loadData();

  Future<void> _loadData() async {
    try {
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber))
            : RefreshIndicator(
                color: Colors.amber,
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // 1. Header
                          HomeHeader(
                            displayName: _profile?.fullName ?? 'Visitante',
                            streak: _readingProgress?.currentStreak ?? 0,
                          ),
                          const SizedBox(height: 20),

                          // 2. Continuar Leitura
                          ContinueReadingCard(
                            progress: _readingProgress,
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
                          const SizedBox(height: 20),

                          // 3. Versículo do Dia
                          DailyVerseCard(verse: _dailyVerse),
                          const SizedBox(height: 20),

                          // 4. Devocional Diário
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: DailyDevotionalCard(
                              title: _devotional?.title,
                              content: _devotional?.content,
                              readingTimeMin:
                                  _devotional?.readingTimeMin ?? 3,
                              publishDate: _devotional?.publishDate,
                              devotionalId: _devotional?.id,
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
