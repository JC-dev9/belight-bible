import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bible_screen.dart';
import 'chatbot_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/plans_tab.dart';
import 'tabs/menu_tab.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0=Home, 1=Bible, 2=Plans, 3=Chatbot, 4=Menu
  ReadingTheme _bibleTheme = ReadingTheme.light;
  
  // Keys
  final GlobalKey<ChatBotScreenState> _chatBotKey = GlobalKey<ChatBotScreenState>();
  final GlobalKey<BibleReaderScreenState> _bibleKey = GlobalKey<BibleReaderScreenState>();

  void _updateBibleTheme(ReadingTheme newTheme) {
    setState(() {
      _bibleTheme = newTheme;
    });
  }

  void _switchToChatbot(String prompt) {
    setState(() {
      _currentIndex = 3; // Index do Chatbot
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _chatBotKey.currentState?.sendPrompt(prompt);
    });
  }

  void _navigateToVerse(String book, int chapter, int verse) {
    setState(() {
      _currentIndex = 1; // Index da Bíblia
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _bibleKey.currentState?.jumpToVerse(book, chapter, verse);
    });
  }

  // Helper para obter cores baseadas no tema (apenas para a aba da Bíblia)
  Color get _backgroundColor {
    // Se não estiver na aba da Bíblia (1), usa cores padrão ou do sistema
    if (_currentIndex != 1) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? AppColors.darkBg : Colors.grey.shade50;
    }

    switch (_bibleTheme) {
      case ReadingTheme.dark: return AppColors.darkBg;
      case ReadingTheme.sepia: return AppColors.sepiaBg;
      default: return Colors.white;
    }
  }

  Color get _navBarColor {
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    // Se não for Bíblia, usa adaptativo
    if (_currentIndex != 1) {
      return isSystemDark ? Colors.grey.shade900 : Colors.white;
    }
    
    switch (_bibleTheme) {
      case ReadingTheme.sepia: return AppColors.navSepia;
      case ReadingTheme.dark: return AppColors.navDark;
      default: return Colors.white;
    }
  }

  Color get _contentColor {
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    if (_currentIndex != 1) {
      return isSystemDark ? Colors.grey.shade400 : Colors.black87;
    }

    switch (_bibleTheme) {
      case ReadingTheme.dark: return Colors.grey.shade400;
      case ReadingTheme.sepia: return AppColors.sepiaText;
      default: return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.yellow.shade800;

    // Ajusta Status Bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _backgroundColor,
      statusBarIconBrightness: 
          (_currentIndex == 1 && _bibleTheme == ReadingTheme.dark) || 
          Theme.of(context).brightness == Brightness.dark
          ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: _backgroundColor,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // 0: Home
            const HomeTab(),
            
            // 1: Bíblia
            BibleReaderScreen(
              key: _bibleKey,
              currentTheme: _bibleTheme,
              onThemeChanged: _updateBibleTheme,
              onAskAI: _switchToChatbot,
            ),
            
            // 2: Planos
            const PlansTab(),
            
            // 3: Chatbot (IA)
            ChatBotScreen(
              key: _chatBotKey, 
              onNavigateToVerse: _navigateToVerse
            ),
            
            // 4: Menu (Mais)
            MenuTab(
              currentTheme: _bibleTheme,
              onNavigateToVerse: _navigateToVerse,
              onDataChanged: () {
                 // Quando algo muda em Salvos (delete/edit), recarrega a bíblia
                 _bibleKey.currentState?.refreshData();
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: MaterialStateProperty.resolveWith((states) {
            final color = states.contains(MaterialState.selected)
                ? primaryColor
                : _contentColor;
            return IconThemeData(color: color, size: 24);
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final color = states.contains(MaterialState.selected)
                ? primaryColor
                : _contentColor;
            return TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12);
          }),
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          tween: ColorTween(begin: Colors.white, end: _navBarColor),
          builder: (context, color, child) {
            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) { 
                setState(() => _currentIndex = index);
              },
              height: 70, // Slightly more compact
              elevation: 0,
              backgroundColor: color,
              indicatorColor: primaryColor.withOpacity(0.15),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Bíblia',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Planos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'IA',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: 'Mais',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
