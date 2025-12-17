import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/theme.dart'; // Certifique-se que este arquivo existe na mesma pasta

// ============================================================================
// 1. API DA BÍBLIA
// ============================================================================

class BibleApi {
  final String translation;

  BibleApi({this.translation = 'almeida'});

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

  Future<List<Map<String, dynamic>>> fetchChapter(String book, int chapter) async {
    final url = Uri.parse(
        'https://bible-api.com/${Uri.encodeComponent(book)} $chapter?translation=$translation');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['verses'] != null) {
          return List<Map<String, dynamic>>.from(data['verses'].map((v) => {
                'number': v['verse'],
                'text': v['text'].toString().trim(),
                'highlighted': false,
                'note': '',
              }));
        }
      }
      return [];
    } catch (e) {
      throw Exception('Falha na conexão');
    }
  }
}

// ============================================================================
// 2. TELA DA BÍBLIA
// ============================================================================

class BibleReaderScreen extends StatefulWidget {
  // Parâmetros recebidos da HomeScreen
  final ReadingTheme currentTheme;
  final Function(ReadingTheme) onThemeChanged;

  const BibleReaderScreen({
    super.key, 
    required this.currentTheme, 
    required this.onThemeChanged
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  // Estado de Dados
  final BibleApi _api = BibleApi(translation: 'almeida');
  String selectedBook = 'Gênesis';
  int selectedChapter = 1;
  List<Map<String, dynamic>> verses = [];
  bool _isLoading = true;

  // Estado de UI Local
  double _fontSize = 18.0;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Lógica de Dados ---

  Future<void> _loadChapter() async {
    setState(() => _isLoading = true);
    try {
      final newVerses = await _api.fetchChapter(selectedBook, selectedChapter);
      setState(() {
        verses = newVerses;
        _isLoading = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        verses = [];
      });
      _showSnackBar('Erro de conexão.', isError: true, action: _loadChapter);
    }
  }

  void _navigateChapter(int delta) {
    final maxChapters = BibleApi.chaptersPerBook[selectedBook] ?? 1;
    final newChapter = selectedChapter + delta;

    if (newChapter >= 1 && newChapter <= maxChapters) {
      setState(() => selectedChapter = newChapter);
      _loadChapter();
    } else if (newChapter > maxChapters) {
      _showSnackBar('Último capítulo de $selectedBook.');
    }
  }

  // --- Helpers de Estilo (Baseados no Tema Atual) ---

  Color get _backgroundColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark: return AppColors.darkBg;
      case ReadingTheme.sepia: return AppColors.sepiaBg;
      default: return Colors.white;
    }
  }

