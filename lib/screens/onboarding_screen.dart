import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show HiveKeys;
import '../utils/theme.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const List<_OnboardPage> _pages = [
  _OnboardPage(
    icon: Icons.menu_book_rounded,
    title: 'Bem-vindo ao BeLight Bible',
    description:
        'Leia a Bíblia em várias versões — ACF, ARC e NTLH — sempre disponíveis, mesmo sem ligação à internet.',
  ),
  _OnboardPage(
    icon: Icons.auto_awesome_rounded,
    title: 'Marque, anote e partilhe',
    description:
        'Realce versículos com cores, escreva anotações pessoais e partilhe a Palavra com quem ama.',
  ),
  _OnboardPage(
    icon: Icons.chat_bubble_rounded,
    title: 'Estudo com IA',
    description:
        'Pergunte sobre qualquer versículo e receba contexto, ligações e explicações em linguagem clara.',
  ),
  _OnboardPage(
    icon: Icons.calendar_today_rounded,
    title: 'Planos e devocionais',
    description:
        'Crie rotinas de leitura, mantenha o seu streak diário e receba o versículo do dia.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    await Hive.box(HiveKeys.settingsBox).put(HiveKeys.onboardingCompleted, true);
    if (!mounted) return;
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;
    Navigator.of(context).pushNamedAndRemoveUntil(
      hasSession ? '/home' : '/',
      (route) => false,
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTheme.accentGold;
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Botão "Saltar"
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(foregroundColor: mutedColor),
                  child: const Text('Saltar'),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardPageView(
                  page: _pages[i],
                  accent: accent,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ),

            // Indicadores
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: i == _index ? accent : mutedColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Botão principal
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    _isLast ? 'Começar' : 'Próximo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  const _OnboardPageView({
    required this.page,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: accent),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
