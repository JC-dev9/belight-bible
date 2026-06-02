import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connections_provider.dart';
import '../widgets/connections/connection_graph_view.dart';
import '../widgets/connections/filter_drawer.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conexões',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Botão de filtros
          IconButton(
            icon: Badge(
              label: Text('${state.hiddenNodeTypes.length + state.hiddenPeriods.length}'),
              isLabelVisible: state.hiddenNodeTypes.isNotEmpty || state.hiddenPeriods.isNotEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterDrawer(),
              );
            },
          ),
          // Botão de reset
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              notifier.clearFilters();
              notifier.clearSelection();
            },
            tooltip: 'Resetar visualização',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Grafo principal
          if (state.isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando conexões bíblicas...'),
                ],
              ),
            )
          else if (state.errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notifier.loadData(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else
            const ConnectionGraphView(),

          // Info overlay (quando não há seleção)
          if (!state.isLoading && state.selectedNodeId == null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toque em um nó para ver suas conexões',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Estatísticas overlay (canto inferior esquerdo)
          if (!state.isLoading)
            Positioned(
              bottom: 16,
              left: 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${state.filteredNodes.length} nós • ${state.allConnections.length} conexões',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
