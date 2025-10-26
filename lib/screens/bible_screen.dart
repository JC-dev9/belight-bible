import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  String selectedBook = 'Gênesis';
  int selectedChapter = 1;
  int selectedVerse = 1;
  bool isAudioPlaying = false;
  
  // Dados de exemplo - você deve substituir por dados reais do Supabase
  final List<String> books = [
    'Gênesis', 'Êxodo', 'Levítico', 'Números', 'Deuteronômio',
    'Josué', 'Juízes', 'Rute', '1 Samuel', '2 Samuel',
    'Mateus', 'Marcos', 'Lucas', 'João', 'Atos'
  ];
  
  final Map<String, int> chaptersPerBook = {
    'Gênesis': 50, 'Êxodo': 40, 'Levítico': 27, 'Números': 36,
    'Deuteronômio': 34, 'Josué': 24, 'Juízes': 21, 'Rute': 4,
    '1 Samuel': 31, '2 Samuel': 24, 'Mateus': 28, 'Marcos': 16,
    'Lucas': 24, 'João': 21, 'Atos': 28
  };
  
  // Versículos de exemplo - substituir por dados reais
  List<Map<String, dynamic>> verses = [
    {'number': 1, 'text': 'No princípio, Deus criou os céus e a terra.', 'highlighted': false, 'note': ''},
    {'number': 2, 'text': 'A terra era sem forma e vazia; havia trevas sobre a face do abismo, e o Espírito de Deus pairava sobre as águas.', 'highlighted': false, 'note': ''},
    {'number': 3, 'text': 'Disse Deus: Haja luz. E houve luz.', 'highlighted': false, 'note': ''},
    {'number': 4, 'text': 'Viu Deus que a luz era boa; e fez separação entre a luz e as trevas.', 'highlighted': false, 'note': ''},
    {'number': 5, 'text': 'Chamou Deus à luz Dia e às trevas, Noite. Houve tarde e manhã, o primeiro dia.', 'highlighted': false, 'note': ''},
  ];

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.bookmark_outline,
              label: 'Salvar',
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Versículo salvo!');
              },
            ),
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
              icon: Icons.lightbulb_outline,
              label: 'Explicar',
              onTap: () {
                Navigator.pop(context);
                _showExplanationDialog(verse);
              },
            ),
            _buildOptionTile(
              icon: Icons.highlight,
              label: verse['highlighted'] ? 'Remover sublinhado' : 'Sublinhar',
              onTap: () {
                setState(() {
                  verses[verseIndex]['highlighted'] = !verse['highlighted'];
                });
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              icon: Icons.note_add_outlined,
              label: 'Anotar',
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(verseIndex);
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
        title: const Text('Adicionar Anotação'),
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
        title: Text('$selectedBook $selectedChapter:${verse['number']}'),
        content: const SingleChildScrollView(
          child: Text(
            'Esta é uma explicação de exemplo do versículo. '
            'Aqui você pode adicionar comentários teológicos, '
            'contexto histórico e interpretações do texto bíblico.',
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBookSelector() {
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
            const Text(
              'Selecionar Livro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(books[index]),
                    trailing: books[index] == selectedBook
                        ? const Icon(Icons.check, color: Colors.yellow)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedBook = books[index];
                        selectedChapter = 1;
                      });
                      Navigator.pop(context);
                    },
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
    final maxChapters = chaptersPerBook[selectedBook] ?? 50;
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
            const Text(
              'Selecionar Capítulo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    onTap: () {
                      setState(() {
                        selectedChapter = chapter;
                      });
                      Navigator.pop(context);
                    },
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
                            color: isSelected ? Colors.black : null,
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

  void _previousChapter() {
    if (selectedChapter > 1) {
      setState(() {
        selectedChapter--;
      });
    }
  }

  void _nextChapter() {
    final maxChapters = chaptersPerBook[selectedBook] ?? 50;
    if (selectedChapter < maxChapters) {
      setState(() {
        selectedChapter++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSnackBar('Busca em desenvolvimento');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showSnackBar('Mais opções em desenvolvimento');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de capítulo
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
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousChapter,
                ),
                GestureDetector(
                  onTap: _showChapterSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Capítulo ',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$selectedChapter',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextChapter,
                ),
              ],
            ),
          ),
          
          // Botão de áudio
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isAudioPlaying = !isAudioPlaying;
                });
                _showSnackBar(
                  isAudioPlaying ? 'Reproduzindo áudio...' : 'Áudio pausado',
                );
              },
              icon: Icon(
                isAudioPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
              label: Text(
                isAudioPlaying ? 'Pausar Áudio' : 'Reproduzir Áudio',
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          
          // Lista de versículos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                return GestureDetector(
                  onTap: () => _showVerseOptionsModal(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: verse['highlighted']
                          ? Colors.yellow.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: verse['note'].isNotEmpty
                          ? Border.all(color: Colors.yellow.shade700, width: 1)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${verse['number']} ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade700,
                                ),
                              ),
                              TextSpan(
                                text: verse['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (verse['note'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade700.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Colors.yellow.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    verse['note'],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnackBar('Ir para versículo específico');
        },
        backgroundColor: Colors.yellow.shade700,
        child: const Icon(Icons.format_list_numbered, color: Colors.black),
      ),
    );
  }
}