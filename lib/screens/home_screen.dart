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

  // Cor do NavigationBar: só usa tema bíblico na aba da Bíblia
  Color get _navBarColor {
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    
    if (_currentIndex != 1) {
      return isSystemDark ? Colors.grey.shade900 : Colors.white;
    }
    
    switch (_bibleTheme) {
      case ReadingTheme.sepia: return AppColors.navSepia;
      case ReadingTheme.dark: return AppColors.navDark;
      default: return Colors.white;
    }
  }

  // Cor dos ícones/labels do NavigationBar: só usa tema bíblico na aba da Bíblia
  Color get _navContentColor {
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
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;

    // Ajusta Status Bar baseado na aba atual
    final bool useLightIcons = 
        (_currentIndex == 1 && _bibleTheme == ReadingTheme.dark) || isSystemDark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: useLightIcons ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      // Cada aba tem o seu próprio Scaffold/background. Não forçamos cor aqui.
      backgroundColor: isSystemDark ? AppColors.darkBg : Colors.grey.shade50,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Home
          HomeTab(onNavigateToVerse: _navigateToVerse),
          
          // 1: Bíblia (gere o proprio tema internamente)
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
               _bibleKey.currentState?.refreshData();
            },
          ),
        ],
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? primaryColor
                : _navContentColor;
            return IconThemeData(color: color, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? primaryColor
                : _navContentColor;
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
              height: 70,
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
