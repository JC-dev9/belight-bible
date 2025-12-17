import 'package:flutter/material.dart';
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

  // Estado do tema da Bíblia
  ReadingTheme _bibleTheme = ReadingTheme.light;

  void _updateBibleTheme(ReadingTheme newTheme) {
    setState(() {
      _bibleTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Deteta o sistema do telemóvel
    final isSystemDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Cor de destaque (Amarelo) - Itens SELECIONADOS
    final Color primaryColor = Colors.yellow.shade800;

    // 2. Lógica para a cor de FUNDO da Barra
    Color? getNavBarBackgroundColor() {
      if (_currentIndex == 1) {
        // Aba Chatbot: Segue o sistema
        return isSystemDark ? Colors.grey.shade900 : Colors.white;
      }
      // Aba Bíblia: Segue o tema escolhido
      switch (_bibleTheme) {
        case ReadingTheme.sepia:
          return AppColors.navSepia;
        case ReadingTheme.dark:
          return AppColors.navDark;
        case ReadingTheme.light:
        default:
          return Colors.white;
      }
    }

    // 3. Lógica para a cor dos ÍCONES/TEXTO (O que pediste para corrigir)
    Color getContentColor() {
      // Se estiver na aba Chatbot, contraste padrão do sistema
      if (_currentIndex == 1) {
        return isSystemDark ? Colors.grey.shade400 : Colors.black87;
      }

      // Se estiver na aba Bíblia, contraste personalizado
      switch (_bibleTheme) {
        case ReadingTheme.dark:
          return Colors.grey.shade400; // Cinza claro no fundo escuro
        case ReadingTheme.sepia:
          return AppColors
              .sepiaText; // Castanho escuro no fundo bege (Fica elegante e legível)
        case ReadingTheme.light:
        default:
          return Colors
              .black87; // Preto quase puro no fundo branco (Resolve o teu problema)
      }
    }

    final contentColor = getContentColor();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BibleReaderScreen(
            currentTheme: _bibleTheme,
            onThemeChanged: _updateBibleTheme,
          ),
          const ChatBotScreen(),
        ],
      ),

      // Usamos NavigationBarTheme para forçar a cor dos textos também
      // ... dentro do return Scaffold( ...
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Animação suave também para a cor dos ícones/texto
          iconTheme: MaterialStateProperty.resolveWith((states) {
            // Usamos uma transição simples aqui, ou podemos deixar fixo
            // para não complicar demais, vamos focar na cor do conteúdo
            final color = states.contains(MaterialState.selected)
                ? primaryColor
                : getContentColor();
            return IconThemeData(
              color: color,
              size: 24,
            ); // Adicionei size para evitar pulos
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final color = states.contains(MaterialState.selected)
                ? primaryColor
                : getContentColor();
            return TextStyle(color: color, fontWeight: FontWeight.w500);
          }),
        ),

        // AQUI COMEÇA A ANIMAÇÃO DO FUNDO DA BARRA
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200), // Tempo da animação
          curve: Curves.easeInOut, // Curva de aceleração suave
          tween: ColorTween(
            begin: Colors
                .white, // Valor inicial (pode ser qualquer um, ele ajusta-se logo)
            end: getNavBarBackgroundColor(), // O DESTINO (a cor do tema atual)
          ),
          builder: (context, color, child) {
            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              height: 80,
              elevation: 0,
              backgroundColor: color, // A cor animada entra aqui
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
