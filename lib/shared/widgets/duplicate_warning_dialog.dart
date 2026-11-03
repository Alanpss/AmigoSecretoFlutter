import 'package:flutter/material.dart';

import '../../features/participants/data/person_repository.dart';

/// Aviso não bloqueante de nome ou telefone repetido.
///
/// Retorna `true` quando o organizador decide salvar mesmo assim.
Future<bool> showDuplicateWarningDialog(
  BuildContext context,
  DuplicatePersonMatches matches,
) async {
  final lines = <String>[];
  if (matches.nameMatches.isNotEmpty) {
    final names = matches.nameMatches
        .map((person) => person.name)
        .toSet()
        .join(', ');
    lines.add('Já existe uma pessoa com nome parecido: $names.');
  }
  if (matches.phoneMatches.isNotEmpty) {
    lines.add(
      'Este telefone já é usado por outra pessoa. Isso é permitido quando '
      'várias pessoas recebem pelo mesmo responsável.',
    );
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Dados parecidos encontrados'),
        content: Text(lines.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salvar mesmo assim'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
