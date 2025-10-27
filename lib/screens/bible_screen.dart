import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// --- SIMULAÇÃO DA API DA BÍBLIA EM PORTUGUÊS ---
// No mundo real, você usaria o pacote 'http' ou 'dio' para
// fazer uma chamada REST para um serviço como Supabase, Firebase ou uma API de terceiros.

import 'dart:convert';
import 'package:http/http.dart' as http;

class BibleApi {
  final String translation;

  BibleApi({this.translation = 'almeida'});

  // Mapagem de livros e capítulos da Bíblia (mantida)
  static final Map<String, int> chaptersPerBook = {
    'Gênesis': 50, 'Êxodo': 40, 'Levítico': 27, 'Números': 36, 'Deuteronômio': 34,
    'Josué': 24, 'Juízes': 21, 'Rute': 4, '1 Samuel': 31, '2 Samuel': 24,
    '1 Reis': 22, '2 Reis': 25, '1 Crônicas': 29, '2 Crônicas': 36, 'Esdras': 10,
    'Neemias': 13, 'Ester': 10, 'Jó': 42, 'Salmos': 150, 'Provérbios': 31,
    'Eclesiastes': 12, 'Cantares': 8, 'Isaías': 66, 'Jeremias': 52, 'Lamentações': 5,
    'Ezequiel': 48, 'Daniel': 12, 'Oseias': 14, 'Joel': 3, 'Amós': 9,
    'Obadias': 1, 'Jonas': 4, 'Miqueias': 7, 'Naum': 3, 'Habacuque': 3,
    'Sofonias': 3, 'Ageu': 2, 'Zacarias': 14, 'Malaquias': 4,
    'Mateus': 28, 'Marcos': 16, 'Lucas': 24, 'João': 21, 'Atos': 28,
    'Romanos': 16, '1 Coríntios': 16, '2 Coríntios': 13, 'Gálatas': 6, 'Efésios': 6,
    'Filipenses': 4, 'Colossenses': 4, '1 Tessalonicenses': 5, '2 Tessalonicenses': 3,
    '1 Timóteo': 6, '2 Timóteo': 4, 'Tito': 3, 'Filemom': 1, 'Hebreus': 13,
    'Tiago': 5, '1 Pedro': 5, '2 Pedro': 3, '1 João': 5, '2 João': 1,
    '3 João': 1, 'Judas': 1, 'Apocalipse': 22,
  };

  static List<String> get allBooks => chaptersPerBook.keys.toList();

  /// Busca capítulo na Bible API
  Future<List<Map<String, dynamic>>> fetchChapter(String book, int chapter) async {
    final url = Uri.parse(
        'https://bible-api.com/${Uri.encodeComponent(book)} $chapter?translation=$translation');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['verses'] != null) {
        return List<Map<String, dynamic>>.from(data['verses'].map((v) => {
              'number': v['verse'],
              'text': v['text'],
              'highlighted': false,
              'note': '',
            }));
      } else {
        // Se não houver versículos, retorna lista vazia
        return [];
      }
    } else {
      throw Exception('Erro ao carregar capítulo: ${response.statusCode}');
    }
  }
}


