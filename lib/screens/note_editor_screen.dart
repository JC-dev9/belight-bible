import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar a cor da barra de status
import 'package:flutter_quill/flutter_quill.dart';

class NoteEditorScreen extends StatefulWidget {
  final String book;
  final int chapter;
  final int verseNumber;
  final String verseText;
  final String? initialNote;
  final String? initialTitle;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  const NoteEditorScreen({
    super.key,
    required this.book,
    required this.chapter,
    required this.verseNumber,
    required this.verseText,
    this.initialNote,
    this.initialTitle,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  
  // Variáveis para controlar o estado da UI sem recriar tudo
  bool _isDirty = false; 

  @override
  void initState() {
    super.initState();
    _loadContent();
    
    // Ouve alterações para saber se há algo para salvar
    _controller.document.changes.listen((event) {
      if (!_isDirty) setState(() => _isDirty = true);
    });
  }

  void _loadContent() {
    if (widget.initialNote != null && widget.initialNote!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.initialNote!);
        
        if (json is Map && json.containsKey('delta')) {
          _controller = QuillController(
            document: Document.fromJson(json['delta']),
            selection: const TextSelection.collapsed(offset: 0),
          );
          if (json['title'] != null && widget.initialTitle == null) {
             _titleController.text = json['title'];
          }
        } else {
           _controller = QuillController(
            document: Document.fromJson(json),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (e) {
        final doc = Document()..insert(0, widget.initialNote!);
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _controller = QuillController.basic();
    }
    
    // Set Title
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  void _saveAndExit() {
    final delta = _controller.document.toDelta().toJson();
    final title = _titleController.text.trim();
    
    // Otimização: Se estiver vazio, não guarda lixo
    if (title.isEmpty && _controller.document.isEmpty()) {
       Navigator.pop(context);
       return;
    }

    final noteData = {
      'delta': delta,
      'title': title.isNotEmpty ? title : null,
      'hasTitle': title.isNotEmpty,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    final jsonString = jsonEncode(noteData);
    Navigator.pop(context, jsonString);
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar cores com opacidade para fundos sutis
    final surfaceColor = widget.accentColor.withOpacity(0.08);
    final mutedText = widget.textColor.withOpacity(0.6);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      // AppBar Minimalista
      appBar: AppBar(
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0, // Remove sombra ao rolar (Material 3)
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _saveAndExit,
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: surfaceColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: const Text("Concluir", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      
      // Barra de Ferramentas fixa no fundo (BottomNavigationBar approach)
      // Isso é muito mais rápido e ergonômico
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border(top: BorderSide(color: widget.textColor.withOpacity(0.05))),
        ),
        child: SafeArea(
          child: QuillSimpleToolbar(
             controller: _controller,
             config: QuillSimpleToolbarConfig(
               // Configuração Minimalista e Performática
               showFontFamily: false,
               showFontSize: false,
               showSearchButton: false, 
               showIndent: false,
               showSubscript: false,
               showSuperscript: false,
               showCodeBlock: false,
               showInlineCode: false,
               showListCheck: true, // Útil para tarefas
               showQuote: true,
               showLink: false, // Links costumam complicar UX móvel simples
               
               // Botões essenciais apenas
               showBoldButton: true,
               showItalicButton: true,
               showUnderLineButton: true,
               showStrikeThrough: true,
               showColorButton: true,
               showBackgroundColorButton: true,
               showListNumbers: true,
               showListBullets: true,
               
               toolbarIconAlignment: WrapAlignment.center, // Centraliza ícones
               color: widget.backgroundColor,
               buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: QuillIconTheme(
                      iconButtonSelectedData: IconButtonData(
                        color: widget.accentColor,
                        style: IconButton.styleFrom(backgroundColor: surfaceColor),
                      ), 
                      iconButtonUnselectedData: IconButtonData(color: mutedText)
                    )
                  )
               )
             ),
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // 1. O Cartão do Versículo (Hero Section)
                Container(
                  margin: const EdgeInsets.only(bottom: 24, top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bookmark_rounded, size: 16, color: widget.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.book} ${widget.chapter}:${widget.verseNumber}'.toUpperCase(), 
                            style: TextStyle(
                              color: widget.accentColor, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              letterSpacing: 1.0
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.verseText, 
                        style: TextStyle(
                          height: 1.4,
                          fontStyle: FontStyle.italic, 
                          color: widget.textColor.withOpacity(0.85), 
                          fontSize: 15
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Campo de Título
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w800, 
                    color: widget.textColor,
                    letterSpacing: -0.5
                  ),
                  decoration: InputDecoration(
                    hintText: "Título da anotação",
                    hintStyle: TextStyle(
                      color: widget.textColor.withOpacity(0.3), 
                      fontWeight: FontWeight.w800
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 16),

                // 3. Editor de Texto (Quill)
                // Usando Builder para garantir constraints corretas
                QuillEditor.basic(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  config: QuillEditorConfig(
                    placeholder: 'Comece a escrever suas reflexões...',
                    autoFocus: false, // Melhor UX: não pular teclado na cara logo de início
                    padding: const EdgeInsets.only(bottom: 50), // Espaço para scroll final
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          color: widget.textColor, 
                          fontSize: 17, // Fonte levemente maior para leitura fácil
                          height: 1.6,  // Espaçamento de linha confortável
                          fontWeight: FontWeight.w400
                        ), 
                        const HorizontalSpacing(0, 0), 
                        const VerticalSpacing(0, 0), 
                        const VerticalSpacing(0, 0), 
                        null
                      ),
                      h1: DefaultTextBlockStyle(
                         TextStyle(fontSize: 32, color: widget.textColor, height: 1.15, fontWeight: FontWeight.bold),
                         const HorizontalSpacing(0, 0), const VerticalSpacing(16, 0), const VerticalSpacing(0, 0), null
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}