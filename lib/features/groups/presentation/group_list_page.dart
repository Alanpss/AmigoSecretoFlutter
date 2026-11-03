import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/group.dart';

/// Lista de grupos do evento, com membros e restrição.
class GroupListPage extends ConsumerWidget {
  const GroupListPage({super.key, required this.eventId});

  final String eventId;

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir grupo?',
      message:
          'O grupo "${group.name}" será removido do evento. Os participantes '
          'continuam cadastrados. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(groupRepositoryProvider).delete(group.id);
      refreshEvent(ref, eventId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Grupo excluído.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir o grupo. Tente novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _toggleRestriction(
    BuildContext context,
    WidgetRef ref,
    Group group,
    bool enabled,
  ) async {
    try {
      await ref
          .read(groupRepositoryProvider)
          .update(
            id: group.id,
            name: group.name,
            type: group.type,
            restrictionEnabled: enabled,
            memberParticipantIds: group.memberParticipantIds.toSet(),
          );
      refreshEvent(ref, eventId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível alterar a restrição. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider(eventId));
    final participantsAsync = ref.watch(participantsProvider(eventId));

    return groupsAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        onRetry: () => ref.invalidate(groupsProvider(eventId)),
      ),
      data: (groups) {
        return participantsAsync.when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) => AsyncErrorView(
            onRetry: () => ref.invalidate(participantsProvider(eventId)),
          ),
          data: (participants) {
            final namesById = {
              for (final view in participants)
                view.participant.id: view.person.name,
            };

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
                                'Grupos e restrições',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push('/events/$eventId/groups/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Criar grupo'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quando a restrição está ativa, integrantes do '
                            'grupo não podem tirar uns aos outros. A regra é a '
                            'união de todos os grupos restritos.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: groups.isEmpty
                                ? EmptyState(
                                    icon: Icons.groups_outlined,
                                    title: 'Nenhum grupo criado',
                                    message:
                                        'Crie famílias, casais ou outros '
                                        'grupos para impedir que essas pessoas '
                                        'tirem umas às outras.',
                                    action: FilledButton.icon(
                                      onPressed: () => context.push(
                                        '/events/$eventId/groups/new',
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Criar primeiro grupo'),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 24,
                                    ),
                                    itemCount: groups.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final group = groups[index];
                                      final memberNames = group
                                          .memberParticipantIds
                                          .map(
                                            (id) =>
                                                namesById[id] ??
                                                'Participante removido',
                                          )
                                          .toList(growable: false);
                                      return _GroupCard(
                                        group: group,
                                        memberNames: memberNames,
                                        onEdit: () => context.push(
                                          '/events/$eventId/groups/'
                                          '${group.id}/edit',
                                        ),
                                        onDelete: () =>
                                            _deleteGroup(context, ref, group),
                                        onRestrictionChanged: (enabled) =>
                                            _toggleRestriction(
                                              context,
                                              ref,
                                              group,
                                              enabled,
                                            ),
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
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.memberNames,
    required this.onEdit,
    required this.onDelete,
    required this.onRestrictionChanged,
  });

  final Group group;
  final List<String> memberNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onRestrictionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(group.type.label),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          Chip(
                            label: Text(
                              group.restrictionEnabled
                                  ? 'Restrição ativa'
                                  : 'Sem restrição',
                            ),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(
                              color: group.restrictionEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Ações do grupo',
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
            const SizedBox(height: 4),
            Text(
              memberNames.isEmpty
                  ? 'Nenhum membro no grupo'
                  : '${memberNames.length} membro'
                        '${memberNames.length == 1 ? '' : 's'}: '
                        '${memberNames.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Restringir sorteio neste grupo'),
              value: group.restrictionEnabled,
              onChanged: onRestrictionChanged,
            ),
          ],
        ),
      ),
    );
  }
}
