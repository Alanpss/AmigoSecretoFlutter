import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/widgets/async_states.dart';
import '../../events/domain/event.dart';
import '../domain/delivery_status.dart';
import '../domain/message_template.dart';

class MessageTemplatePage extends ConsumerWidget {
  const MessageTemplatePage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventProvider(eventId));
    return event.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        title: 'Não foi possível carregar o evento',
        onRetry: () => ref.invalidate(eventProvider(eventId)),
      ),
      data: (value) => _MessageTemplateEditor(event: value),
    );
  }
}

class _MessageTemplateEditor extends ConsumerStatefulWidget {
  const _MessageTemplateEditor({required this.event});

  final Event event;

  @override
  ConsumerState<_MessageTemplateEditor> createState() =>
      _MessageTemplateEditorState();
}

class _MessageTemplateEditorState
    extends ConsumerState<_MessageTemplateEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.event.messageTemplate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(int pendingCount) async {
    if (_saving || !_formKey.currentState!.validate()) return;

    var updatePending = false;
    if (widget.event.activeDrawId != null && pendingCount > 0) {
      final choice = await showDialog<_PendingTemplateChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Atualizar entregas pendentes?'),
          content: Text(
            'Há $pendingCount mensagem(ns) pendente(s). As conversas abertas '
            'e os envios confirmados manterão o texto anterior.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _PendingTemplateChoice.cancel),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, _PendingTemplateChoice.saveOnly),
              child: const Text('Salvar sem atualizar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _PendingTemplateChoice.updatePending),
              child: const Text('Salvar e atualizar'),
            ),
          ],
        ),
      );
      if (choice == null || choice == _PendingTemplateChoice.cancel) return;
      updatePending = choice == _PendingTemplateChoice.updatePending;
    }

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(deliveryRepositoryProvider)
          .saveMessageTemplate(
            eventId: widget.event.id,
            template: _controller.text,
            updatePending: updatePending,
          );
      refreshEvent(ref, widget.event.id);
      ref.invalidate(activeDeliveriesProvider(widget.event.id));
      if (!mounted) return;

      final message = result.updatedPendingMessages == 0
          ? 'Modelo de mensagem salvo.'
          : '${result.updatedPendingMessages} mensagem(ns) pendente(s) atualizada(s).';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.go(
        widget.event.activeDrawId == null
            ? '/events/${widget.event.id}'
            : '/events/${widget.event.id}/deliveries',
      );
    } on DomainException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o modelo. Nada foi alterado. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDeliveries = ref.watch(
      activeDeliveriesProvider(widget.event.id),
    );
    final deliveries = activeDeliveries.asData?.value;
    final pendingCount = deliveries == null
        ? 0
        : deliveries
              .where(
                (delivery) => delivery.status == DeliveryStatus.pending.name,
              )
              .length;
    final preview = _buildPreview(_controller.text);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Modelo de mensagem',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O texto é preparado separadamente para cada participante. '
                    'Nenhuma mensagem é enviada automaticamente.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _controller,
                    minLines: 6,
                    maxLines: 10,
                    maxLength: maxMessageTemplateLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Texto da mensagem',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      helperText:
                          'Use {evento}, {participante}, {apelido}, '
                          '{sorteado} e {responsavel}.',
                    ),
                    validator: (value) {
                      try {
                        MessageTemplate.parse(value ?? '');
                        return null;
                      } on MessageTemplateException catch (error) {
                        return error.message;
                      }
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prévia fictícia',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preview.message ?? preview.error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: preview.error == null
                                  ? null
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.event.activeDrawId != null) ...[
                    const SizedBox(height: 12),
                    if (deliveries == null && activeDeliveries.hasError)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.error_outline),
                          title: const Text(
                            'Não foi possível conferir as entregas.',
                          ),
                          subtitle: const Text(
                            'Recarregue antes de salvar para decidir com segurança '
                            'sobre as mensagens pendentes.',
                          ),
                          trailing: IconButton(
                            tooltip: 'Tentar carregar novamente',
                            onPressed: () => ref.invalidate(
                              activeDeliveriesProvider(widget.event.id),
                            ),
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      )
                    else
                      Text(
                        deliveries == null
                            ? 'Carregando mensagens de entrega…'
                            : pendingCount == 0
                            ? 'Não há mensagens pendentes para atualizar.'
                            : '$pendingCount mensagem(ns) pendente(s) podem ser atualizadas ao salvar.',
                      ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        _saving ||
                            (widget.event.activeDrawId != null &&
                                deliveries == null)
                        ? null
                        : () => _save(pendingCount),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salvar modelo'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.go('/events/${widget.event.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Voltar ao evento'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  ({String? message, String? error}) _buildPreview(String source) {
    try {
      final template = MessageTemplate.parse(source);
      return (
        message: template.render(const {
          'evento': 'Encontro fictício',
          'participante': 'Ana Exemplo',
          'apelido': 'Aninha',
          'sorteado': 'Beto Exemplo',
          'responsavel': 'Carla Exemplo',
        }),
        error: null,
      );
    } on MessageTemplateException catch (error) {
      return (message: null, error: error.message);
    }
  }
}

enum _PendingTemplateChoice { cancel, saveOnly, updatePending }
