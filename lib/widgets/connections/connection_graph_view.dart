import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import '../../providers/connections_provider.dart';
import 'node_widget.dart';
import 'node_detail_sheet.dart';

class ConnectionGraphView extends ConsumerStatefulWidget {
  const ConnectionGraphView({super.key});

  @override
  ConsumerState<ConnectionGraphView> createState() =>
      _ConnectionGraphViewState();
}

class _ConnectionGraphViewState extends ConsumerState<ConnectionGraphView> {
  final Graph graph = Graph();
  late SugiyamaConfiguration builder;
  final TransformationController _transformationController =
      TransformationController();

  // Rastreia o que foi usado para construir o grafo — evita reconstrução em mudanças de seleção
  Set<String> _builtNodeIds = {};
  int _builtConnectionCount = -1;

  @override
  void initState() {
    super.initState();
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

    final nodeMap = <String, Node>{};
    for (final bibleNode in state.filteredNodes) {
      final node = Node.Id(bibleNode.id);
      nodeMap[bibleNode.id] = node;
      graph.addNode(node);
    }

    for (final connection in state.allConnections) {
      final sourceNode = nodeMap[connection.sourceId];
      final targetNode = nodeMap[connection.targetId];
      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }

    _builtNodeIds = state.filteredNodes.map((n) => n.id).toSet();
    _builtConnectionCount = state.allConnections.length;
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

    // Reconstrói o grafo somente quando nós ou conexões mudam (não em mudanças de seleção/UI)
    ref.listen(connectionsProvider, (previous, next) {
      final currentNodeIds = next.filteredNodes.map((n) => n.id).toSet();
      final nodesChanged =
          !_builtNodeIds.containsAll(currentNodeIds) ||
          !currentNodeIds.containsAll(_builtNodeIds);
      final connectionsChanged =
          next.allConnections.length != _builtConnectionCount;

      if (nodesChanged || connectionsChanged) {
        setState(() => _buildGraph());
      }
    });

    // Build inicial
    if (_builtNodeIds.isEmpty && state.filteredNodes.isNotEmpty) {
      _buildGraph();
    }

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
          final isDimmed =
              state.selectedNodeId != null && !isSelected && !isConnected;

          return RepaintBoundary(
            child: NodeWidget(
              node: bibleNode,
              isSelected: isSelected,
              isConnected: isConnected,
              isFavorite: isFavorite,
              isDimmed: isDimmed,
              onTap: () => _onNodeTap(nodeId),
            ),
          );
        },
      ),
    );
  }
}
