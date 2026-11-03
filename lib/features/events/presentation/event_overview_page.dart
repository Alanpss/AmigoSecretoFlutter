import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/utils/br_format.dart';
import '../../../shared/widgets/async_states.dart';
import '../../groups/domain/group.dart';
import '../domain/event.dart';
import '../domain/event_overview_data.dart';

/// Visão geral do evento com atalhos para participantes, grupos e revisão.
class EventOverviewPage extends ConsumerWidget {
  const EventOverviewPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(eventOverviewProvider(eventId));

    return overviewAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        title: 'Não foi possível carregar o evento',
        onRetry: () => ref.invalidate(eventOverviewProvider(eventId)),
      ),
      data: (overview) => _EventOverviewBody(overview: overview),
    );
  }
}

class _EventOverviewBody extends StatelessWidget {
  const _EventOverviewBody({required this.overview});

  final EventOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventId = overview.event.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(overview.event.status.label),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Spacer(),
                            Text(
                              'Rev. ${overview.event.pairingRevision}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          overview.event.name,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDateBr(overview.event.eventDate)} • '
                          'Brasil (+55)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      icon: Icons.people_outline,
                      label: 'Participantes ativos',
                      value: '${overview.activeParticipants}',
                      detail: '${overview.participants.length} no total',
                      onTap: () => context.go('/events/$eventId/participants'),
                    ),
                    _StatCard(
                      icon: Icons.groups_outlined,
                      label: 'Grupos',
                      value: '${overview.groups.length}',
                      detail:
                          '${overview.restrictedGroups} com restrição ativa',
                      onTap: () => context.go('/events/$eventId/groups'),
                    ),
                    _StatCard(
                      icon: Icons.checklist_outlined,
                      label: 'Revisão',
                      value: 'Abrir',
                      detail: 'Pendências antes do sorteio',
                      onTap: () => context.go('/events/$eventId/review'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (overview.participants.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Adicione os participantes',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cadastre nomes, contatos e responsáveis. Depois '
                            'organize famílias e casais para valer no sorteio.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '/events/$eventId/participants/new',
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Adicionar participante'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/events/$eventId/participants/new'),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Adicionar participante'),
                  ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    leading: const Icon(Icons.message_outlined),
                    title: const Text('Modelo de mensagem'),
                    subtitle: const Text(
                      'Usado para montar o texto de cada participante.',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          overview.event.messageTemplate,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: const Text('Participantes'),
                        subtitle: Text(
                          '${overview.participants.length} cadastrado'
                          '${overview.participants.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.go('/events/$eventId/participants'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: const Text('Grupos e restrições'),
                        subtitle: Text(_groupSummary(overview.groups)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/events/$eventId/groups'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.checklist_outlined),
                        title: const Text('Revisão de pendências'),
                        subtitle: const Text(
                          'Confira contatos e grupos antes de sortear.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/events/$eventId/review'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Editar dados do evento'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/events/$eventId/edit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _groupSummary(List<Group> groups) {
    if (groups.isEmpty) {
      return 'Nenhum grupo criado';
    }
    final restricted = groups.where((g) => g.restrictionEnabled).length;
    return '${groups.length} grupo${groups.length == 1 ? '' : 's'} • '
        '$restricted com restrição';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
