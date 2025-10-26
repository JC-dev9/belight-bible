import 'package:flutter/material.dart';
import 'bible_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BibleReaderScreen(),
    const ChatBotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Definindo as cores para melhor clareza e reutilização
    final Color primaryColor = Colors.yellow.shade700;
    final Color unselectedItemColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return Scaffold(
      
      body: _screens[_currentIndex],
      
      // 1. Substituição do BottomNavigationBar pelo NavigationBar (Material 3)
      bottomNavigationBar: NavigationBar(
        // Propriedades de controle e eventos
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        
        // Propriedades de estilo
        height: 80, // A altura padrão do M3, semelhante ao do vídeo
        elevation: 0, // Remove a sombra
        
        // Define a cor do indicador em formato de pílula
        indicatorColor: primaryColor.withOpacity(0.2), // Um amarelo claro para o fundo do item selecionado

        // 2. Definição dos destinos (itens) da navegação
        destinations: [
          NavigationDestination(
            // Ícone para o estado não selecionado
            icon: Icon(Icons.menu_book_outlined, color: unselectedItemColor),
            // Ícone para o estado selecionado (opcional, mas comum no M3)
            selectedIcon: Icon(Icons.menu_book, color: primaryColor),
            label: 'Bíblia',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: unselectedItemColor),
            selectedIcon: Icon(Icons.chat_bubble, color: primaryColor),
            label: 'Chatbot',
          ),
        ],
      ),
    );
  }
}