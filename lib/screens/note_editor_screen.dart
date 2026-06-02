import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../widgets/note_editor/note_editor_toolbar.dart';
import '../widgets/note_editor/verse_context_card.dart';
import '../services/note_export_service.dart';
import '../data/user_data_model.dart';

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
  final ScrollController _editorScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode(); // Re-introduced FocusNode
  
  // State
  bool _isDirty = false; 
  EditorToolbarMode _toolbarMode = EditorToolbarMode.none;
  Color? _customBackgroundColor; 

  // Available background colors
  final List<Color?> _backgroundColors = [
    null, // Default
    const Color(0xFFFAAFA8), // Red
    const Color(0xFFF39F76), // Orange
    const Color(0xFFFFF8B8), // Yellow
    const Color(0xFFE2F6D3), // Green
    const Color(0xFFB4DDD3), // Teal
    const Color(0xFFD4E4ED), // Blue
    const Color(0xFFAECCDC), // Dark Blue
    const Color(0xFFD3BFDB), // Purple
    const Color(0xFFF6E2DD), // Pink
    const Color(0xFFE9E3D4), // Brown
    const Color(0xFFEFEFF1), // Grey
  ];

  @override
  void initState() {
    super.initState();
    _customBackgroundColor = null; 
    _loadContent();
    _controller.document.changes.listen(_onDocumentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose(); // Dispose properly
    _controller.dispose();
    super.dispose();
  }

  void _onDocumentChanged(DocChange event) {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _loadContent() {
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    
    if (widget.initialNote?.isNotEmpty == true) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.initialNote!));
        _controller = QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
        return;
      } catch (e) {
        // Fallback to basic if parsing fails
      }
    }
    _controller = QuillController.basic();
  }

  void _saveAndExit() {
    final title = _titleController.text.trim();
    final content = jsonEncode(_controller.document.toDelta().toJson());
    Navigator.pop(context, {
      'title': title,
      'content': content,
      'color': _customBackgroundColor?.toARGB32(),
    });
  }

  Future<void> _shareNote() async {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final note = UserNote(
      book: widget.book,
      chapter: widget.chapter,
      verse: widget.verseNumber,
      content: content,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
    );
    await NoteExportService.exportNote(note);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _customBackgroundColor ?? widget.backgroundColor;
    final bool isCustomColor = _customBackgroundColor != null;
    
    // Auto-contrast text color
    final Color effectiveTextColor = isCustomColor ? Colors.black87 : widget.textColor;
    final Color effectiveHintColor = isCustomColor ? Colors.black38 : widget.textColor.withValues(alpha: 0.4);
    final surfaceColor = widget.accentColor.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: effectiveTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: effectiveTextColor, size: 20),
            tooltip: 'Partilhar nota',
            onPressed: _shareNote,
          ),
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
      
      bottomNavigationBar: NoteEditorToolbar(
        controller: _controller,
        toolbarMode: _toolbarMode,
        onModeChanged: (mode) => setState(() => _toolbarMode = mode),
        backgroundColor: widget.backgroundColor,
        textColor: widget.textColor,
        accentColor: widget.accentColor,
        activeColor: _customBackgroundColor,
        backgroundColors: _backgroundColors,
        onColorSelected: (color) => setState(() => _customBackgroundColor = color),
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: CustomScrollView(
          controller: _editorScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                   VerseContextCard(
                      book: widget.book,
                      chapter: widget.chapter,
                      verseNumber: widget.verseNumber,
                      verseText: widget.verseText,
                      accentColor: widget.accentColor,
                      backgroundColor: isCustomColor ? Colors.white.withValues(alpha: 0.5) : surfaceColor,
                      textColor: effectiveTextColor,
                   ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: effectiveTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "Título",
                      hintStyle: TextStyle(color: effectiveHintColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            SliverFillRemaining(
              hasScrollBody: false, 
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Request focus when tapping outside the precise text area
                        if (!_editorFocusNode.hasFocus) {
                           _editorFocusNode.requestFocus();
                        }
                      },
                      child: QuillEditor.basic(
                        controller: _controller,
                        focusNode: _editorFocusNode, // Re-attached FocusNode
                        // configurations removed
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}