// -----------------------------------------------------------------

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  String selectedBook = 'Gênesis';
  int selectedChapter = 1;
  bool isAudioPlaying = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> verses = [];
  final BibleApi _api = BibleApi(translation: 'almeida'); // português


  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  // --- Lógica de Carregamento da Bíblia ---
  Future<void> _loadChapter() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simula a busca do capítulo na API
      final newVerses = await _api.fetchChapter(selectedBook, selectedChapter);
      setState(() {
        verses = newVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        verses = [];
      });
      _showSnackBar('Erro ao carregar o capítulo. Verifique a conexão.', isError: true);
    }
  }

  // --- Funções de Navegação ---

  void _previousChapter() {
    if (selectedChapter > 1) {
      setState(() {
        selectedChapter--;
      });
      _loadChapter();
    } else {
      _showSnackBar('Você está no primeiro capítulo!');
    }
  }

  void _nextChapter() {
    final maxChapters = BibleApi.chaptersPerBook[selectedBook] ?? 1;
    if (selectedChapter < maxChapters) {
      setState(() {
        selectedChapter++;
      });
      _loadChapter();
    } else {
      _showSnackBar('Você chegou ao último capítulo de $selectedBook!');
    }
  }

  void _onBookSelected(String book) {
    setState(() {
      selectedBook = book;
      selectedChapter = 1;
    });
    Navigator.pop(context);
    _loadChapter();
  }

  void _onChapterSelected(int chapter) {
    setState(() {
      selectedChapter = chapter;
    });
    Navigator.pop(context);
    _loadChapter();
  }

  // --- UX/UI e Interações ---

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVerseOptionsModal(int verseIndex) {
    final verse = verses[verseIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle de arrastar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$selectedBook $selectedChapter:${verse['number']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.copy,
              label: 'Copiar',
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: '$selectedBook $selectedChapter:${verse['number']} - ${verse['text']}',
                ));
                Navigator.pop(context);
                _showSnackBar('Versículo copiado!');
              },
            ),
            _buildOptionTile(
              icon: Icons.share,
              label: 'Partilhar',
              onTap: () {
                Navigator.pop(context);
                Share.share('$selectedBook $selectedChapter:${verse['number']} - ${verse['text']}');
              },
            ),
            _buildOptionTile(
              icon: Icons.highlight,
              label: verse['highlighted'] ? 'Remover Destaque' : 'Destacar',
              onTap: () {
                setState(() {
                  verses[verseIndex]['highlighted'] = !verse['highlighted'];
                });
                Navigator.pop(context);
                _showSnackBar(verse['highlighted'] ? 'Versículo destacado!' : 'Destaque removido.');
                // *Aqui seria o ponto de chamada para a API para salvar o destaque no DB.*
              },
            ),
            _buildOptionTile(
              icon: Icons.note_add_outlined,
              label: verse['note'].isNotEmpty ? 'Ver/Editar Anotação' : 'Anotar',
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(verseIndex);
              },
            ),
            _buildOptionTile(
              icon: Icons.lightbulb_outline,
              label: 'Estudo/Explicação',
              onTap: () {
                Navigator.pop(context);
                _showExplanationDialog(verse);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.yellow.shade700),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(int verseIndex) {
    final controller = TextEditingController(text: verses[verseIndex]['note']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${selectedBook} ${selectedChapter}:${verses[verseIndex]['number']} - Anotar'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Digite sua anotação...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                verses[verseIndex]['note'] = controller.text;
              });
              Navigator.pop(context);
              _showSnackBar('Anotação salva!');
              // *Aqui seria o ponto de chamada para a API para salvar a anotação no DB.*
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showExplanationDialog(Map<String, dynamic> verse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${selectedBook} ${selectedChapter}:${verse['number']} - Estudo'),
        content: const SingleChildScrollView(
          child: Text(
            '**Explicação IA Simples:** Este versículo fala sobre a criação do mundo por Deus, '
            'estabelecendo o poder e a soberania divina. (Em um app real, '
            'essa explicação viria de uma base de dados teológica ou IA.)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // --- Seletores de Livro e Capítulo (Bottom Sheets) ---

  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // Aumentado para melhor visualização
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Selecionar Livro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: BibleApi.allBooks.length,
                itemBuilder: (context, index) {
                  final book = BibleApi.allBooks[index];
                  return ListTile(
                    title: Text(book),
                    trailing: book == selectedBook
                        ? Icon(Icons.check_circle, color: Colors.yellow.shade700)
                        : null,
                    onTap: () => _onBookSelected(book),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterSelector() {
    final maxChapters = BibleApi.chaptersPerBook[selectedBook] ?? 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Capítulos de $selectedBook',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: maxChapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final isSelected = chapter == selectedChapter;
                  return InkWell(
                    onTap: () => _onChapterSelected(chapter),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellow.shade700
                            : Theme.of(context).cardColor,
                        border: Border.all(
                          color: isSelected
                              ? Colors.yellow.shade700
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.black
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Principal (Build) ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.menu), // Trocado para ícone de menu/configurações
          onPressed: () => _showSnackBar('Configurações/Menu lateral em desenvolvimento'),
        ),
        title: GestureDetector(
          onTap: _showBookSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedBook,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_down, size: 24),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSnackBar('Busca avançada em desenvolvimento'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor e Navegação de Capítulo (Melhorado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 30),
                  onPressed: _previousChapter,
                ),
                GestureDetector(
                  onTap: _showChapterSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Capítulo $selectedChapter',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 30),
                  onPressed: _nextChapter,
                ),
              ],
            ),
          ),
          
          // Indicador de Carregamento ou Lista de Versículos
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.yellow.shade700),
                        const SizedBox(height: 16),
                        const Text('Carregando versículos...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      final verse = verses[index];
                      return GestureDetector(
                        // Ao tocar no versículo, mostra o modal de opções
                        onTap: () => _showVerseOptionsModal(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            // Destaque mais sutil
                            color: verse['highlighted']
                                ? Colors.yellow.withOpacity(isDark ? 0.2 : 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            // Borda se houver anotação
                            border: verse['note'].isNotEmpty
                                ? Border.all(color: Colors.yellow.shade700.withOpacity(0.5), width: 1.5)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    // Número do versículo em destaque
                                    TextSpan(
                                      text: '${verse['number']}. ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow.shade700,
                                      ),
                                    ),
                                    // Texto do versículo
                                    TextSpan(
                                      text: verse['text'],
                                      style: TextStyle(
                                        fontSize: 17, // Fonte maior para melhor leitura
                                        height: 1.6,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Exibição da Anotação
                              if (verse['note'].isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.note_alt,
                                        size: 16,
                                        color: Colors.yellow.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Sua anotação: ${verse['note']}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // FAB para ir para a lista de versículos ou menu de leitura
      floatingActionButton: FloatingActionButton(
        onPressed: _showChapterSelector, // Usar para ir rapidamente para um capítulo
        backgroundColor: Colors.yellow.shade700,
        child: const Icon(Icons.format_list_numbered, color: Colors.black),
      ),
    );
  }
}