import 'package:flutter_test/flutter_test.dart';
import 'package:bibleapp/data/models/node_type.dart';
import 'package:bibleapp/data/models/bible_node.dart';
import 'package:bibleapp/data/models/node_connection.dart';
import 'package:bibleapp/data/models/connection_type.dart';
import 'package:bibleapp/providers/connections_provider.dart';

void main() {
  group('ConnectionsState — filteredNodes', () {
    late List<BibleNode> sampleNodes;
    late List<NodeConnection> sampleConnections;

    setUp(() {
      sampleNodes = const [
        BibleNode(
          id: 'a',
          title: 'Abraão',
          type: NodeType.character,
          references: [],
          weight: 5,
          description: '',
        ),
        BibleNode(
          id: 'b',
          title: 'Fé',
          type: NodeType.theme,
          references: [],
          weight: 5,
          description: '',
        ),
        BibleNode(
          id: 'c',
          title: 'Êxodo',
          type: NodeType.event,
          period: 'Êxodo',
          references: [],
          weight: 5,
          description: '',
        ),
      ];
      sampleConnections = const [
        NodeConnection(
          id: 'c1',
          sourceId: 'a',
          targetId: 'b',
          type: ConnectionType.typology,
          description: '',
          supportingVerses: [],
        ),
      ];
    });

    test('sem filtros devolve todos os nós', () {
      final state = ConnectionsState(
        allNodes: sampleNodes,
        allConnections: sampleConnections,
        availablePeriods: [],
      );
      expect(state.filteredNodes.length, 3);
    });

    test('tipo oculto é excluído dos filteredNodes', () {
      final state = ConnectionsState(
        allNodes: sampleNodes,
        allConnections: sampleConnections,
        availablePeriods: [],
        hiddenNodeTypes: {NodeType.character},
      );
      expect(state.filteredNodes.any((n) => n.type == NodeType.character), false);
      expect(state.filteredNodes.length, 2);
    });

    test('período oculto exclui nós com esse período', () {
      final state = ConnectionsState(
        allNodes: sampleNodes,
        allConnections: sampleConnections,
        availablePeriods: [],
        hiddenPeriods: {'Êxodo'},
      );
      expect(state.filteredNodes.any((n) => n.id == 'c'), false);
      expect(state.filteredNodes.length, 2);
    });
  });

  group('ConnectionsState — seleção', () {
    late ConnectionsState baseState;

    setUp(() {
      baseState = ConnectionsState(
        allNodes: const [
          BibleNode(id: 'a', title: 'A', type: NodeType.character, references: [], weight: 1, description: ''),
          BibleNode(id: 'b', title: 'B', type: NodeType.theme, references: [], weight: 1, description: ''),
        ],
        allConnections: const [
          NodeConnection(
            id: 'c1',
            sourceId: 'a',
            targetId: 'b',
            type: ConnectionType.causation,
            description: '',
            supportingVerses: [],
          ),
        ],
        availablePeriods: [],
        selectedNodeId: 'a',
      );
    });

    test('highlightedConnections inclui conexões do nó seleccionado', () {
      expect(baseState.highlightedConnections.length, 1);
      expect(baseState.highlightedConnections.first.id, 'c1');
    });

    test('connectedNodeIds devolve IDs dos nós vizinhos', () {
      expect(baseState.connectedNodeIds, {'b'});
    });

    test('selectedNode devolve o nó correcto', () {
      expect(baseState.selectedNode?.id, 'a');
    });

    test('clearSelection remove a seleção', () {
      final cleared = baseState.copyWith(clearSelection: true);
      expect(cleared.selectedNodeId, isNull);
      expect(cleared.selectedNode, isNull);
      expect(cleared.highlightedConnections, isEmpty);
    });
  });
}
