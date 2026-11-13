import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../data/firebase_configuration.dart';
import '../data/online_draw_client.dart';
import '../data/online_draw_draft_repository.dart';

/// Locally managed online events. Participant data and bearer links remain in
/// this browser's database and are intentionally not fetched from Firestore.
class OnlineDrawEventsPage extends ConsumerStatefulWidget {
  const OnlineDrawEventsPage({super.key});

  @override
  ConsumerState<OnlineDrawEventsPage> createState() =>
      _OnlineDrawEventsPageState();
}

class _OnlineDrawEventsPageState extends ConsumerState<OnlineDrawEventsPage> {
  late Future<List<Map<String, Object?>>> _draftsFuture;
  String? _deletingEventId;

  OnlineDrawDraftRepository get _repository =>
      OnlineDrawDraftRepository(ref.read(appDatabaseProvider).database);

  @override
  void initState() {
    super.initState();
    _draftsFuture = _repository.list();
  }

  Future<void> _deleteEvent(Map<String, Object?> draft) async {
    final eventId = draft['eventId'] as String;
    final eventName = (draft['eventName'] as String? ?? '').trim();
    final links = (draft['links'] as List? ?? const []).whereType<Map>().toList(
      growable: false,
    );
    final hasRemoteRecord =
        links.isNotEmpty || draft['remoteEventMayExist'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir evento online?'),
        content: Text(
          hasRemoteRecord
              ? '“${eventName.isEmpty ? 'Evento sem nome' : eventName}”, o rascunho deste navegador e os resultados no servidor serão removidos. Todos os links deixarão de funcionar. Esta ação não pode ser desfeita.'
              : '“${eventName.isEmpty ? 'Evento sem nome' : eventName}” e os dados deste navegador serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir evento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (hasRemoteRecord && !FirebaseConfiguration.canInitialize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseConfiguration.configurationError ??
                'Configure o Firebase para gerenciar este evento online.',
          ),
        ),
      );
      return;
    }
    if (hasRemoteRecord && FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entre com Google para revogar os links e excluir este evento.',
          ),
        ),
      );
      return;
    }

    setState(() => _deletingEventId = eventId);
    try {
      if (hasRemoteRecord) {
        final apiBaseUrl = const String.fromEnvironment(
          'ONLINE_DRAW_API_BASE_URL',
        ).replaceFirst(RegExp(r'/$'), '');
        if (apiBaseUrl.isEmpty) {
          throw const OnlineDrawServiceUnavailableException();
        }
        await OnlineDrawClient(
          apiBaseUrl: apiBaseUrl,
          auth: FirebaseAuth.instance,
        ).deleteEvent(eventId: eventId);
      }
      await _repository.clear(eventId: eventId);
      if (!mounted) return;
      setState(() {
        _deletingEventId = null;
        _draftsFuture = _repository.list();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evento online excluído.')));
    } on OnlineDrawAuthenticationException {
      _showDeleteError('Entre novamente com Google e tente excluir o evento.');
    } on OnlineDrawAccessException {
      _showDeleteError('Esta conta não tem acesso para excluir o evento.');
    } on OnlineDrawServiceUnavailableException {
      _showDeleteError(
        'Não foi possível acessar a API online. Confira se ela está ativa e tente novamente.',
      );
    } catch (_) {
      _showDeleteError(
        'Não foi possível excluir o evento. Seus dados continuam salvos; tente novamente.',
      );
    }
  }

  void _showDeleteError(String message) {
    if (!mounted) return;
    setState(() => _deletingEventId = null);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Eventos online')),
            body: const Center(
              child: Text('Não foi possível carregar os eventos online.'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Eventos online')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final drafts = snapshot.data!;
        final participantCount = drafts.fold<int>(
          0,
          (total, draft) =>
              total + ((draft['participants'] as List?)?.length ?? 0),
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Meus eventos online')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Organize sem revelar os pares',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crie eventos online, configure participantes e compartilhe links individuais.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          onPressed: () => context.push('/online/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Criar evento online'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _OnlineListMetric(
                        icon: Icons.event_available_outlined,
                        label: 'Eventos neste navegador',
                        value: '${drafts.length}',
                      ),
                      _OnlineListMetric(
                        icon: Icons.people_outline,
                        label: 'Participantes cadastrados',
                        value: '$participantCount',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Seus eventos',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (drafts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Seu primeiro sorteio começa aqui',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Crie um evento ou copie os dados de um evento local. Os resultados locais não são copiados.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final draft in drafts)
                    _OnlineEventCard(
                      draft: draft,
                      isDeleting: _deletingEventId == draft['eventId'],
                      onDelete: () => _deleteEvent(draft),
                    ),
                  const _OnlineLocalStorageNotice(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnlineListMetric extends StatelessWidget {
  const _OnlineListMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 600
        ? MediaQuery.sizeOf(context).width - 40
        : 230,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnlineLocalStorageNotice extends StatelessWidget {
  const _OnlineLocalStorageNotice();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rascunhos e links são guardados neste navegador. Use o mesmo perfil e endereço para retomá-los.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _OnlineEventCard extends StatelessWidget {
  const _OnlineEventCard({
    required this.draft,
    required this.isDeleting,
    required this.onDelete,
  });

  final Map<String, Object?> draft;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final eventId = draft['eventId'] as String;
    final participants = (draft['participants'] as List? ?? const [])
        .whereType<Map>()
        .toList(growable: false);
    final activeCount = participants
        .where((row) => row['isActive'] as bool? ?? true)
        .length;
    final links = (draft['links'] as List? ?? const []).whereType<Map>().toList(
      growable: false,
    );
    final hasDraw = links.isNotEmpty;
    final name = (draft['eventName'] as String? ?? '').trim();

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDeleting ? null : () => context.push('/online/$eventId'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      hasDraw ? Icons.link : Icons.event_note_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Evento sem nome' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$activeCount participantes ativos de ${participants.length}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir evento online',
                    onPressed: isDeleting ? null : onDelete,
                    icon: isDeleting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: Icon(
                      hasDraw ? Icons.check_circle_outline : Icons.edit_note,
                      size: 18,
                    ),
                    label: Text(hasDraw ? 'Sorteado' : 'Rascunho'),
                  ),
                  if (hasDraw)
                    Chip(
                      avatar: const Icon(Icons.link_outlined, size: 18),
                      label: Text('${links.length} links'),
                    ),
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.primary,
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
