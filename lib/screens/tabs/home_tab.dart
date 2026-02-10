import 'package:flutter/material.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/daily_verse_card.dart';
import '../../widgets/home/continue_reading_card.dart';
import '../../widgets/home/daily_devotional_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 20.0), // Increased top padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header (Greeting + Streak)
                    const HomeHeader(),
                    const SizedBox(height: 24),

                    // 2. Daily Verse (Impact)
                    const DailyVerseCard(),
                    const SizedBox(height: 24),

                    // 3. Continue Reading (Utility)
                    ContinueReadingCard(
                      onTap: () {
                        // TODO: Implement Logic to jump to last read
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Continuar leitura em breve...')),
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    // 4. Daily Devotional (Content)
                    const DailyDevotionalCard(),
                    const SizedBox(height: 80), // Bottom padding for NavBar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context) {
    // Mock days: M T W T F S S
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final completed = [true, true, true, false, false, false, false]; // Mock data

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isCompleted = completed[index];
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Theme.of(context).dividerColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isCompleted ? null : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: isCompleted 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }
}
