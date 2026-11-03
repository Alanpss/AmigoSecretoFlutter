import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/domain_exceptions.dart';
import '../../../groups/domain/group.dart';

/// Criação rápida de grupo dentro do formulário de participante.
///
/// O formulário do participante permanece aberto e com os campos preenchidos;
/// apenas o novo grupo é acrescentado à seleção.
class GroupQuickCreateDialog extends ConsumerStatefulWidget {
  const GroupQuickCreateDialog({
    super.key,
    required this.eventId,
    this.initialMemberIds = const {},
  });

  final String eventId;
  final Set<String> initialMemberIds;

  @override
  ConsumerState<GroupQuickCreateDialog> createState() =>
      _GroupQuickCreateDialogState();
}

class _GroupQuickCreateDialogState
    extends ConsumerState<GroupQuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupType _type = GroupType.family;
  bool _restrictionEnabled = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final group = await ref
          .read(groupRepositoryProvider)
          .create(
            eventId: widget.eventId,
            name: _nameController.text,
            type: _type,
            restrictionEnabled: _restrictionEnabled,
            memberParticipantIds: widget.initialMemberIds,
          );
      if (mounted) {
        Navigator.of(context).pop<Group>(group);
      }
    } on DomainException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível criar o grupo. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar grupo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    return 'Use no máximo $maxGroupNameLength caracteres.';
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
                          setState(() => _type = value);
                        }
                      },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restringir sorteio no grupo'),
                subtitle: const Text(
                  'Integrantes deste grupo não podem tirar uns aos outros.',
                ),
                value: _restrictionEnabled,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _restrictionEnabled = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar grupo'),
        ),
      ],
    );
  }
}
