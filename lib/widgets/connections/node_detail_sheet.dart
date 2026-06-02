import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connections_provider.dart';
import '../../data/models/connection_type.dart';
import '../../data/models/node_type.dart';

class NodeDetailSheet extends ConsumerWidget {
  final String nodeId;

  const NodeDetailSheet({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);
    final theme = Theme.of(context);

    final node = state.allNodes.firstWhere((n) => n.id == nodeId);
    final isFavorite = state.favoriteNodeIds.contains(nodeId);
    
    // Conexões relacionadas a este nó
    final relatedConnections = state.allConnections.where((conn) {
      return conn.sourceId == nodeId || conn.targetId == nodeId;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header com título e tipo
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Ícone do tipo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: node.type.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            node.type.icon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Título e tipo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: node.type.color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      node.type.displayName,
                                      style: TextStyle(
                                        color: node.type.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (node.period != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${node.period}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Botão de favoritar
                        IconButton(
                          onPressed: () {
                            notifier.toggleFavorite(nodeId);
                          },
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Conteúdo scrollável
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Descrição
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      node.description,
                      style: const TextStyle(height: 1.5),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Referências bíblicas
                    const Text(
                      'Referências Bíblicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: node.references.map((ref) {
                        return Chip(
                          label: Text(ref),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide(color: Colors.blue.shade200),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Conexões
                    const Text(
                      'Conexões',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (relatedConnections.isEmpty)
                      const Text(
                        'Nenhuma conexão encontrada',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...relatedConnections.map((conn) {
                        final isSource = conn.sourceId == nodeId;
                        final otherNodeId = isSource ? conn.targetId : conn.sourceId;
                        final otherNode = state.allNodes.firstWhere(
                          (n) => n.id == otherNodeId,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: otherNode.type.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                otherNode.type.icon,
                                color: otherNode.type.color,
                                size: 24,
                              ),
                            ),
                            title: Text(otherNode.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isSource ? "→" : "←"} ${conn.type.displayName}',
                                  style: TextStyle(
                                    color: conn.type.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  conn.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      }),

                    const SizedBox(height: 80), // Espaço no final
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
