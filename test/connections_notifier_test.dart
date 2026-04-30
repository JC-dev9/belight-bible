import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bibleapp/providers/connections_provider.dart';
import 'package:bibleapp/data/models/node_type.dart';

void main() {
  group('ConnectionsNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Future<void> waitForLoad() async {
      await container.read(connectionsProvider.notifier).loadData();
    }

    test('carrega dados após inicialização', () async {
      await waitForLoad();
      final state = container.read(connectionsProvider);

      expect(state.isLoading, false);
      expect(state.allNodes, isNotEmpty);
      expect(state.allConnections, isNotEmpty);
      expect(state.availablePeriods, isNotEmpty);
      expect(state.errorMessage, isNull);
    });

    test('selectNode selecciona um nó', () async {
      await waitForLoad();
      final nodes = container.read(connectionsProvider).allNodes;
      final firstId = nodes.first.id;

      container.read(connectionsProvider.notifier).selectNode(firstId);

      expect(container.read(connectionsProvider).selectedNodeId, firstId);
    });

    test('selectNode no mesmo nó limpa a seleção', () async {
      await waitForLoad();
      final firstId = container.read(connectionsProvider).allNodes.first.id;

      container.read(connectionsProvider.notifier).selectNode(firstId);
      container.read(connectionsProvider.notifier).selectNode(firstId);

      expect(container.read(connectionsProvider).selectedNodeId, isNull);
    });

    test('clearSelection remove a seleção activa', () async {
      await waitForLoad();
      final firstId = container.read(connectionsProvider).allNodes.first.id;
      container.read(connectionsProvider.notifier).selectNode(firstId);

      container.read(connectionsProvider.notifier).clearSelection();

      expect(container.read(connectionsProvider).selectedNodeId, isNull);
    });

    test('toggleNodeTypeFilter oculta e restaura tipo de nó', () async {
      await waitForLoad();

      container
          .read(connectionsProvider.notifier)
          .toggleNodeTypeFilter(NodeType.character);
      expect(
        container.read(connectionsProvider).hiddenNodeTypes,
        contains(NodeType.character),
      );

      container
          .read(connectionsProvider.notifier)
          .toggleNodeTypeFilter(NodeType.character);
      expect(
        container.read(connectionsProvider).hiddenNodeTypes,
        isNot(contains(NodeType.character)),
      );
    });

    test('togglePeriodFilter oculta e restaura período', () async {
      await waitForLoad();
      final period =
          container.read(connectionsProvider).availablePeriods.first;

      container.read(connectionsProvider.notifier).togglePeriodFilter(period);
      expect(container.read(connectionsProvider).hiddenPeriods, contains(period));

      container.read(connectionsProvider.notifier).togglePeriodFilter(period);
      expect(
          container.read(connectionsProvider).hiddenPeriods,
          isNot(contains(period)));
    });

    test('clearFilters remove todos os filtros activos', () async {
      await waitForLoad();
      container
          .read(connectionsProvider.notifier)
          .toggleNodeTypeFilter(NodeType.theme);
      container
          .read(connectionsProvider.notifier)
          .toggleNodeTypeFilter(NodeType.event);

      container.read(connectionsProvider.notifier).clearFilters();

      final state = container.read(connectionsProvider);
      expect(state.hiddenNodeTypes, isEmpty);
      expect(state.hiddenPeriods, isEmpty);
    });

    test('toggleFavorite adiciona e remove favorito', () async {
      await waitForLoad();
      final id = container.read(connectionsProvider).allNodes.first.id;

      container.read(connectionsProvider.notifier).toggleFavorite(id);
      expect(container.read(connectionsProvider).favoriteNodeIds, contains(id));

      container.read(connectionsProvider.notifier).toggleFavorite(id);
      expect(
          container.read(connectionsProvider).favoriteNodeIds,
          isNot(contains(id)));
    });
  });
}
