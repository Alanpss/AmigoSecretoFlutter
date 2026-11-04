import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/utils/br_format.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../delivery/domain/message_template.dart';
import '../domain/event.dart';

/// Criação e edição de evento.
class EventFormPage extends ConsumerWidget {
  const EventFormPage({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = eventId;
    if (id == null) {
      return const _EventFormContent(event: null);
    }

    final eventAsync = ref.watch(eventProvider(id));
    return eventAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Editar evento')),
        body: AsyncErrorView(
          title: 'Evento não encontrado',
          onRetry: () => ref.invalidate(eventProvider(id)),
        ),
      ),
      data: (event) => _EventFormContent(event: event),
    );
  }
}

class _EventFormContent extends ConsumerStatefulWidget {
  const _EventFormContent({required this.event});

  final Event? event;

  @override
  ConsumerState<_EventFormContent> createState() => _EventFormContentState();
}

class _EventFormContentState extends ConsumerState<_EventFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _templateController;
  DateTime? _eventDate;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _nameController = TextEditingController(text: event?.name ?? '');
    _templateController = TextEditingController(
      text: event?.messageTemplate ?? defaultMessageTemplate,
    );
    _eventDate = event?.eventDate;
    _nameController.addListener(_markDirty);
    _templateController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: 'Data do evento',
      cancelText: 'Cancelar',
      confirmText: 'Escolher',
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(eventRepositoryProvider);
      if (_isEditing) {
        await repository.update(
          id: widget.event!.id,
          name: _nameController.text,
          eventDate: _eventDate,
          messageTemplate: _templateController.text,
        );
        refreshEvent(ref, widget.event!.id);
        if (mounted) {
          setState(() => _dirty = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Evento atualizado.')));
          _leaveAfterSave();
        }
      } else {
        final event = await repository.create(
          name: _nameController.text,
          eventDate: _eventDate,
          messageTemplate: _templateController.text,
        );
        refreshEvents(ref);
        if (mounted) {
          setState(() => _dirty = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Evento criado.')));
          context.go('/events/${event.id}');
        }
      }
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
              'Não foi possível salvar o evento. Nada foi alterado. Tente '
              'novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _leaveAfterSave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/events/${widget.event!.id}');
    }
  }

  Future<void> _confirmDiscard() async {
    final shouldLeave = await showConfirmDialog(
      context,
      title: 'Descartar alterações?',
      message: 'As alterações não salvas serão perdidas.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (!shouldLeave || !mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: _dirty
                ? _confirmDiscard
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
          ),
          title: Text(_isEditing ? 'Editar evento' : 'Novo evento'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: maxEventNameLength,
                        decoration: const InputDecoration(
                          labelText: 'Nome do evento',
                          hintText: 'Ex.: Amigo secreto da família',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) {
                            return 'Informe o nome do evento.';
                          }
                          if (name.length > maxEventNameLength) {
                            return 'Use no máximo $maxEventNameLength caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(formatDateBr(_eventDate)),
                          subtitle: const Text('Data do evento (opcional)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_eventDate != null)
                                IconButton(
                                  tooltip: 'Remover data',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _eventDate = null;
                                      _dirty = true;
                                    });
                                  },
                                ),
                              IconButton(
                                tooltip: 'Escolher data',
                                icon: const Icon(Icons.edit_calendar_outlined),
                                onPressed: _pickDate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'País padrão dos telefones',
                          border: OutlineInputBorder(),
                        ),
                        child: const Text('Brasil (+55)'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Telefones sem código do país são interpretados como '
                        'Brasil. Outros países são aceitos quando o número '
                        'inclui o +.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.event?.activeDrawId == null)
                        TextFormField(
                          controller: _templateController,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: maxMessageTemplateLength,
                          decoration: const InputDecoration(
                            labelText: 'Modelo de mensagem',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            helperText:
                                'Variáveis: {evento}, {participante}, '
                                '{apelido}, {sorteado}, {responsavel}',
                          ),
                          validator: (value) {
                            try {
                              MessageTemplate.parse(value ?? '');
                              return null;
                            } on MessageTemplateException catch (error) {
                              return error.message;
                            }
                          },
                        )
                      else
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.message_outlined),
                            title: const Text('Modelo de mensagem'),
                            subtitle: const Text(
                              'Edite pelo editor de mensagem para decidir se '
                              'as entregas pendentes também serão atualizadas.',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go(
                              '/events/${widget.event!.id}/message-template',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isEditing ? 'Salvar alterações' : 'Criar evento',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
