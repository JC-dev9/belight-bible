import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para mudar a cor da barra de status do telemóvel
import 'bible_screen.dart';
import 'chatbot_screen.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  ReadingTheme _bibleTheme = ReadingTheme.light;

  void _updateBibleTheme(ReadingTheme newTheme) {
    setState(() {
      _bibleTheme = newTheme;
    });
  }

  // Helper para obter cores baseadas no tema
  Color get _backgroundColor {
    switch (_bibleTheme) {
      case ReadingTheme.dark: return AppColors.darkBg;
      case ReadingTheme.sepia: return AppColors.sepiaBg;
      default: return Colors.white;
    }
  }

  Color get _navBarColor {
    // Se estiver no Chatbot e for modo escuro do sistema, usa escuro
    // Caso contrário, respeita o tema da Bíblia
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (_currentIndex == 1 && isSystemDark) return Colors.grey.shade900;
    
    switch (_bibleTheme) {
      case ReadingTheme.sepia: return AppColors.navSepia;
      case ReadingTheme.dark: return AppColors.navDark;
      default: return Colors.white;
    }
  }

  Color get _contentColor {
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (_currentIndex == 1) return isSystemDark ? Colors.grey.shade400 : Colors.black87;

    switch (_bibleTheme) {
      case ReadingTheme.dark: return Colors.grey.shade400;
      case ReadingTheme.sepia: return AppColors.sepiaText;
      default: return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.yellow.shade800;

    // Ajusta a cor dos ícones da barra de status (bateria, hora, wifi)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _backgroundColor,
      statusBarIconBrightness: _bibleTheme == ReadingTheme.dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      // AQUI ESTÁ O TRUQUE: AnimatedContainer como corpo principal
      // Ele pinta o fundo de toda a app suavemente
      backgroundColor: Colors.transparent, 
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: _backgroundColor, // A cor de fundo global
        child: IndexedStack(
          index: _currentIndex,
          children: [
            BibleReaderScreen(
              currentTheme: _bibleTheme,
              onThemeChanged: _updateBibleTheme,
            ),
            // Se quiseres que o Chatbot tenha fundo próprio, define a cor dentro dele.
            // Se o Chatbot for transparente, ele herdará a cor sépia/escura daqui.
            const ChatBotScreen(),
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
            return TextStyle(color: color, fontWeight: FontWeight.w500);
          }),
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          tween: ColorTween(begin: Colors.white, end: _navBarColor),
          builder: (context, color, child) {
            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              height: 80,
              elevation: 0,
              backgroundColor: color,
              indicatorColor: primaryColor.withOpacity(0.15),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Bíblia',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'Chatbot',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}