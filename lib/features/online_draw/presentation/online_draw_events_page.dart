import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
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
        return Scaffold(
          appBar: AppBar(title: const Text('Eventos online')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Os eventos e links são guardados neste navegador. Use a mesma origem e o mesmo perfil do Chrome para retomá-los.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/online/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar evento online'),
                  ),
                  const SizedBox(height: 12),
                  if (drafts.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.cloud_outlined),
                        title: Text('Nenhum evento online neste navegador'),
                        subtitle: Text(
                          'Crie um evento ou copie um evento local para começar.',
                        ),
                      ),
                    ),
                  for (final draft in drafts)
                    _OnlineEventCard(
                      draft: draft,
                      isDeleting: _deletingEventId == draft['eventId'],
                      onDelete: () => _deleteEvent(draft),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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

    return Card(
      child: ListTile(
        leading: Icon(hasDraw ? Icons.link : Icons.cloud_outlined),
        title: Text(name.isEmpty ? 'Evento sem nome' : name),
        subtitle: Text(
          '${hasDraw ? 'Sorteado' : 'Rascunho'} · $activeCount ativos de '
          '${participants.length} participantes${hasDraw ? ' · ${links.length} links' : ''}',
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: isDeleting ? null : () => context.push('/online/$eventId'),
      ),
    );
  }
}
