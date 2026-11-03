import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/br_format.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/participant_view.dart';

enum _ParticipantFilter { all, active, inactive }

/// Lista de participantes com busca, filtro e ações.
class ParticipantListPage extends ConsumerStatefulWidget {
  const ParticipantListPage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ParticipantListPage> createState() =>
      _ParticipantListPageState();
}

class _ParticipantListPageState extends ConsumerState<ParticipantListPage> {
  final TextEditingController _searchController = TextEditingController();
  _ParticipantFilter _filter = _ParticipantFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ParticipantWithPerson> _filterViews(List<ParticipantWithPerson> views) {
    final query = _searchController.text.trim().toLowerCase();
    return views
        .where((view) {
          if (_filter == _ParticipantFilter.active &&
              !view.participant.isActive) {
            return false;
          }
          if (_filter == _ParticipantFilter.inactive &&
              view.participant.isActive) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final person = view.person;
          return person.name.toLowerCase().contains(query) ||
              (person.nickname?.toLowerCase().contains(query) ?? false) ||
              (person.phoneE164?.contains(query) ?? false);
        })
        .toList(growable: false);
  }

  Future<void> _remove(ParticipantWithPerson view) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remover participante?',
      message:
          '${view.person.name} será removido deste evento e dos grupos. '
          'A pessoa continua cadastrada e pode participar de outros eventos.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      await ref.read(participantRepositoryProvider).delete(view.participant.id);
      refreshEvent(ref, widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Participante removido. A pessoa continua cadastrada.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível remover o participante. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantsAsync = ref.watch(participantsProvider(widget.eventId));

    return participantsAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        onRetry: () => ref.invalidate(participantsProvider(widget.eventId)),
      ),
      data: (views) {
        final filtered = _filterViews(views);
        final hasFilters =
            _searchController.text.trim().isNotEmpty ||
            _filter != _ParticipantFilter.all;

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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Participantes',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '/events/${widget.eventId}/participants/new',
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nome, apelido ou telefone',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<_ParticipantFilter>(
                          segments: const [
                            ButtonSegment(
                              value: _ParticipantFilter.all,
                              label: Text('Todos'),
                            ),
                            ButtonSegment(
                              value: _ParticipantFilter.active,
                              label: Text('Ativos'),
                            ),
                            ButtonSegment(
                              value: _ParticipantFilter.inactive,
                              label: Text('Inativos'),
                            ),
                          ],
                          selected: {_filter},
                          onSelectionChanged: (selection) {
                            setState(() => _filter = selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? _EmptyParticipants(
                                hasAny: views.isNotEmpty,
                                hasFilters: hasFilters,
                                onAdd: () => context.push(
                                  '/events/${widget.eventId}/participants/new',
                                ),
                                onClear: () {
                                  _searchController.clear();
                                  setState(
                                    () => _filter = _ParticipantFilter.all,
                                  );
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
                                  final view = filtered[index];
                                  return _ParticipantCard(
                                    view: view,
                                    onEdit: () => context.push(
                                      '/events/${widget.eventId}/participants/'
                                      '${view.participant.id}/edit',
                                    ),
                                    onRemove: () => _remove(view),
                                  );
                                },
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

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.view,
    required this.onEdit,
    required this.onRemove,
  });

  final ParticipantWithPerson view;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = view.person;
    final recipient = view.recipient;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(_initial(person.name))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(person.name, style: theme.textTheme.titleMedium),
                        if (person.nickname != null)
                          Text(
                            '(${person.nickname})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Chip(
                          label: Text(
                            view.participant.isActive ? 'Ativo' : 'Inativo',
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      view.participant.guardianPersonId == null
                          ? 'Recebe no próprio número: '
                                '${formatPhoneForDisplay(person.phoneE164)}'
                          : 'Recebe por ${view.guardian?.name ?? 'responsável'}: '
                                '${formatPhoneForDisplay(recipient.phoneE164)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!view.hasContact) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sem contato válido para envio',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (view.groupNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: view.groups
                            .map(
                              (group) => Chip(
                                label: Text(
                                  group.name,
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações do participante',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'remove') {
                    onRemove();
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
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove_outlined),
                      title: Text('Remover do evento'),
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

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}

class _EmptyParticipants extends StatelessWidget {
  const _EmptyParticipants({
    required this.hasAny,
    required this.hasFilters,
    required this.onAdd,
    required this.onClear,
  });

  final bool hasAny;
  final bool hasFilters;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (hasAny && hasFilters) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nenhum participante encontrado',
        message: 'Ajuste a busca ou limpe os filtros.',
        action: OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      );
    }

    return EmptyState(
      icon: Icons.people_outline,
      title: 'Nenhum participante ainda',
      message:
          'Adicione as pessoas que vão participar. Você pode informar apelido, '
          'telefone, responsável e grupos na mesma tela.',
      action: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Adicionar participante'),
      ),
    );
  }
}
