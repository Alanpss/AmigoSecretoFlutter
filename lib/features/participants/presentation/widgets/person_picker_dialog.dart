import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../shared/utils/br_format.dart';
import '../../domain/person.dart';
import 'contact_quick_create_dialog.dart';

enum PersonPickerMode {
  /// Reutilizar uma pessoa que ainda não participa do evento.
  reuse,

  /// Escolher um responsável, que pode ou não participar.
  guardian,
}

/// Seletor pesquisável de pessoas do cadastro.
class PersonPickerDialog extends ConsumerStatefulWidget {
  const PersonPickerDialog({
    super.key,
    required this.eventId,
    required this.mode,
    this.excludedPersonIds = const {},
  });

  final String eventId;
  final PersonPickerMode mode;
  final Set<String> excludedPersonIds;

  @override
  ConsumerState<PersonPickerDialog> createState() => _PersonPickerDialogState();
}

class _PersonPickerDialogState extends ConsumerState<PersonPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Person>? _people;
  Set<String> _participatingPersonIds = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final people = await ref.read(personRepositoryProvider).getAll();
      final participants = await ref
          .read(participantRepositoryProvider)
          .getByEvent(widget.eventId);
      if (!mounted) {
        return;
      }
      setState(() {
        _people = people;
        _participatingPersonIds = participants
            .map((participant) => participant.personId)
            .toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar as pessoas.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _createContact() async {
    final person = await showDialog<Person>(
      context: context,
      builder: (dialogContext) => ContactQuickCreateDialog(
        title: 'Novo contato responsável',
        helperText:
            'O contato recebe a mensagem no lugar do participante, mas não '
            'entra no sorteio.',
      ),
    );
    if (person != null && mounted) {
      Navigator.of(context).pop(person);
    }
  }

  List<Person> get _filtered {
    final people = _people ?? const <Person>[];
    final query = _searchController.text.trim().toLowerCase();
    return people
        .where((person) {
          if (widget.excludedPersonIds.contains(person.id)) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return person.name.toLowerCase().contains(query) ||
              (person.nickname?.toLowerCase().contains(query) ?? false) ||
              (person.phoneE164?.contains(query) ?? false);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == PersonPickerMode.reuse
        ? 'Reutilizar pessoa'
        : 'Escolher responsável';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar pessoa',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _filtered.isEmpty
                  ? const Center(child: Text('Nenhuma pessoa encontrada.'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final person = _filtered[index];
                        final alreadyParticipates = _participatingPersonIds
                            .contains(person.id);
                        final disabled =
                            widget.mode == PersonPickerMode.reuse &&
                            alreadyParticipates;

                        return ListTile(
                          enabled: !disabled,
                          leading: const Icon(Icons.person_outline),
                          title: Text(person.name),
                          subtitle: Text(
                            [
                              if (person.nickname != null)
                                'Apelido: ${person.nickname}',
                              formatPhoneForDisplay(person.phoneE164),
                              if (alreadyParticipates) 'Já participa',
                            ].join(' • '),
                          ),
                          trailing: disabled
                              ? const Chip(
                                  label: Text('Já participa'),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: disabled
                              ? null
                              : () => Navigator.of(context).pop(person),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.mode == PersonPickerMode.guardian)
          TextButton.icon(
            onPressed: _createContact,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Novo contato'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Abre o seletor e devolve a pessoa escolhida, se houver.
Future<Person?> pickPerson(
  BuildContext context, {
  required String eventId,
  required PersonPickerMode mode,
  Set<String> excludedPersonIds = const {},
}) {
  return showDialog<Person>(
    context: context,
    builder: (dialogContext) => PersonPickerDialog(
      eventId: eventId,
      mode: mode,
      excludedPersonIds: excludedPersonIds,
    ),
  );
}
