import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../shared/widgets/async_states.dart';
import '../../groups/domain/group.dart';
import '../domain/review_summary.dart';

/// Revisão das pendências do evento antes do sorteio.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(reviewProvider(eventId));

    return reviewAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        onRetry: () => ref.invalidate(reviewProvider(eventId)),
      ),
      data: (summary) => _ReviewBody(eventId: eventId, summary: summary),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.eventId, required this.summary});

  final String eventId;
  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Revisão do evento', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Confira os participantes, contatos e grupos antes de '
                  'sortear. Nada é enviado nesta etapa.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryTile(
                      icon: Icons.people_outline,
                      label: 'Ativos',
                      value: '${summary.activeParticipants}',
                      detail: '${summary.totalParticipants} no total',
                    ),
                    _SummaryTile(
                      icon: Icons.person_off_outlined,
                      label: 'Inativos',
                      value: '${summary.inactiveParticipants}',
                      detail: 'Fora do sorteio',
                    ),
                    _SummaryTile(
                      icon: Icons.groups_outlined,
                      label: 'Grupos',
                      value: '${summary.groups.length}',
                      detail: '${summary.restrictedGroups} com restrição',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!summary.hasEnoughActiveParticipants)
                  _IssueCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Participantes ativos insuficientes',
                    message:
                        'O sorteio precisa de pelo menos 2 participantes '
                        'ativos. Ative mais participantes ou adicione novas '
                        'pessoas.',
                    actionLabel: 'Ver participantes',
                    onAction: () => context.go('/events/$eventId/participants'),
                  )
                else
                  _IssueCard(
                    icon: Icons.check_circle_outline,
                    title: 'Quantidade de participantes adequada',
                    message:
                        '${summary.activeParticipants} participantes ativos '
                        'podem entrar no sorteio.',
                  ),
                const SizedBox(height: 12),
                _PendingContactsCard(summary: summary, eventId: eventId),
                const SizedBox(height: 12),
                _GroupsCard(summary: summary, eventId: eventId),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/events/$eventId/draw'),
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('Revisar e sortear'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Card(
        margin: EdgeInsets.zero,
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
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingContactsCard extends StatelessWidget {
  const _PendingContactsCard({required this.summary, required this.eventId});

  final ReviewSummary summary;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = summary.activeWithoutContact;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pending.isEmpty
                      ? Icons.contact_phone_outlined
                      : Icons.warning_amber_outlined,
                  color: pending.isEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pending.isEmpty
                        ? 'Todos os ativos têm contato'
                        : '${pending.length} ativo'
                              '${pending.length == 1 ? '' : 's'} sem contato '
                              'válido',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pending.isEmpty
                  ? 'Os contatos serão usados para montar as mensagens na fase '
                        'de envio.'
                  : 'Esses participantes continuam no sorteio, mas a entrega '
                        'será manual até que um telefone seja informado. '
                        'O app não usa o telefone do responsável como '
                        'alternativa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...pending.map(
                (view) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(view.person.name),
                  subtitle: Text(
                    view.participant.guardianPersonId == null
                        ? 'Sem telefone no próprio cadastro'
                        : 'Responsável sem telefone válido',
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push(
                      '/events/$eventId/participants/'
                      '${view.participant.id}/edit',
                    ),
                    child: const Text('Corrigir'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupsCard extends StatelessWidget {
  const _GroupsCard({required this.summary, required this.eventId});

  final ReviewSummary summary;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = summary.groups;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grupos e restrições',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/events/$eventId/groups'),
                  child: const Text('Gerenciar'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (groups.isEmpty)
              Text(
                'Nenhum grupo criado. Se houver famílias ou casais que não '
                'devem tirar uns aos outros, crie um grupo restrito.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ...groups.map(
                (group) => _GroupLine(
                  group: group,
                  hasFewMembers: summary.groupsWithFewMembers.any(
                    (candidate) => candidate.id == group.id,
                  ),
                ),
              ),
              if (summary.restrictedGroups == 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Nenhum grupo está com restrição ativa. As regras de grupo '
                  'não serão aplicadas no sorteio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({required this.group, required this.hasFewMembers});

  final Group group;
  final bool hasFewMembers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        group.restrictionEnabled
            ? Icons.lock_outline
            : Icons.lock_open_outlined,
        color: group.restrictionEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(group.name),
      subtitle: Text(
        '${group.type.label} • ${group.memberParticipantIds.length} membro'
        '${group.memberParticipantIds.length == 1 ? '' : 's'} • '
        '${group.restrictionEnabled ? 'restrição ativa' : 'sem restrição'}'
        '${hasFewMembers ? ' • grupo com menos de 2 membros' : ''}',
      ),
      trailing: hasFewMembers
          ? Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}
