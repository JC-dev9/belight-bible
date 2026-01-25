import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connections_provider.dart';
import '../../data/models/node_type.dart';

class FilterDrawer extends ConsumerWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        notifier.clearFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Filtros por tipo de nó
                    const Text(
                      'Tipos de Nós',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NodeType.values.map((type) {
                        final isHidden = state.hiddenNodeTypes.contains(type);
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                size: 18,
                                color: isHidden ? Colors.grey : type.color,
                              ),
                              const SizedBox(width: 4),
                              Text(type.displayName),
                            ],
                          ),
                          selected: !isHidden,
                          onSelected: (_) {
                            notifier.toggleNodeTypeFilter(type);
                          },
                          selectedColor: type.color.withOpacity(0.2),
                          checkmarkColor: type.color,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Filtros por período
                    const Text(
                      'Períodos Bíblicos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state.availablePeriods.isEmpty)
                      const Text(
                        'Nenhum período disponível',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.availablePeriods.map((period) {
                          final isHidden = state.hiddenPeriods.contains(period);
                          return FilterChip(
                            label: Text(period),
                            selected: !isHidden,
                            onSelected: (_) {
                              notifier.togglePeriodFilter(period);
                            },
                            selectedColor: Colors.blue.withOpacity(0.2),
                            checkmarkColor: Colors.blue,
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Resumo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${state.filteredNodes.length} de ${state.allNodes.length} nós visíveis',
                          ),
                          Text(
                            '${state.allConnections.length} conexões totais',
                          ),
                        ],
                      ),
                    ),
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
