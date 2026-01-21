import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

enum EditorToolbarMode { none, formatting, coloring }

class NoteEditorToolbar extends StatefulWidget {
  final QuillController controller;
  final EditorToolbarMode toolbarMode;
  final Function(EditorToolbarMode) onModeChanged;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color? activeColor;
  final List<Color?> backgroundColors;
  final Function(Color?) onColorSelected;

  const NoteEditorToolbar({
    super.key,
    required this.controller,
    required this.toolbarMode,
    required this.onModeChanged,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.activeColor,
    required this.backgroundColors,
    required this.onColorSelected,
  });

  @override
  State<NoteEditorToolbar> createState() => _NoteEditorToolbarState();
}

class _NoteEditorToolbarState extends State<NoteEditorToolbar> {
  // Use a local state for rebuilds of icons that rely on selection
  // QuillController notifies listeners, but we might need to listen to it
  // to update the "active" state of buttons.

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to update button states (bold, H1, etc.)
    widget.controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Surface color for elements is derived from accent color
    final surfaceColor = widget.accentColor.withOpacity(0.08); 
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          border: Border.all(color: widget.textColor.withOpacity(0.05)),
        ),
        child: ClipRRect(
           borderRadius: BorderRadius.circular(30),
           child: _buildToolbarContent(surfaceColor, widget.textColor),
        ),
      ),
    );
  }

  Widget _buildToolbarContent(Color surfaceColor, Color toolbarItemsColor) {
    Widget divider() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 1, 
      height: 20, 
      color: toolbarItemsColor.withOpacity(0.2)
    );

    switch (widget.toolbarMode) {
      case EditorToolbarMode.formatting:
        return Row(
          children: [
            IconButton(
               icon: const Icon(Icons.close),
               onPressed: () => widget.onModeChanged(EditorToolbarMode.none),
               color: toolbarItemsColor,
            ),
            Container(width: 1, height: 24, color: toolbarItemsColor.withOpacity(0.1)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTextStyleButton("H1", Attribute.h1, toolbarItemsColor, isHeading: true),
                    _buildTextStyleButton("H2", Attribute.h2, toolbarItemsColor, isHeading: true),
                    _buildTextStyleButton("Aa", Attribute.header, toolbarItemsColor),
                    divider(),
                    _buildFormatButton(Icons.format_bold, Attribute.bold, toolbarItemsColor),
                    _buildFormatButton(Icons.format_italic, Attribute.italic, toolbarItemsColor),
                    _buildFormatButton(Icons.format_underline, Attribute.underline, toolbarItemsColor),
                    divider(),
                    IconButton(
                      icon: const Icon(Icons.format_clear),
                      tooltip: "Limpar Formatação",
                      onPressed: () {
                        final attrs = [
                          Attribute.bold, Attribute.italic, Attribute.underline, 
                          Attribute.strikeThrough, Attribute.h1, Attribute.h2, Attribute.h3
                        ];
                        for (var attr in attrs) {
                          widget.controller.formatSelection(Attribute.clone(attr, null));
                        }
                      },
                      color: toolbarItemsColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case EditorToolbarMode.coloring:
         return Row(
          children: [
            IconButton(
               icon: const Icon(Icons.close),
               onPressed: () => widget.onModeChanged(EditorToolbarMode.none),
               color: toolbarItemsColor,
            ),
            Container(width: 1, height: 24, color: toolbarItemsColor.withOpacity(0.1)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: widget.backgroundColors.map((color) {
                    final bool isDefault = color == null;
                    final Color effectiveColor = color ?? widget.backgroundColor;
                    final bool isSelected = widget.activeColor == color;
                    return GestureDetector(
                      onTap: () => widget.onColorSelected(color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: effectiveColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? widget.accentColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1
                          ),
                        ),
                        child: isDefault 
                          ? Icon(Icons.format_color_reset, size: 16, color: widget.textColor.withOpacity(0.5))
                          : (isSelected 
                              ? Icon(Icons.check, size: 16, color: Colors.black54)
                              : null),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      case EditorToolbarMode.none:
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                    IconButton(
                      icon: const Icon(Icons.palette_outlined),
                      tooltip: "Cor de fundo",
                      color: toolbarItemsColor,
                      onPressed: () => widget.onModeChanged(EditorToolbarMode.coloring),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_format),
                      tooltip: "Formatação",
                      color: toolbarItemsColor,
                      onPressed: () => widget.onModeChanged(EditorToolbarMode.formatting),
                    ),
                 ],
               ),
               Row(
                 children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      color: toolbarItemsColor,
                      onPressed: () {
                         widget.controller.undo();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      color: toolbarItemsColor,
                      onPressed: () {
                         widget.controller.redo();
                      },
                    ),
                 ],
               )
            ],
          ),
        );
    }
  }

  Widget _buildFormatButton(IconData icon, Attribute attribute, Color color) {
    if (!mounted) return SizedBox();
    final currentStyle = widget.controller.getSelectionStyle();
    final isActive = currentStyle.attributes.containsKey(attribute.key);
    return IconButton(
      icon: Icon(icon),
      color: isActive ? widget.accentColor : color,
      onPressed: () {
         if (isActive) {
            widget.controller.formatSelection(Attribute.clone(attribute, null));
         } else {
            widget.controller.formatSelection(attribute);
         }
      },
    );
  }

  Widget _buildTextStyleButton(String label, Attribute attribute, Color color, {bool isHeading = false}) {
     if (!mounted) return SizedBox();
    final currentStyle = widget.controller.getSelectionStyle();
    bool isActive;
    if (attribute.key == Attribute.header.key) {
        if (attribute.value == null) {
          isActive = !currentStyle.attributes.containsKey(Attribute.header.key);
        } else {
           isActive = currentStyle.attributes[Attribute.header.key]?.value == attribute.value;
        }
    } else {
        isActive = currentStyle.attributes.containsKey(attribute.key);
    }
    return InkWell(
      onTap: () {
         if (attribute.key == Attribute.header.key && attribute.value == null) {
            widget.controller.formatSelection(Attribute.header); 
         } else {
            if (isActive) {
               widget.controller.formatSelection(Attribute.header);
            } else {
               widget.controller.formatSelection(attribute);
            }
         }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? widget.accentColor : color,
            fontWeight: FontWeight.bold,
            fontSize: isHeading ? 16 : 14,
          ),
        ),
      ),
    );
  }
}
