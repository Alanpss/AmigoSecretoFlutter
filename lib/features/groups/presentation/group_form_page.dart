import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../draw/presentation/draw_locked_notice.dart';
import '../../participants/data/participant_view.dart';
import '../domain/group.dart';

/// Criação e edição de grupo.
class GroupFormPage extends ConsumerWidget {
  const GroupFormPage({super.key, required this.eventId, this.groupId});

  final String eventId;
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventProvider(eventId)).asData?.value;
    if (event?.activeDrawId != null) {
      return DrawLockedNotice(eventId: eventId, item: 'grupo');
    }
    final participantsAsync = ref.watch(participantsProvider(eventId));
    final id = groupId;

    if (id == null) {
      return participantsAsync.when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: const Text('Novo grupo')),
          body: AsyncErrorView(
            onRetry: () => ref.invalidate(participantsProvider(eventId)),
          ),
        ),
        data: (participants) => _GroupFormContent(
          eventId: eventId,
          group: null,
          participants: participants,
        ),
      );
    }

    final groupAsync = ref.watch(groupProvider(id));
    return groupAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Editar grupo')),
        body: AsyncErrorView(
          title: 'Grupo não encontrado',
          onRetry: () => ref.invalidate(groupProvider(id)),
        ),
      ),
      data: (group) => participantsAsync.when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: const Text('Editar grupo')),
          body: AsyncErrorView(
            onRetry: () => ref.invalidate(participantsProvider(eventId)),
          ),
        ),
        data: (participants) => _GroupFormContent(
          eventId: eventId,
          group: group,
          participants: participants,
        ),
      ),
    );
  }
}

class _GroupFormContent extends ConsumerStatefulWidget {
  const _GroupFormContent({
    required this.eventId,
    required this.group,
    required this.participants,
  });

  final String eventId;
  final Group? group;
  final List<ParticipantWithPerson> participants;

  @override
  ConsumerState<_GroupFormContent> createState() => _GroupFormContentState();
}

class _GroupFormContentState extends ConsumerState<_GroupFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late GroupType _type;
  late bool _restrictionEnabled;
  late Set<String> _memberIds;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _type = group?.type ?? GroupType.family;
    _restrictionEnabled = group?.restrictionEnabled ?? true;
    _memberIds = group?.memberParticipantIds.toSet() ?? <String>{};
    _nameController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(groupRepositoryProvider);
      if (_isEditing) {
        final updated = await repository.update(
          id: widget.group!.id,
          name: _nameController.text,
          type: _type,
          restrictionEnabled: _restrictionEnabled,
          memberParticipantIds: _memberIds,
        );
        refreshEvent(ref, widget.eventId);
        ref.invalidate(groupProvider(updated.id));
      } else {
        final created = await repository.create(
          eventId: widget.eventId,
          name: _nameController.text,
          type: _type,
          restrictionEnabled: _restrictionEnabled,
          memberParticipantIds: _memberIds,
        );
        refreshEvent(ref, widget.eventId);
        ref.invalidate(groupProvider(created.id));
      }

      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Grupo salvo.')));
        _leaveAfterSave();
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
              'Não foi possível salvar o grupo. Nada foi alterado. Tente '
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
      context.go('/events/${widget.eventId}/groups');
    }
  }

  Future<void> _confirmDiscard() async {
    final shouldLeave = await showConfirmDialog(
      context,
      title: 'Descartar alterações?',
      message: 'Os dados não salvos serão perdidos.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
    if (!shouldLeave || !mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/events/${widget.eventId}/groups');
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
                      context.go('/events/${widget.eventId}/groups');
                    }
                  },
          ),
          title: Text(_isEditing ? 'Editar grupo' : 'Novo grupo'),
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
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: maxGroupNameLength,
                        decoration: const InputDecoration(
                          labelText: 'Nome do grupo',
                          hintText: 'Ex.: Família Silva',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) {
                            return 'Informe o nome do grupo.';
                          }
                          if (name.length > maxGroupNameLength) {
                            return 'Use no máximo $maxGroupNameLength '
                                'caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GroupType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        items: GroupType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _type = value;
                                    _dirty = true;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: SwitchListTile(
                          title: const Text('Restringir sorteio no grupo'),
                          subtitle: const Text(
                            'Integrantes deste grupo não podem tirar uns aos '
                            'outros quando a restrição está ativa.',
                          ),
                          value: _restrictionEnabled,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                  _restrictionEnabled = value;
                                  _dirty = true;
                                }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Membros do grupo',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marque os participantes que pertencem a este grupo. '
                        'Uma pessoa pode estar em mais de um grupo; a restrição '
                        'efetiva é a união dos grupos ativos.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.participants.isEmpty)
                        Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text(
                              'Nenhum participante cadastrado neste evento.',
                            ),
                            subtitle: const Text(
                              'Adicione participantes antes de incluir membros '
                              'no grupo.',
                            ),
                          ),
                        )
                      else
                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: widget.participants
                                .map(
                                  (view) => CheckboxListTile(
                                    value: _memberIds.contains(
                                      view.participant.id,
                                    ),
                                    title: Text(view.person.name),
                                    subtitle: view.participant.isActive
                                        ? null
                                        : const Text('Inativo no sorteio'),
                                    onChanged: _saving
                                        ? null
                                        : (selected) {
                                            setState(() {
                                              if (selected ?? false) {
                                                _memberIds = {
                                                  ..._memberIds,
                                                  view.participant.id,
                                                };
                                              } else {
                                                _memberIds = {..._memberIds}
                                                  ..remove(view.participant.id);
                                              }
                                              _dirty = true;
                                            });
                                          },
                                  ),
                                )
                                .toList(),
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
                          _isEditing ? 'Salvar alterações' : 'Criar grupo',
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
