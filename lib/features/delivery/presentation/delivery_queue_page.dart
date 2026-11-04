import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/widgets/async_states.dart';
import '../../draw/data/draw_records.dart';
import '../domain/delivery_status.dart';
import '../domain/whatsapp_link.dart';

class DeliveryQueuePage extends ConsumerStatefulWidget {
  const DeliveryQueuePage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<DeliveryQueuePage> createState() => _DeliveryQueuePageState();
}

class _DeliveryQueuePageState extends ConsumerState<DeliveryQueuePage> {
  bool _pendingOnly = false;
  final Set<String> _busyIds = {};

  Future<void> _open(DeliveryRecord delivery) async {
    if (_busyIds.contains(delivery.id)) return;
    final uri = WhatsAppLink.create(
      phoneE164: delivery.recipientPhoneSnapshot,
      message: delivery.messageSnapshot,
    );
    if (uri == null) return;

    setState(() => _busyIds.add(delivery.id));
    try {
      final opened = await ref.read(whatsAppLauncherProvider).open(uri);
      if (!mounted) return;
      if (!opened) {
        _showCopyFallback(delivery);
        return;
      }
      await ref
          .read(deliveryRepositoryProvider)
          .markOpened(eventId: widget.eventId, deliveryId: delivery.id);
      _refresh();
      _showMessage(
        'Conversa aberta. O envio ainda precisa ser feito no WhatsApp.',
      );
    } on DomainException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) _showCopyFallback(delivery);
    } finally {
      if (mounted) setState(() => _busyIds.remove(delivery.id));
    }
  }

  Future<void> _copy(DeliveryRecord delivery) async {
    try {
      await Clipboard.setData(ClipboardData(text: delivery.messageSnapshot));
      if (mounted) _showMessage('Mensagem copiada.');
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível copiar. Selecione o texto da mensagem.');
      }
    }
  }

  void _showCopyFallback(DeliveryRecord delivery) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível abrir o WhatsApp. A entrega continua pendente.',
          ),
          action: SnackBarAction(
            label: 'Copiar',
            onPressed: () => _copy(delivery),
          ),
        ),
      );
  }

  Future<void> _confirm(DeliveryRecord delivery) async {
    final hasPhone =
        delivery.recipientPhoneSnapshot != null &&
        delivery.recipientPhoneSnapshot!.isNotEmpty;
    final method = await showDialog<DeliveryConfirmationMethod>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar envio?'),
        content: Text(
          'Confirme somente depois de tocar em Enviar. '
          '${hasPhone ? 'Escolha como a mensagem foi enviada.' : 'Este participante não tem contato cadastrado; confirme o envio manual.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (hasPhone)
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, DeliveryConfirmationMethod.manual),
              child: const Text('Enviei manualmente'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              hasPhone
                  ? DeliveryConfirmationMethod.whatsapp
                  : DeliveryConfirmationMethod.manual,
            ),
            child: Text(hasPhone ? 'Enviei pelo WhatsApp' : 'Confirmar envio'),
          ),
        ],
      ),
    );
    if (method == null || !mounted) return;

    setState(() => _busyIds.add(delivery.id));
    try {
      await ref
          .read(deliveryRepositoryProvider)
          .confirmSent(
            eventId: widget.eventId,
            deliveryId: delivery.id,
            method: method,
          );
      _refresh();
      _showMessage('Envio confirmado pelo organizador.');
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível salvar a confirmação. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(delivery.id));
    }
  }

  void _refresh() => ref.invalidate(activeDeliveriesProvider(widget.eventId));

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(activeDeliveriesProvider(widget.eventId));
    return deliveriesAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        title: 'Não foi possível carregar as entregas',
        onRetry: _refresh,
      ),
      data: (allDeliveries) {
        if (allDeliveries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ainda não há um sorteio ativo com mensagens para entregar.',
              ),
            ),
          );
        }
        final pendingCount = allDeliveries
            .where((item) => item.status == DeliveryStatus.pending.name)
            .length;
        final deliveries = _pendingOnly
            ? allDeliveries
                  .where((item) => item.status == DeliveryStatus.pending.name)
                  .toList(growable: false)
            : allDeliveries;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Entregas',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount pendente(s) de ${allDeliveries.length} participante(s).',
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar somente pendentes'),
                      value: _pendingOnly,
                      onChanged: (value) =>
                          setState(() => _pendingOnly = value),
                    ),
                    if (deliveries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Não há entregas pendentes.'),
                      ),
                    for (final delivery in deliveries)
                      _DeliveryCard(
                        delivery: delivery,
                        busy: _busyIds.contains(delivery.id),
                        onOpen:
                            delivery.recipientPhoneSnapshot == null ||
                                delivery.recipientPhoneSnapshot!.isEmpty
                            ? null
                            : () => _open(delivery),
                        onCopy: () => _copy(delivery),
                        onConfirm: () => _confirm(delivery),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.delivery,
    required this.busy,
    required this.onOpen,
    required this.onCopy,
    required this.onConfirm,
  });

  final DeliveryRecord delivery;
  final bool busy;
  final VoidCallback? onOpen;
  final VoidCallback onCopy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final status = DeliveryStatus.values.where(
      (value) => value.name == delivery.status,
    );
    final knownStatus = status.isEmpty ? null : status.first;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.ownerNameSnapshot,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text('Tirou: ${delivery.drawnNameSnapshot}'),
                      Text('Destinatário: ${delivery.recipientNameSnapshot}'),
                      if (delivery.recipientPhoneSnapshot == null ||
                          delivery.recipientPhoneSnapshot!.isEmpty)
                        Text(
                          'Sem telefone: faça a entrega manualmente.',
                          style: TextStyle(color: theme.colorScheme.error),
                        )
                      else
                        Text('Telefone: ${delivery.recipientPhoneSnapshot}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(switch (knownStatus) {
                DeliveryStatus.pending => Icons.schedule,
                DeliveryStatus.opened => Icons.open_in_new,
                DeliveryStatus.confirmed => Icons.check_circle_outline,
                null => Icons.help_outline,
              }, size: 18),
              label: Text(knownStatus?.label ?? 'Estado não reconhecido'),
              visualDensity: VisualDensity.compact,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Ver mensagem'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(delivery.messageSnapshot),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpen != null)
                  FilledButton.icon(
                    onPressed: busy ? null : onOpen,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_outlined),
                    label: Text(
                      knownStatus == DeliveryStatus.pending
                          ? 'Abrir WhatsApp'
                          : 'Reabrir WhatsApp',
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onCopy,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar mensagem'),
                ),
                if (knownStatus != DeliveryStatus.confirmed)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onConfirm,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar envio'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
