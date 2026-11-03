import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/widgets/async_states.dart';
import '../../participants/data/participant_view.dart';
import '../data/draw_records.dart';
import '../domain/draw_models.dart';

/// Revisão, confirmação e revelação individual do resultado persistido.
class DrawPage extends ConsumerStatefulWidget {
  const DrawPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends ConsumerState<DrawPage> {
  final Set<String> _revealed = {};
  bool _saving = false;
  int? _candidateRevision;
  DrawEngineResult? _candidate;

  @override
  Widget build(BuildContext context) {
    final preparation = ref.watch(drawPreparationProvider(widget.eventId));
    final participants = ref.watch(participantsProvider(widget.eventId));
    final activeDraw = ref.watch(activeDrawProvider(widget.eventId));
    return preparation.when(
      loading: () => const LoadingView(),
      error: (error, stack) => AsyncErrorView(
        onRetry: () => ref.invalidate(drawPreparationProvider(widget.eventId)),
      ),
      data: (prep) => participants.when(
        loading: () => const LoadingView(),
        error: (error, stack) => AsyncErrorView(
          onRetry: () => ref.invalidate(participantsProvider(widget.eventId)),
        ),
        data: (views) => activeDraw.when(
          loading: () => const LoadingView(),
          error: (error, stack) => AsyncErrorView(
            onRetry: () => ref.invalidate(activeDrawProvider(widget.eventId)),
          ),
          data: (persisted) => _buildContent(prep, views, persisted),
        ),
      ),
    );
  }

  Widget _buildContent(
    DrawPreparation prep,
    List<ParticipantWithPerson> views,
    PersistedDraw? persisted,
  ) {
    final engine = ref.read(drawEngineProvider);
    if (persisted == null && _candidateRevision != prep.pairingRevision) {
      _candidateRevision = prep.pairingRevision;
      _candidate = engine.draw(prep.request);
    }
    final result = persisted == null ? _candidate : null;
    final nameById = {for (final v in views) v.participant.id: v.person.name};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  persisted == null
                      ? 'Sortear amigo secreto'
                      : 'Resultado do sorteio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (persisted != null) ...[
                  const Text(
                    'O resultado está salvo. Revele cada pessoa individualmente.',
                  ),
                  const SizedBox(height: 12),
                  ...persisted.assignments.map((assignment) {
                    final visible = _revealed.contains(
                      assignment.giverParticipantId,
                    );
                    return Card(
                      child: ListTile(
                        title: Text(
                          nameById[assignment.giverParticipantId] ??
                              'Participante',
                        ),
                        subtitle: Text(
                          visible
                              ? (nameById[assignment.receiverParticipantId] ??
                                    'Participante')
                              : 'Resultado oculto',
                        ),
                        trailing: IconButton(
                          tooltip: visible
                              ? 'Ocultar resultado'
                              : 'Revelar resultado',
                          icon: Icon(
                            visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => visible
                                ? _revealed.remove(
                                    assignment.giverParticipantId,
                                  )
                                : _revealed.add(assignment.giverParticipantId),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _invalidate(persisted),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Invalidar sorteio'),
                  ),
                ] else ...[
                  Text(
                    'Revisão ${prep.pairingRevision} · ${prep.request.participantIds.length} participantes ativos',
                  ),
                  const SizedBox(height: 12),
                  if (result == null || !result.isPossible) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result?.diagnostics?.message ??
                                  'Não foi possível avaliar o sorteio.',
                            ),
                            if (result
                                    ?.diagnostics
                                    ?.groupsLargerThanHalf
                                    .isNotEmpty ??
                                false)
                              Text(
                                'Grupos maiores que metade dos ativos: ${result!.diagnostics!.groupsLargerThanHalf.join(', ')}',
                              ),
                            if (result
                                    ?.diagnostics
                                    ?.groupsThatWouldRestorePossibility
                                    .isNotEmpty ??
                                false)
                              Text(
                                'Desativar a restrição de um destes grupos permite sortear: ${result!.diagnostics!.groupsThatWouldRestorePossibility.join(', ')}',
                              ),
                            if (result
                                    ?.diagnostics
                                    ?.participantsWithoutOptions
                                    .isNotEmpty ??
                                false)
                              Text(
                                'Participantes sem opção válida: ${result!.diagnostics!.participantsWithoutOptions.map((id) => nameById[id] ?? 'Participante').join(', ')}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'As restrições permitem um pareamento completo. Ao confirmar, o resultado será salvo e as edições de participantes, pessoas e grupos ficarão bloqueadas até a invalidação.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _confirmAndSave(prep, result),
                      icon: const Icon(Icons.casino_outlined),
                      label: Text(
                        _saving ? 'Salvando…' : 'Confirmar e salvar sorteio',
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      context.go('/events/${widget.eventId}/review'),
                  child: const Text('Voltar à revisão'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSave(
    DrawPreparation prep,
    DrawEngineResult result,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar sorteio?'),
        content: const Text(
          'O resultado será salvo neste dispositivo e ficará oculto até ser revelado individualmente. Participantes, pessoas e grupos serão bloqueados para edição.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sortear e salvar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(drawRepositoryProvider)
          .saveDraw(
            eventId: widget.eventId,
            drawId: const Uuid().v4(),
            pairingRevision: prep.pairingRevision,
            pairing: result.assignments,
          );
      ref.invalidate(activeDrawProvider(widget.eventId));
      ref.invalidate(eventProvider(widget.eventId));
      ref.invalidate(eventsProvider);
    } on DomainException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      ref.invalidate(drawPreparationProvider(widget.eventId));
      _candidateRevision = null;
      _candidate = null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _invalidate(PersistedDraw draw) async {
    final opened = draw.deliveries.where((d) => d.status == 'opened').length;
    final confirmed = draw.deliveries
        .where((d) => d.status == 'confirmed')
        .length;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalidar sorteio?'),
        content: Text(
          'O resultado antigo ficará no histórico. Há $opened conversa(s) aberta(s) e $confirmed envio(s) confirmado(s). Será possível sortear novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter sorteio'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Invalidar'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    try {
      await ref.read(drawRepositoryProvider).invalidateDraw(widget.eventId);
      _revealed.clear();
      ref.invalidate(activeDrawProvider(widget.eventId));
      ref.invalidate(drawPreparationProvider(widget.eventId));
      ref.invalidate(eventProvider(widget.eventId));
      ref.invalidate(eventsProvider);
    } on DomainException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
