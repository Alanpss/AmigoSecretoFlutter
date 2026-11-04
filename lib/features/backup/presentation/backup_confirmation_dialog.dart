import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_document.dart';

Future<bool> showBackupImportConfirmation(
  BuildContext context,
  BackupPreview preview, {
  required String title,
  required String replacementMessage,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'O arquivo contém telefones e resultados de sorteios. '
                    'Esses dados são sensíveis e serão gravados somente neste dispositivo.',
                  ),
                  const SizedBox(height: 12),
                  Text(replacementMessage),
                  const SizedBox(height: 12),
                  Text(
                    'Prévia do arquivo • exportado em '
                    '${DateFormat('dd/MM/yyyy HH:mm').format(preview.exportedAt.toLocal())}',
                  ),
                  const SizedBox(height: 8),
                  _CountLine(label: 'Pessoas', count: preview.people),
                  _CountLine(label: 'Eventos', count: preview.events),
                  _CountLine(
                    label: 'Participações',
                    count: preview.participants,
                  ),
                  _CountLine(label: 'Grupos', count: preview.groups),
                  _CountLine(label: 'Sorteios', count: preview.draws),
                  _CountLine(
                    label: 'Sorteios ativos',
                    count: preview.activeDraws,
                  ),
                  _CountLine(label: 'Entregas', count: preview.deliveries),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Importar e substituir'),
            ),
          ],
        ),
      ) ??
      false;
}

class _CountLine extends StatelessWidget {
  const _CountLine({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text('$label: $count'),
  );
}
