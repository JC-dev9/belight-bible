import 'package:flutter/material.dart';
import 'bible_types.dart';

class SelectionPanel extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color activeColor;
  final Set<int> selectedVerses;
  final List<Color> availableColors;
  final HighlightStyle currentHighlightStyle;
  
  // Funções de Retorno (Callbacks)
  final VoidCallback onClose;
  final VoidCallback onResetHighlight;
  final Function(Color) onColorSelected;
  final Function(HighlightStyle) onStyleToggle;
  final Function(BuildContext) onAdvancedColorTap; // Pass context to show dialog
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onNote;
  final VoidCallback onAskAI;

  const SelectionPanel({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.activeColor,
    required this.selectedVerses,
    required this.availableColors,
    required this.currentHighlightStyle,
    required this.onClose,
    required this.onResetHighlight,
    required this.onColorSelected,
    required this.onStyleToggle,
    required this.onAdvancedColorTap,
    required this.onCopy,
    required this.onShare,
    required this.onNote,
    required this.onAskAI,
  });

  @override
  State<SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends State<SelectionPanel> {
  bool _isColorsExpanded = false;
  static const int _collapsedColorCount = 3;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedVerses.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Linha 1: Fechar | Cores | Alternar Estilo
              Row(
                children: [
                  // Botão Fechar
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.textColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: widget.textColor),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Lista de Cores
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white.withValues(alpha: 0.05)
                          ],
                          stops: const [0.0, 0.85, 1.0],
                          tileMode: TileMode.mirror,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Botão Reset
                            GestureDetector(
                              onTap: () {
                                widget.onResetHighlight();
                                setState(() => _isColorsExpanded = false);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: widget.textColor.withValues(alpha: 0.2)),
                                ),
                                child: Icon(Icons.format_color_reset, size: 18, color: widget.textColor),
                              ),
                            ),

                            // Colors
                            ...widget.availableColors.asMap().entries.map((entry) {
                              final index = entry.key;
                              final color = entry.value;
                              
                              final bool showAsSmall = !_isColorsExpanded && index >= _collapsedColorCount;

                              return GestureDetector(
                                onTap: () {
                                  if (showAsSmall) {
                                    setState(() => _isColorsExpanded = true);
                                  } else {
                                    widget.onColorSelected(color);
                                    setState(() => _isColorsExpanded = false);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  width: showAsSmall ? 16 : 32,
                                  height: showAsSmall ? 16 : 32,
                                  margin: EdgeInsets.only(right: showAsSmall ? 4 : 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black12, width: 1),
                                  ),
                                ),
                              );
                            }),

                            // Seletor Avançado
                            GestureDetector(
                                onTap: () => widget.onAdvancedColorTap(context),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: widget.textColor.withValues(alpha: 0.2)),
                                      gradient: const SweepGradient(colors: [
                                        Colors.red,
                                        Colors.yellow,
                                        Colors.green,
                                        Colors.blue,
                                        Colors.purple,
                                        Colors.red
                                      ])),
                                  child: const Icon(Icons.colorize, size: 16, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Botão Alternar Estilo
                  GestureDetector(
                    // Chama o callback de alternância com o NOVO estilo
                    // Assumimos que o pai lida com a lógica, apenas pedimos para alternar.
                    // Mas podemos calcular o próximo estilo aqui.
                    onTap: () {
                       final nextStyle = widget.currentHighlightStyle == HighlightStyle.fundoVersiculo
                           ? HighlightStyle.fundoTexto
                           : HighlightStyle.fundoVersiculo;
                       widget.onStyleToggle(nextStyle);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.textColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.currentHighlightStyle == HighlightStyle.fundoVersiculo
                            ? Icons.crop_square
                            : Icons.title,
                        size: 20,
                        color: widget.activeColor,
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: widget.textColor.withValues(alpha: 0.05)),
              const SizedBox(height: 12),

              // Linha 2: Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionIcon(Icons.copy, 'Copiar', widget.onCopy, widget.textColor),
                  _buildOptionIcon(Icons.share, 'Partilhar', widget.onShare, widget.textColor),
                  _buildOptionIcon(Icons.edit_note, 'Anotar', widget.onNote, widget.textColor),
                  _buildOptionIcon(Icons.psychology, 'AI', widget.onAskAI, widget.textColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                color: textColor.withValues(alpha: 0.05),
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
}