  Color get _textColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark: return Colors.grey.shade300;
      case ReadingTheme.sepia: return AppColors.sepiaText;
      default: return Colors.grey.shade900;
    }
  }

  Color get _verseNumColor {
     switch (widget.currentTheme) {
      case ReadingTheme.dark: return Colors.grey.shade600;
      case ReadingTheme.sepia: return AppColors.sepiaAccent;
      default: return Colors.grey.shade500;
    }
  }

  // --- Widgets da UI ---

  @override
  Widget build(BuildContext context) {
    // 1. Animação do Fundo da Tela
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      tween: ColorTween(
        begin: Colors.white, 
        end: _backgroundColor, // Destino da cor de fundo
      ),
      builder: (context, animatedBgColor, child) {
        
        // 2. Animação da Cor do Texto
        return TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          tween: ColorTween(
            begin: Colors.black, 
            end: _textColor // Destino da cor do texto
          ),
          builder: (context, animatedTextColor, _) {
            
            return Scaffold(
              backgroundColor: animatedBgColor, // Fundo animado
              body: SafeArea(
                child: Column(
                  children: [
                    // Passamos as cores animadas para os componentes
                    _buildHeader(
                      bgColor: animatedBgColor!, 
                      textColor: animatedTextColor!
                    ),
                    
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingSkeleton()
                          : verses.isEmpty
                              ? _buildErrorState(animatedTextColor)
                              : _buildVersesList(animatedTextColor),
                    ),
                    
                    _buildBottomControls(
                      bgColor: animatedBgColor, 
                      textColor: animatedTextColor
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildHeader({required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: textColor.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.text_format, color: textColor),
            onPressed: _showDisplaySettings,
            tooltip: 'Ajustar texto',
          ),
          GestureDetector(
            onTap: _showBookSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    selectedBook,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: textColor),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () => _showSnackBar('Busca em breve!'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList(Color animatedTextColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      itemCount: verses.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final verse = verses[index];
        final isHighlighted = verse['highlighted'] == true;
        final hasNote = verse['note'].toString().isNotEmpty;

        return GestureDetector(
          onTap: () => _showVerseOptionsModal(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted 
                  ? AppColors.highlightColor.withOpacity(widget.currentTheme == ReadingTheme.dark ? 0.3 : 0.4) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: hasNote ? Border(left: BorderSide(color: Colors.orange, width: 3)) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.6,
                      color: animatedTextColor, // Usa a cor animada
                      fontFamily: 'Georgia',
                    ),
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -4),
                          child: Text(
                            '${verse['number']} ',
                            style: TextStyle(fontSize: _fontSize * 0.6, fontWeight: FontWeight.bold, color: _verseNumColor),
                          ),
                        ),
                      ),
                      TextSpan(text: verse['text']),
                    ],
                  ),
                ),
                if (hasNote) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            verse['note'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: animatedTextColor.withOpacity(0.7), fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls({required Color bgColor, required Color textColor}) {
    final isFirst = selectedChapter == 1;
    final maxChapters = BibleApi.chaptersPerBook[selectedBook] ?? 1;
    final isLast = selectedChapter == maxChapters;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            label: 'Anterior',
            color: textColor,
            onTap: isFirst ? null : () => _navigateChapter(-1),
          ),
          GestureDetector(
            onTap: _showChapterSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'Capítulo $selectedChapter',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right,
            label: 'Próximo',
            color: textColor,
            isRight: true,
            onTap: isLast ? null : () => _navigateChapter(1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required String label, required Color color, required VoidCallback? onTap, bool isRight = false}) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: CircularProgressIndicator(
        color: widget.currentTheme == ReadingTheme.sepia ? AppColors.sepiaAccent : Colors.blueGrey,
      ),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Não foi possível carregar.', style: TextStyle(color: textColor)),
          TextButton(onPressed: _loadChapter, child: const Text('Tentar Novamente'))
        ],
      ),
    );
  }

  // --- Modais ---

  void _showDisplaySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // StatefulBuilder para atualizar o modal internamente
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Color getModalBg() {
              switch (widget.currentTheme) {
                case ReadingTheme.dark: return AppColors.darkSurface;
                case ReadingTheme.sepia: return AppColors.sepiaBg;
                default: return Colors.white;
              }
            }
            
            Color getModalText() {
              switch (widget.currentTheme) {
                case ReadingTheme.dark: return Colors.white;
                case ReadingTheme.sepia: return AppColors.sepiaText;
                default: return Colors.black;
              }
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: getModalBg(),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aparência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: getModalText())),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(Icons.text_fields, size: 16, color: getModalText()),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 30,
                          divisions: 18,
                          activeColor: widget.currentTheme == ReadingTheme.sepia ? AppColors.sepiaAccent : Colors.blue,
                          inactiveColor: getModalText().withOpacity(0.2),
                          label: _fontSize.round().toString(),
                          onChanged: (val) {
                            this.setState(() => _fontSize = val);
                            setModalState(() {}); 
                          },
                        ),
                      ),
                      Icon(Icons.text_fields, size: 28, color: getModalText()),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text('Tema', style: TextStyle(fontWeight: FontWeight.w600, color: getModalText())),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeOptionInternal(setModalState, ReadingTheme.light, Colors.white, Colors.black, 'Claro', getModalText()),
                      _buildThemeOptionInternal(setModalState, ReadingTheme.sepia, AppColors.sepiaBg, AppColors.sepiaText, 'Papel', getModalText()),
                      _buildThemeOptionInternal(setModalState, ReadingTheme.dark, AppColors.darkBg, Colors.white, 'Escuro', getModalText()),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionInternal(StateSetter setModalState, ReadingTheme theme, Color bg, Color text, String label, Color labelColor) {
    final isSelected = widget.currentTheme == theme;
    return GestureDetector(
      onTap: () {
        // AVISO AO PAI (HomeScreen) para mudar o tema e a cor da barra
        widget.onThemeChanged(theme);
        setModalState(() {}); // Atualiza o modal
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? (theme == ReadingTheme.sepia ? AppColors.sepiaAccent : Colors.blue) : Colors.grey.shade400,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [if(isSelected) BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
            ),
            child: Center(
              child: Text('Aa', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        ],
      ),
    );
  }

  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Livros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: BibleApi.allBooks.length,
                  itemBuilder: (context, index) {
                    final book = BibleApi.allBooks[index];
                    final isSelected = book == selectedBook;
                    return ListTile(
                      title: Text(book, style: TextStyle(color: isSelected ? Colors.blue : _textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        setState(() {
                          selectedBook = book;
                          selectedChapter = 1;
                        });
                        Navigator.pop(context);
                        _loadChapter();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Capítulos de $selectedBook', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: maxChapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final isSelected = chapter == selectedChapter;
                  return InkWell(
                    onTap: () {
                      setState(() => selectedChapter = chapter);
                      Navigator.pop(context);
                      _loadChapter();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : _textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : Border.all(color: _textColor.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textColor,
                            fontWeight: FontWeight.bold,
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

  void _showVerseOptionsModal(int verseIndex) {
    final verse = verses[verseIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
             Text('$selectedBook $selectedChapter:${verse['number']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionIcon(Icons.copy, 'Copiar', () {
                  Clipboard.setData(ClipboardData(text: '${verse['text']} ($selectedBook $selectedChapter:${verse['number']})'));
                  Navigator.pop(context);
                  _showSnackBar('Versículo copiado');
                }),
                _buildOptionIcon(Icons.share, 'Partilhar', () {
                  Navigator.pop(context);
                  Share.share('${verse['text']} ($selectedBook $selectedChapter:${verse['number']})');
                }),
                _buildOptionIcon(Icons.highlight, 'Destacar', () {
                  setState(() => verses[verseIndex]['highlighted'] = !verses[verseIndex]['highlighted']);
                  Navigator.pop(context);
                }),
                _buildOptionIcon(Icons.edit_note, 'Anotar', () {
                  Navigator.pop(context);
                  _showNoteDialog(verseIndex);
                }),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _textColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _textColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: _textColor, fontSize: 12)),
        ],
      ),
    );
  }

  void _showNoteDialog(int index) {
    final controller = TextEditingController(text: verses[index]['note']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Anotação', style: TextStyle(color: _textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _textColor),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escreva sua reflexão...',
            hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
            filled: true,
            fillColor: _textColor.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() => verses[index]['note'] = controller.text);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false, VoidCallback? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        action: action != null ? SnackBarAction(label: 'Tentar', onPressed: action, textColor: Colors.white) : null,
      ),
    );
  }
}