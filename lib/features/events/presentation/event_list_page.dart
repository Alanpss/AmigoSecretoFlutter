import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/br_format.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/event_summary.dart';
import '../domain/event.dart';

/// Lista de eventos com busca, filtro por situação e ações de edição.
class EventListPage extends ConsumerStatefulWidget {
  const EventListPage({super.key});

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  EventStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty || _statusFilter != null;

  List<EventSummary> _filter(List<EventSummary> summaries) {
    final query = _searchController.text.trim().toLowerCase();
    return summaries
        .where((summary) {
          if (_statusFilter != null && summary.event.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return summary.event.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _deleteEvent(EventSummary summary) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir evento?',
      message:
          'O evento "${summary.event.name}", seus participantes e seus grupos '
          'serão removidos. As pessoas continuam cadastradas para outros '
          'eventos. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref.read(eventRepositoryProvider).delete(summary.event.id);
      refreshEvents(ref);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Evento excluído.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir o evento. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) =>
          AsyncErrorView(onRetry: () => ref.invalidate(eventsProvider)),
      data: (summaries) {
        final filtered = _filter(summaries);
        return LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        total: summaries.length,
                        onCreate: () => context.push('/events/new'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar evento',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _statusFilter == null,
                            onSelected: (_) =>
                                setState(() => _statusFilter = null),
                          ),
                          ChoiceChip(
                            label: Text(EventStatus.draft.label),
                            selected: _statusFilter == EventStatus.draft,
                            onSelected: (_) => setState(
                              () => _statusFilter = EventStatus.draft,
                            ),
                          ),
                          ChoiceChip(
                            label: Text(EventStatus.drawn.label),
                            selected: _statusFilter == EventStatus.drawn,
                            onSelected: (_) => setState(
                              () => _statusFilter = EventStatus.drawn,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(eventsProvider);
                            await ref.read(eventsProvider.future);
                          },
                          child: filtered.isEmpty
                              ? _EmptyEvents(
                                  hasAnyEvent: summaries.isNotEmpty,
                                  hasFilters: _hasFilters,
                                  onCreate: () => context.push('/events/new'),
                                  onClearFilters: () {
                                    _searchController.clear();
                                    setState(() => _statusFilter = null);
                                  },
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 24,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final summary = filtered[index];
                                    return _EventCard(
                                      summary: summary,
                                      onOpen: () => context.go(
                                        '/events/${summary.event.id}',
                                      ),
                                      onEdit: () => context.push(
                                        '/events/${summary.event.id}/edit',
                                      ),
                                      onDelete: () => _deleteEvent(summary),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onCreate});

  final int total;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seus eventos', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              total == 0
                  ? 'Comece criando o primeiro amigo secreto.'
                  : '$total evento${total == 1 ? '' : 's'} salvo${total == 1 ? '' : 's'} neste navegador.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Criar evento'),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.summary,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final EventSummary summary;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = summary.event;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(event.status.label),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        Text(
                          formatDateBr(event.eventDate),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${summary.activeParticipants} ativo'
                          '${summary.activeParticipants == 1 ? '' : 's'}'
                          ' de ${summary.totalParticipants}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações do evento',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Excluir'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents({
    required this.hasAnyEvent,
    required this.hasFilters,
    required this.onCreate,
    required this.onClearFilters,
  });

  final bool hasAnyEvent;
  final bool hasFilters;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (hasFilters && hasAnyEvent) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nenhum evento encontrado',
        message:
            'Ajuste a busca ou limpe os filtros para ver todos os eventos.',
        action: OutlinedButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      );
    }

    return EmptyState(
      icon: Icons.card_giftcard_outlined,
      title: 'Nenhum evento por aqui',
      message:
          'Crie seu primeiro amigo secreto, adicione participantes e organize '
          'os grupos e restrições.',
      action: FilledButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add),
        label: const Text('Criar primeiro evento'),
      ),
    );
  }
}
