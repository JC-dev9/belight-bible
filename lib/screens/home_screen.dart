import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para mudar a cor da barra de status do telemóvel
import 'bible_screen.dart';
import 'chatbot_screen.dart';
import 'saved_data_screen.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  ReadingTheme _bibleTheme = ReadingTheme.light;
  
  // Key para acessar o estado do ChatBot
  final GlobalKey<ChatBotScreenState> _chatBotKey = GlobalKey<ChatBotScreenState>();
  // Key para acessar o estado da Bíblia
  final GlobalKey<BibleReaderScreenState> _bibleKey = GlobalKey<BibleReaderScreenState>();
  // Key para acessar o estado de Salvos (Auto-Refresh)
  final GlobalKey<SavedDataScreenState> _savedDataKey = GlobalKey<SavedDataScreenState>();

  void _updateBibleTheme(ReadingTheme newTheme) {
    setState(() {
      _bibleTheme = newTheme;
    });
  }

  void _switchToChatbot(String prompt) {
    setState(() {
      _currentIndex = 1; // Muda para a tab do Chatbot
    });
    
    // Pequeno delay para garantir que a tab mudou e o widget foi montado/exibido
    Future.delayed(const Duration(milliseconds: 100), () {
      _chatBotKey.currentState?.sendPrompt(prompt);
    });
  }

  void _navigateToVerse(String book, int chapter, int verse) {
    setState(() {
      _currentIndex = 0; // Muda para a tab da Bíblia
    });

    // Aguarda a troca de tab e chama o jump
    Future.delayed(const Duration(milliseconds: 100), () {
      _bibleKey.currentState?.jumpToVerse(book, chapter, verse);
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
    // Se estiver no Chatbot ou Salvos, e for modo escuro do sistema, usa escuro
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    if ((_currentIndex == 1 || _currentIndex == 2) && isSystemDark) return Colors.grey.shade900;
    
    switch (_bibleTheme) {
      case ReadingTheme.sepia: return AppColors.navSepia;
      case ReadingTheme.dark: return AppColors.navDark;
      default: return Colors.white;
    }
  }

  Color get _contentColor {
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    // Chatbot (index 1) e Salvos (index 2) podem usar system dark se system for dark
    if (_currentIndex == 1 || _currentIndex == 2) return isSystemDark ? Colors.grey.shade400 : Colors.black87;

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
              key: _bibleKey,
              currentTheme: _bibleTheme,
              onThemeChanged: _updateBibleTheme,
              onAskAI: _switchToChatbot, // Passando a callback
            ),
            // Se quiseres que o Chatbot tenha fundo próprio, define a cor dentro dele.
            // Se o Chatbot for transparente, ele herdará a cor sépia/escura daqui.
            ChatBotScreen(
              key: _chatBotKey, 
              onNavigateToVerse: _navigateToVerse
            ), // Atribuindo a Key
            SavedDataScreen(
              key: _savedDataKey, // Key para refresh
              currentTheme: _bibleTheme,
              onNavigateToVerse: _navigateToVerse,
              onDataChanged: () {
                 // Quando algo muda em Salvos (delete/edit), recarrega a bíblia
                 // para atualizar os grifos e notas visualmente
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
              onDestinationSelected: (index) { 
                setState(() => _currentIndex = index);
                // AUTO REFRES HLOGIC
                if (index == 2) {
                  _savedDataKey.currentState?.refreshData();
                }
              },
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
                NavigationDestination(
                  icon: Icon(Icons.bookmarks_outlined),
                  selectedIcon: Icon(Icons.bookmarks),
                  label: 'Salvos',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}