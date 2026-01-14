import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/theme.dart';
import '../data/bible_repository.dart';
import 'chatbot_screen.dart';
import 'note_editor_screen.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// ============================================================================
// 1. DEFINIÇÕES
// ============================================================================

enum HighlightStyle { fundoVersiculo, fundoTexto }

// ============================================================================
// 2. TELA DA BÍBLIA
// ============================================================================

class BibleReaderScreen extends StatefulWidget {
  final ReadingTheme currentTheme;
  final Function(ReadingTheme) onThemeChanged;
  final Function(String)? onAskAI; // Callback para navegar para o chat

  const BibleReaderScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.onAskAI,
  });

  @override
  State<BibleReaderScreen> createState() => BibleReaderScreenState();
}

class BibleReaderScreenState extends State<BibleReaderScreen> {
  // Estado de Dados
  late BibleRepository _repo;
  String selectedBook = 'Gênesis';
  int selectedChapter = 1;
  List<Map<String, dynamic>> verses = [];
  bool _isLoading = true;

  // --- CONTROLE DE ESTILO DE GRIFO ---
  HighlightStyle _selectedHighlightStyle = HighlightStyle.fundoVersiculo;

  final List<Color> _availableColors = [
    AppTheme.accentGold,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.pink.shade300,
  ];

  double _fontSize = 18.0;
  // Substituindo ScrollController por ItemScrollController
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // Highlight temporário para navegação profunda
  int? _focusedVerseIndex;
  
  // Seleção múltipla
  final Set<int> _selectedVerses = {};

  void _clearFocus() {
    if (_focusedVerseIndex != null) {
      setState(() {
        _focusedVerseIndex = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializa com a versão padrão
    _repo = BibleRepository(version: 'acf'); 
    _loadInitialData();
  }

  // Método público para navegar para um versículo específico
  Future<void> jumpToVerse(String book, int chapter, int verse) async {
    // 1. Atualiza livro e capítulo se necessário
    if (selectedBook != book || selectedChapter != chapter) {
      setState(() {
        selectedBook = book;
        selectedChapter = chapter;
      });
      await _loadChapter();
    }

    // 2. Aguarda um pouco para a lista ser construída com os novos versículos
    // (O _loadChapter já faz setState, mas garantir renderização é bom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (verses.isNotEmpty && verse > 0 && verse <= verses.length) {
        
        setState(() {
          _focusedVerseIndex = verse - 1;
        });

        _itemScrollController.scrollTo(
          index: verse - 1,
          duration: const Duration(milliseconds: 500), // Mais rápido
          curve: Curves.easeInOutCubic,
          alignment: 0.3, // Tenta posicionar um pouco abaixo do topo para dar contexto
        );
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Garante que o repositório carregue o JSON (seja local ou baixado)
      await _repo.ensureLoaded();
      await _loadChapter();
    } catch (e) {
      // Se der erro (ex: arquivo não existe), paramos o loading
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao carregar dados. Verifique a versão.', isError: true);
    }
  }

  @override
  void dispose() {
    // _scrollController.dispose(); // Não precisa dispose no ItemScrollController
    super.dispose();
  }

  // --- Lógica de Dados ---
  Future<void> _loadChapter() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final newVerses = await _repo.getChapter(selectedBook, selectedChapter);
      setState(() {
        verses = newVerses;
        _isLoading = false;
      });
      
      // Reset scroll (com ItemScrollController, geralmente começa do 0, 
      // mas podemos forçar se mudou de capítulo manualmente)
      if (verses.isNotEmpty) {
         try {
           _itemScrollController.jumpTo(index: 0);
         } catch (e) {
           // Pode falhar se não estiver anexado ainda, o que é OK no load inicial
         }
      }

    } catch (e) {
      debugPrint("Erro no _loadChapter: $e");
      setState(() {
        _isLoading = false;
        verses = [];
      });
      _showSnackBar('Erro ao carregar capítulo.', isError: true, action: _loadChapter);
    }
  }

  void _navigateChapter(int delta) {
    final maxChapters = _repo.chaptersPerBook[selectedBook] ?? 1;
    final newChapter = selectedChapter + delta;

    if (newChapter >= 1 && newChapter <= maxChapters) {
      setState(() => selectedChapter = newChapter);
      _loadChapter();
    } else if (newChapter > maxChapters) {
      _showSnackBar('Último capítulo de $selectedBook.');
    }
  }

