import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../../shared/utils/br_format.dart';
import '../../../shared/widgets/async_states.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/duplicate_warning_dialog.dart';
import '../../groups/domain/group.dart';
import '../../draw/presentation/draw_locked_notice.dart';
import '../domain/participant.dart';
import '../domain/person.dart';
import '../domain/phone_number.dart';
import 'widgets/contact_quick_create_dialog.dart';
import 'widgets/group_quick_create_dialog.dart';
import 'widgets/person_picker_dialog.dart';

/// Cadastro e edição de participante, com pessoa, responsável e grupos na
/// mesma tela.
class ParticipantFormPage extends ConsumerStatefulWidget {
  const ParticipantFormPage({
    super.key,
    required this.eventId,
    this.participantId,
  });

  final String eventId;
  final String? participantId;

  @override
  ConsumerState<ParticipantFormPage> createState() =>
      _ParticipantFormPageState();
}

class _ParticipantFormPageState extends ConsumerState<ParticipantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  Participant? _participant;
  Person? _reusedPerson;
  Person? _guardian;
  List<Group> _groups = const [];
  bool _isActive = true;
  Set<String> _selectedGroupIds = {};
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _loadError;

  bool get _isEditing => widget.participantId != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_markDirty);
    _nicknameController.addListener(_markDirty);
    _phoneController.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && !_loading) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _load() async {
    try {
      final groups = await ref
          .read(groupRepositoryProvider)
          .getByEvent(widget.eventId);
      final people = await ref.read(personRepositoryProvider).getAll();

      Participant? participant;
      Person? person;
      Person? guardian;
      Set<String> selectedGroups = {};

      final participantId = widget.participantId;
      if (participantId != null) {
        participant = await ref
            .read(participantRepositoryProvider)
            .getById(participantId);
        if (participant == null) {
          throw const EntityNotFoundException('Participante não encontrado.');
        }
        person = people
            .where((candidate) => candidate.id == participant!.personId)
            .firstOrNull;
        if (person == null) {
          throw const EntityNotFoundException('Pessoa não encontrada.');
        }
        final guardianId = participant.guardianPersonId;
        if (guardianId != null) {
          guardian = people
              .where((candidate) => candidate.id == guardianId)
              .firstOrNull;
        }
        selectedGroups = groups
            .where(
              (group) => group.memberParticipantIds.contains(participant!.id),
            )
            .map((group) => group.id)
            .toSet();
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _groups = groups;
        _participant = participant;
        _reusedPerson = person;
        _guardian = guardian;
        _selectedGroupIds = selectedGroups;
        _isActive = participant?.isActive ?? true;
        _nameController.text = person?.name ?? '';
        _nicknameController.text = person?.nickname ?? '';
        _phoneController.text = person?.phoneE164 ?? '';
        _loading = false;
        _dirty = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error is DomainException
              ? error.message
              : 'Não foi possível carregar os dados do participante.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickReusedPerson() async {
    final person = await pickPerson(
      context,
      eventId: widget.eventId,
      mode: PersonPickerMode.reuse,
    );
    if (person == null || !mounted) {
      return;
    }
    setState(() {
      _reusedPerson = person;
      _nameController.text = person.name;
      _nicknameController.text = person.nickname ?? '';
      _phoneController.text = person.phoneE164 ?? '';
      _dirty = true;
    });
  }

  void _clearReusedPerson() {
    setState(() {
      _reusedPerson = null;
      _nameController.clear();
      _nicknameController.clear();
      _phoneController.clear();
      _dirty = true;
    });
  }

  Future<void> _pickGuardian() async {
    final excluded = <String>{
      if (_isEditing) _participant!.personId,
      if (_reusedPerson != null) _reusedPerson!.id,
    };
    final person = await pickPerson(
      context,
      eventId: widget.eventId,
      mode: PersonPickerMode.guardian,
      excludedPersonIds: excluded,
    );
    if (person != null && mounted) {
      setState(() {
        _guardian = person;
        _dirty = true;
      });
    }
  }

  Future<void> _createGuardianContact() async {
    final person = await showDialog<Person>(
      context: context,
      builder: (dialogContext) => const ContactQuickCreateDialog(
        title: 'Novo contato responsável',
        helperText:
            'O contato recebe a mensagem no lugar do participante, mas não '
            'entra no sorteio.',
      ),
    );
    if (person != null && mounted) {
      setState(() {
        _guardian = person;
        _dirty = true;
      });
    }
  }

  Future<void> _createGroup() async {
    final group = await showDialog<Group>(
      context: context,
      builder: (dialogContext) => GroupQuickCreateDialog(
        eventId: widget.eventId,
        initialMemberIds: _isEditing ? {_participant!.id} : const {},
      ),
    );
    if (group == null || !mounted) {
      return;
    }
    setState(() {
      _groups = [..._groups, group]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _selectedGroupIds = {..._selectedGroupIds, group.id};
      _dirty = true;
    });
  }

  Future<bool> _confirmDuplicates({
    required String name,
    required String? phoneE164,
    String? excludePersonId,
  }) async {
    final matches = await ref
        .read(personRepositoryProvider)
        .findMatches(
          name: name,
          phoneE164: phoneE164,
          excludePersonId: excludePersonId,
        );
    if (!matches.hasMatches || !mounted) {
      return true;
    }
    return showDuplicateWarningDialog(context, matches);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    final parsedPhone = parsePhoneNumber(_phoneController.text);
    if (!parsedPhone.isValid) {
      return;
    }
    final phoneE164 = parsedPhone.e164!.isEmpty ? null : parsedPhone.e164;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final canSave = await _confirmDuplicates(
          name: _nameController.text,
          phoneE164: phoneE164,
          excludePersonId: _participant!.personId,
        );
        if (!canSave || !mounted) {
          return;
        }
        await ref
            .read(participantRepositoryProvider)
            .updateParticipant(
              participantId: _participant!.id,
              name: _nameController.text,
              nickname: _nicknameController.text,
              phoneE164: phoneE164,
              guardianPersonId: _guardian?.id,
              isActive: _isActive,
              groupIds: _selectedGroupIds,
            );
        refreshEvent(ref, widget.eventId);
      } else if (_reusedPerson != null) {
        await ref
            .read(participantRepositoryProvider)
            .createWithExistingPerson(
              eventId: widget.eventId,
              personId: _reusedPerson!.id,
              guardianPersonId: _guardian?.id,
              isActive: _isActive,
              groupIds: _selectedGroupIds,
            );
        refreshEvent(ref, widget.eventId);
      } else {
        final canSave = await _confirmDuplicates(
          name: _nameController.text,
          phoneE164: phoneE164,
        );
        if (!canSave || !mounted) {
          return;
        }
        await ref
            .read(participantRepositoryProvider)
            .createWithNewPerson(
              eventId: widget.eventId,
              name: _nameController.text,
              nickname: _nicknameController.text,
              phoneE164: phoneE164,
              guardianPersonId: _guardian?.id,
              isActive: _isActive,
              groupIds: _selectedGroupIds,
            );
        refreshEvent(ref, widget.eventId);
      }

      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Participante salvo.')));
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
              'Não foi possível salvar o participante. Nada foi alterado. '
              'Tente novamente.',
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
      context.go('/events/${widget.eventId}/participants');
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
      context.go('/events/${widget.eventId}/participants');
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider(widget.eventId)).asData?.value;
    if (event?.activeDrawId != null) {
      return DrawLockedNotice(eventId: widget.eventId, item: 'participante');
    }
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Participante')),
        body: AsyncErrorView(
          title: 'Não foi possível abrir o participante',
          message: _loadError!,
          onRetry: () {
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _load();
          },
        ),
      );
    }

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
                      context.go('/events/${widget.eventId}/participants');
                    }
                  },
          ),
          title: Text(_isEditing ? 'Editar participante' : 'Novo participante'),
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
                      _SectionCard(
                        title: 'Pessoa',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_isEditing) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _reusedPerson == null
                                    ? OutlinedButton.icon(
                                        onPressed: _pickReusedPerson,
                                        icon: const Icon(
                                          Icons.person_search_outlined,
                                        ),
                                        label: const Text(
                                          'Reutilizar pessoa cadastrada',
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Usando: ${_reusedPerson!.name}',
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _clearReusedPerson,
                                            child: const Text(
                                              'Usar nova pessoa',
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _nameController,
                              enabled: _reusedPerson == null,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 120,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return 'Informe o nome.';
                                }
                                if (name.length > 120) {
                                  return 'Use no máximo 120 caracteres.';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _nicknameController,
                              enabled: _reusedPerson == null,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 40,
                              decoration: const InputDecoration(
                                labelText: 'Apelido (opcional)',
                                helperText:
                                    'Usado nas mensagens quando preenchido.',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final nickname = value?.trim() ?? '';
                                if (nickname.length > 40) {
                                  return 'Use no máximo 40 caracteres.';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _phoneController,
                              enabled: _reusedPerson == null,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone (opcional)',
                                hintText: '(11) 90000-0001',
                                helperText:
                                    'Sem o +, o número é tratado como Brasil.',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final parsed = parsePhoneNumber(value ?? '');
                                return parsed.isValid ? null : parsed.error;
                              },
                            ),
                            if (_reusedPerson != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Os dados desta pessoa são compartilhados com '
                                'os outros eventos em que ela participa.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Responsável',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sem responsável, a mensagem vai para o próprio '
                              'participante. O responsável pode ou não '
                              'participar do sorteio.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_guardian == null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickGuardian,
                                      icon: const Icon(
                                        Icons.person_search_outlined,
                                      ),
                                      label: const Text('Escolher responsável'),
                                    ),
                                    TextButton.icon(
                                      onPressed: _createGuardianContact,
                                      icon: const Icon(Icons.person_add_alt_1),
                                      label: const Text('Novo contato'),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.contact_phone_outlined,
                                  ),
                                  title: Text(_guardian!.name),
                                  subtitle: Text(
                                    formatPhoneForDisplay(_guardian!.phoneE164),
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'Trocar responsável',
                                        icon: const Icon(Icons.swap_horiz),
                                        onPressed: _pickGuardian,
                                      ),
                                      IconButton(
                                        tooltip: 'Remover responsável',
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() {
                                          _guardian = null;
                                          _dirty = true;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Grupos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'A restrição é a união dos grupos ativos: se duas '
                              'pessoas compartilham qualquer grupo restrito, '
                              'não podem tirar uma à outra.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_groups.isEmpty)
                              const Text('Nenhum grupo criado neste evento.')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _groups
                                    .map(
                                      (group) => FilterChip(
                                        label: Text(
                                          group.restrictionEnabled
                                              ? '${group.name} • restrito'
                                              : group.name,
                                        ),
                                        selected: _selectedGroupIds.contains(
                                          group.id,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedGroupIds = {
                                                ..._selectedGroupIds,
                                                group.id,
                                              };
                                            } else {
                                              _selectedGroupIds = {
                                                ..._selectedGroupIds,
                                              }..remove(group.id);
                                            }
                                            _dirty = true;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _createGroup,
                                icon: const Icon(Icons.add),
                                label: const Text('Criar grupo'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Situação',
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Participa do sorteio'),
                          subtitle: const Text(
                            'Participantes inativos ficam no cadastro, mas não '
                            'entram no sorteio.',
                          ),
                          value: _isActive,
                          onChanged: (value) => setState(() {
                            _isActive = value;
                            _dirty = true;
                          }),
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
                          _isEditing
                              ? 'Salvar alterações'
                              : 'Adicionar participante',
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
