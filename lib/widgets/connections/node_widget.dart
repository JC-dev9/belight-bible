import 'package:flutter/material.dart';
import '../../data/models/bible_node.dart';
import '../../data/models/node_type.dart';

class NodeWidget extends StatefulWidget {
  final BibleNode node;
  final bool isSelected;
  final bool isConnected;
  final bool isFavorite;
  final bool isDimmed;
  final VoidCallback onTap;

  const NodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isConnected,
    required this.isFavorite,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = widget.node.type.color;
    final size = 70.0 + (widget.node.weight * 3.0); // Maior peso = nó maior

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.isDimmed ? 0.3 : 1.0,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Container principal do nó
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeColor,
                    boxShadow: [
                      BoxShadow(
                        color: widget.isSelected 
                            ? nodeColor.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.2),
                        blurRadius: widget.isSelected ? 16 : 8,
                        spreadRadius: widget.isSelected ? 2 : 0,
                      ),
                    ],
                    border: widget.isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : widget.isConnected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.node.type.icon,
                        color: Colors.white,
                        size: size * 0.35,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          widget.node.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: size * 0.14,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge de favorito
                if (widget.isFavorite)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