  // --- Nova Lógica: Seletor de Versão ---
  void _showVersionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versão da Bíblia', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...BibleRepository.availableVersions.entries.map((entry) {
                final isSelected = _repo.version == entry.key;
                return ListTile(
                  title: Text(entry.value, style: TextStyle(color: _textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check, color: _uiActiveColor) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (isSelected) return;
                    
                    // Atualiza a versão no repositório
                    _repo.version = entry.key;
                    
                    // Recarrega os dados (o LocalBibleLoader vai decidir se lê do asset ou do disco)
                    await _loadInitialData();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- Helpers de Estilo ---

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

  Color get _uiActiveColor => AppTheme.accentGold; 

  // --- Widgets da UI ---

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      tween: ColorTween(
        begin: Colors.white, 
        end: _backgroundColor, 
      ),
      builder: (context, animatedBgColor, child) {
        return TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          tween: ColorTween(
            begin: Colors.black, 
            end: _textColor
          ),
          builder: (context, animatedTextColor, _) {
            return Scaffold(
              backgroundColor: animatedBgColor, 
              body: SafeArea(
                child: Column(
                  children: [
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
                    // Condicional: Se tiver seleção, mostra painel de ação.
                    // Se não, mostra controles de navegação.
                    _selectedVerses.isNotEmpty 
                       ? _buildSelectionPanel(animatedBgColor, animatedTextColor)
                       : _buildBottomControls(
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
          // Botão de Versão (NOVO)
          TextButton(
            onPressed: _showVersionSelector,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: textColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              _repo.version.toUpperCase(), 
              style: TextStyle(color: _uiActiveColor, fontWeight: FontWeight.bold)
            ),
          ),
          
          // Seletor de Livro
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

          // Configurações
          IconButton(
            icon: Icon(Icons.text_format, color: textColor),
            onPressed: _showDisplaySettings,
            tooltip: 'Ajustar texto',
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList(Color animatedTextColor) {
    return Listener(
      onPointerDown: (_) {
         _clearFocus();
         // Nota: Não limpamos a seleção aqui, pois o usuário pode estar clicando 
         // para adicionar mais versículos. A limpeza da seleção acontece ao fechar o modal
         // ou através de lógica específica se implementarmos um "cancelar".
      },
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        itemCount: verses.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final verse = verses[index];
          final highlightValue = verse['highlighted'];
          final Color? highlightColor = highlightValue is Color 
              ? highlightValue 
              : (highlightValue == true ? AppTheme.accentGold : null);

          final hasNote = verse['note'] != null && verse['note'].toString().isNotEmpty;
          final bool isBlock = _selectedHighlightStyle == HighlightStyle.fundoVersiculo;
          final bool isText = _selectedHighlightStyle == HighlightStyle.fundoTexto;
          
          // Lógica de Foco (Dimming)
          final bool isFocused = _focusedVerseIndex == index;
          final bool isDimmed = _focusedVerseIndex != null && !isFocused;
          
          // Lógica de Seleção
          final bool isSelected = _selectedVerses.contains(index);
          
          final double opacity = isDimmed ? 0.3 : 1.0;
          final Color textColorWithFocus = animatedTextColor.withOpacity(isDimmed ? 0.3 : 1.0);

          return GestureDetector(
            onLongPress: () {
              setState(() {
                _selectedVerses.add(index);
              });
            },
            onTap: () {
               if (_selectedVerses.isNotEmpty) {
                 // Modo de seleção ativo: toggle
                 setState(() {
                   if (_selectedVerses.contains(index)) {
                     _selectedVerses.remove(index);
                   } else {
                     _selectedVerses.add(index);
                   }
                 });
               } else {
                 // Modo normal: seleciona e abre "modal" (que agora é o painel de seleção)
                 setState(() {
                   _selectedVerses.add(index);
                 });
               }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
              decoration: BoxDecoration(
                // Removido background de seleção (agora é underline)
                color: (highlightColor != null && isBlock)
                        ? highlightColor.withOpacity(widget.currentTheme == ReadingTheme.dark ? 0.3 : 0.4).withOpacity(isDimmed ? 0.1 : (widget.currentTheme == ReadingTheme.dark ? 0.3 : 0.4))
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: hasNote ? BorderSide(color: _uiActiveColor.withOpacity(opacity), width: 3) : BorderSide.none,
                  // Prioridade: Seleção > Foco > Nada
                  bottom: isSelected 
                      ? BorderSide(color: _uiActiveColor, width: 3) // Underline de seleção
                      : (isFocused ? BorderSide(color: _uiActiveColor, width: 2) : BorderSide.none),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.6,
                        color: textColorWithFocus, 
                        fontFamily: 'Georgia',
                        backgroundColor: (highlightColor != null && isText)
                            ? highlightColor.withOpacity(0.5).withOpacity(isDimmed ? 0.1 : 0.5)
                            : null,
                      ),
                      children: [
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0, -4),
                            child: Text(
                              '${verse['number']} ',
                              style: TextStyle(
                                fontSize: _fontSize * 0.6, 
                                fontWeight: FontWeight.bold, 
                                color: _verseNumColor.withOpacity(opacity)
                              ),
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
                        GestureDetector(
                          onTap: () => _showNoteBottomSheet(index), 
                          child: Icon(Icons.note, size: 14, color: _uiActiveColor),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showNoteBottomSheet(index),
                            child: Text(
                              verse['note'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: animatedTextColor.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
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
      ),
    );
  }

  // Substitui o modal flutuante por um painel persistente quando há seleção
  Widget _buildSelectionPanel(Color bgColor, Color textColor) {
    if (_selectedVerses.isEmpty) return const SizedBox.shrink();

    final sortedIndices = _selectedVerses.toList()..sort();
    final count = sortedIndices.length;
    final firstVerse = verses[sortedIndices.first];
    
    String title = count == 1 
        ? '$selectedBook $selectedChapter:${firstVerse['number']}' 
        : '$count versículos'; // Encurtado para "versículos"

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Floating Margin
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24), // Borda totalmente arredondada
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), 
                blurRadius: 20, 
                offset: const Offset(0, 10)
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Compacto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      // Botão Fechar (Esquerda)
                      GestureDetector(
                        onTap: () => setState(() => _selectedVerses.clear()),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: textColor.withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 20, color: textColor),
                        ),
                      ),
                      
                      // Título (Centro)
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      
                      // Placeholder/Spacer (Direita) para balancear
                      const SizedBox(width: 40), 
                   ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Toggles (Estilo Chips)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStyleToggleBtn(setState, HighlightStyle.fundoVersiculo, "Bloco", Icons.crop_square),
                  const SizedBox(width: 12),
                  _buildStyleToggleBtn(setState, HighlightStyle.fundoTexto, "Texto", Icons.title),
                ],
              ),
              const SizedBox(height: 16),

              // Cores
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Reset
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          for (var i in _selectedVerses) verses[i]['highlighted'] = null;
                          _selectedVerses.clear();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: textColor.withOpacity(0.2))),
                        child: Icon(Icons.format_color_reset, size: 20, color: textColor),
                      ),
                    ),
                    // Cores
                    ..._availableColors.map((color) => GestureDetector(
                      onTap: () {
                         setState(() {
                           for (var i in _selectedVerses) verses[i]['highlighted'] = color;
                           _selectedVerses.clear();
                         });
                      },
                      child: Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1)
                        ),
                      ),
                    )).toList(),
                    // Advanced Picker
                    GestureDetector(
                      onTap: () => _showAdvancedColorPicker(_selectedVerses.first, setState),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: textColor.withOpacity(0.2)),
                          gradient: const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red])
                        ),
                        child: const Icon(Icons.colorize, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Ações (Divider sutil antes?)
              Divider(height: 1, color: textColor.withOpacity(0.05)),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionIcon(Icons.copy, 'Copiar', () {
                    final text = _getSelectedText();
                    Clipboard.setData(ClipboardData(text: text));
                    if (mounted) {
                      setState(() => _selectedVerses.clear()); 
                      _showSnackBar('Copiado');
                    }
                  }, textColor),
                  _buildOptionIcon(Icons.share, 'Partilhar', () async { // Async
                    final text = _getSelectedText();
                    // Inicia o compartilhamento
                    await Share.share(text);
                    
                    // Pequeno delay para garantir que o Share Sheet abriu e a transição ocorreu
                    // antes de alterar a árvore de widgets (remover o painel).
                    // Isso evita crashes nativos em alguns dispositivos.
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    if (mounted) setState(() => _selectedVerses.clear());
                  }, textColor),
                  _buildOptionIcon(Icons.edit_note, 'Anotar', () {
                     if (_selectedVerses.length == 1) {
                       final index = _selectedVerses.first;
                       if (mounted) {
                         setState(() => _selectedVerses.clear());
                         _showNoteBottomSheet(index);
                       }
                     } else {
                       _showSnackBar('Selecione apenas 1 para anotar');
                     }
                  }, textColor),
                  _buildOptionIcon(Icons.psychology, 'AI', () { // Encurtado
                    final text = _getSelectedText();
                    final prompt = "Explique: \"$text\"";
                    if (mounted) {
                      setState(() => _selectedVerses.clear());
                      if (widget.onAskAI != null) widget.onAskAI!(prompt);
                    }
                  }, textColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls({required Color bgColor, required Color textColor}) {
    final isFirst = selectedChapter == 1;
    final maxChapters = _repo.chaptersPerBook[selectedBook] ?? 1;
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
        color: widget.currentTheme == ReadingTheme.sepia ? AppColors.sepiaAccent : _uiActiveColor,
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
          Text('Não foi possível carregar os dados.', style: TextStyle(color: textColor)),
          TextButton(
            onPressed: _loadInitialData, 
            style: TextButton.styleFrom(foregroundColor: _uiActiveColor),
            child: const Text('Tentar Novamente')
          )
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
                          activeColor: widget.currentTheme == ReadingTheme.sepia ? AppColors.sepiaAccent : _uiActiveColor,
                          inactiveColor: getModalText().withOpacity(0.2),
                          label: _fontSize.round().toString(),
                          onChanged: (val) {
                            setState(() => _fontSize = val);
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
        widget.onThemeChanged(theme);
        setModalState(() {});
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
                  color: isSelected ? (theme == ReadingTheme.sepia ? AppColors.sepiaAccent : _uiActiveColor) : Colors.grey.shade400,
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
                  itemCount: _repo.allBooks.length,
                  itemBuilder: (context, index) {
                    final book = _repo.allBooks[index];
                    final isSelected = book == selectedBook;
                    return ListTile(
                      title: Text(book, style: TextStyle(color: isSelected ? _uiActiveColor : _textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? Icon(Icons.check, color: _uiActiveColor) : null,
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
    final maxChapters = _repo.chaptersPerBook[selectedBook] ?? 1;
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
                        color: isSelected ? _uiActiveColor : _textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? null : Border.all(color: _textColor.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            color: isSelected ? Colors.black : _textColor,
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

  // --- Modais e Paineis de Ação ---

  // Substitui o modal flutuante por um painel persistente quando há seleção


  // Helper para mostrar picker de cor (reutilizando lógica do modal)
  void _showColorPickerForSelection() {
     showModalBottomSheet(
       context: context,
       backgroundColor: Colors.transparent,
       builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        for (var i in _selectedVerses) {
                          verses[i]['highlighted'] = null;
                        }
                        _selectedVerses.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: _buildColorCircle(null, isReset: true),
                  ),
                  ..._availableColors.map((color) => GestureDetector(
                    onTap: () {
                       setState(() {
                         for (var i in _selectedVerses) {
                           verses[i]['highlighted'] = color;
                         }
                         _selectedVerses.clear();
                       });
                       Navigator.pop(context);
                    },
                    child: _buildColorCircle(color),
                  )).toList(),
               ],
            ),
          ),
       ),
     );
  }

  Widget _buildColorCircle(Color? color, {bool isReset = false}) {
     return Container(
        width: 45, height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
           color: color ?? Colors.transparent,
           shape: BoxShape.circle,
           border: Border.all(color: _textColor.withOpacity(0.2)),
        ),
        child: isReset ? Icon(Icons.format_color_reset, color: _textColor) : null,
     );
  }

  String _getSelectedText() {
    final sortedIndices = _selectedVerses.toList()..sort();
    final buffer = StringBuffer();
    for (var i in sortedIndices) {
      final v = verses[i];
      buffer.write('${v['text']} ($selectedBook $selectedChapter:${v['number']})\n');
    }
    return buffer.toString().trim();
  }

  Widget _buildOptionIcon(IconData icon, String label, VoidCallback onTap, Color textColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          ],
        ),
      ),
    );
  }

  // Mantendo o antigo apenas como placeholder ou para lógica singular se necessário
  void _showVerseOptionsModal() {
     // Apenas chama setState para garantir que o painel apareça
     // A lógica real está no _buildSelectionPanel
     setState(() {});
  }
 
  /* 
  // Versão antiga comentada/substituída pela lógica de Seleção
  void _showVerseOptionsModal_OLD(int verseIndex) {
    final verse = verses[verseIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStyleToggleBtn(setModalState, HighlightStyle.fundoVersiculo, "Fundo Bloco", Icons.crop_square),
                  const SizedBox(width: 12),
                  _buildStyleToggleBtn(setModalState, HighlightStyle.fundoTexto, "Fundo Texto", Icons.title),
                ],
              ),
              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => verses[verseIndex]['highlighted'] = null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _textColor.withOpacity(0.2))),
                        child: Icon(Icons.format_color_reset, size: 20, color: _textColor),
                      ),
                    ),
                    ..._availableColors.map((color) => GestureDetector(
                      onTap: () {
                        setState(() => verses[verseIndex]['highlighted'] = color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: verse['highlighted'] == color ? _uiActiveColor : Colors.transparent, width: 3)
                        ),
                      ),
                    )).toList(),
                    GestureDetector(
                      onTap: () => _showAdvancedColorPicker(verseIndex, setModalState),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _textColor.withOpacity(0.2)),
                          gradient: const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red])
                        ),
                        child: const Icon(Icons.colorize, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              
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
                  _buildOptionIcon(Icons.edit_note, 'Anotar', () {
                    Navigator.pop(context);
                    _showNoteBottomSheet(verseIndex);
                  }),
                  _buildOptionIcon(Icons.psychology, 'Perguntar a IA', () {
                    Navigator.pop(context);
                    final prompt = 'Gostaria de saber mais sobre este versículo: "$selectedBook $selectedChapter:${verse['number']} - ${verse['text']}". O que ele significa?';
                    
                    if (widget.onAskAI != null) {
                      widget.onAskAI!(prompt);
                    } else {
                      // Fallback safe caso não haja callback
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatBotScreen(initialPrompt: prompt),
                        ),
                      );
                    }
                  }),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  */

  Widget _buildStyleToggleBtn(StateSetter setModalState, HighlightStyle style, String label, IconData icon) {
    final isSelected = _selectedHighlightStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHighlightStyle = style);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _uiActiveColor : _textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : _textColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : _textColor,
            )),
          ],
        ),
      ),
    );
  }

  void _showAdvancedColorPicker(int verseIndex, StateSetter setModalState) {
    Color tempColor = Colors.orange.shade200;
    final List<Color> presets = [
      ...Colors.primaries.map((c) => c.shade200),
      ...Colors.accents.map((c) => c.withOpacity(0.5)),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) => AlertDialog(
          backgroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nova Cor e Preview', style: TextStyle(color: _textColor, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_selectedHighlightStyle == HighlightStyle.fundoVersiculo)
                    ? tempColor.withOpacity(widget.currentTheme == ReadingTheme.dark ? 0.3 : 0.4)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tempColor),
                ),
                child: Text(
                  verses[verseIndex]['text'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textColor, 
                    fontSize: 14, 
                    fontStyle: FontStyle.italic,
                    backgroundColor: (_selectedHighlightStyle == HighlightStyle.fundoTexto)
                      ? tempColor.withOpacity(0.5)
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.maxFinite,
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: presets.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setPickerState(() => tempColor = presets[i]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: presets[i], 
                        shape: BoxShape.circle,
                        border: Border.all(color: tempColor == presets[i] ? _textColor : Colors.transparent, width: 2)
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: _textColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _uiActiveColor),
              onPressed: () {
                setState(() {
                  if (!_availableColors.contains(tempColor)) _availableColors.add(tempColor);
                  verses[verseIndex]['highlighted'] = tempColor;
                });
                setModalState(() {});
                Navigator.pop(context);
              },
              child: const Text('Aplicar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }




  void _showNoteBottomSheet(int index) async {
    final note = verses[index]['note'];
    final verseNumber = verses[index]['number'];
    final verseText = verses[index]['text'];
    
    // Navega para a tela de editor
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          book: selectedBook,
          chapter: selectedChapter,
          verseNumber: verseNumber,
          verseText: verseText,
          initialNote: note,
          backgroundColor: _backgroundColor, // Passando tema atual
          textColor: _textColor,
          accentColor: _uiActiveColor,
        ),
      ),
    );

    // Se retornou algo (JSON string), salva. 
    // Se retornou null, o usuário apenas voltou sem salvar.
    if (result != null && result is String) {
      setState(() {
        verses[index]['note'] = result;
      });
      _showSnackBar('Anotação salva');
    }
  }

  void _showSnackBar(String msg, {bool isError = false, VoidCallback? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        action: action != null ? SnackBarAction(label: 'Tentar', onPressed: action, textColor: _uiActiveColor) : null,
      ),
    );
  }
}