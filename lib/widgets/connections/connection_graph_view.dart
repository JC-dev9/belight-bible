import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import '../../providers/connections_provider.dart';
import '../../data/models/bible_node.dart';
import '../../data/models/node_connection.dart';
import 'node_widget.dart';
import 'node_detail_sheet.dart';

class ConnectionGraphView extends ConsumerStatefulWidget {
  const ConnectionGraphView({super.key});

  @override
  ConsumerState<ConnectionGraphView> createState() => _ConnectionGraphViewState();
}

class _ConnectionGraphViewState extends ConsumerState<ConnectionGraphView> {
  final Graph graph = Graph();
  late SugiyamaConfiguration builder;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    
    // Configuração do algoritmo de layout
    builder = SugiyamaConfiguration()
      ..nodeSeparation = 80
      ..levelSeparation = 100
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _buildGraph() {
    final state = ref.read(connectionsProvider);
    graph.nodes.clear();
    graph.edges.clear();

    // Criar nós apenas para os filtrados
    final nodeMap = <String, Node>{};
    for (final bibleNode in state.filteredNodes) {
      final node = Node.Id(bibleNode.id);
      nodeMap[bibleNode.id] = node;
      graph.addNode(node);
    }

    // Criar arestas entre nós filtrados
    for (final connection in state.allConnections) {
      final sourceNode = nodeMap[connection.sourceId];
      final targetNode = nodeMap[connection.targetId];
      
      // Só adiciona a aresta se ambos os nós estão visíveis
      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }
  }

  void _onNodeTap(String nodeId) {
    final notifier = ref.read(connectionsProvider.notifier);
    notifier.selectNode(nodeId);
    
    // Abrir bottom sheet com detalhes
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NodeDetailSheet(nodeId: nodeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionsProvider);
    
    // Rebuild o grafo quando os nós filtrados mudarem
    _buildGraph();

    if (state.filteredNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum nó visível',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ajuste os filtros para ver as conexões',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.3,
      maxScale: 2.5,
      transformationController: _transformationController,
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(builder),
        paint: Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final nodeId = node.key!.value as String;
          final bibleNode = state.allNodes.firstWhere((n) => n.id == nodeId);
          
          // Determinar estado visual do nó
          final isSelected = state.selectedNodeId == nodeId;
          final isConnected = state.connectedNodeIds.contains(nodeId);
          final isFavorite = state.favoriteNodeIds.contains(nodeId);
          final isDimmed = state.selectedNodeId != null && 
                          !isSelected && 
                          !isConnected;

          return NodeWidget(
            node: bibleNode,
            isSelected: isSelected,
            isConnected: isConnected,
            isFavorite: isFavorite,
            isDimmed: isDimmed,
            onTap: () => _onNodeTap(nodeId),
          );
        },
      ),
    );
  }
}
