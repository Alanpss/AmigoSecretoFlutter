import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../data/backup_service.dart';
import '../domain/backup_document.dart';
import 'backup_confirmation_dialog.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(backupServiceProvider);
      final bytes = await service.exportBytes();
      final filename = BackupService.fileName(DateTime.now());
      final saved = await ref
          .read(backupFileServiceProvider)
          .save(fileName: filename, bytes: bytes);
      if (!mounted) return;
      if (saved == BackupSaveResult.cancelled) {
        _showMessage('Exportação cancelada. Nenhum arquivo foi salvo.');
      } else if (saved == BackupSaveResult.downloadStarted) {
        _showMessage(
          'Exportação iniciada. Confira os downloads do navegador e guarde o arquivo em local seguro.',
        );
      } else {
        _showMessage('Backup exportado. Guarde o arquivo em local seguro.');
      }
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Não foi possível exportar o backup. Confira o armazenamento e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(backupFileServiceProvider)
          .pick(maxBytes: maxBackupBytes);
      if (!mounted || bytes == null) return;

      final document = ref.read(backupServiceProvider).parse(bytes);
      final confirmed = await showBackupImportConfirmation(
        context,
        document.preview,
        title: 'Substituir os dados deste aplicativo?',
        replacementMessage:
            'A importação substitui tudo que está neste navegador. '
            'Recomendamos exportar um backup atual antes de continuar.',
      );
      if (!confirmed || !mounted) return;

      await ref.read(backupServiceProvider).importDocument(document);
      refreshAllData(ref);
      if (!mounted) return;
      context.go('/');
      _showMessage('Backup importado. Os dados foram restaurados.');
    } on DomainException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Não foi possível importar o backup. Os dados atuais foram mantidos. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Backup e restauração',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'O backup inclui pessoas, telefones, eventos, sorteios e '
                  'mensagens. O arquivo não é criptografado; guarde-o em local seguro.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exportar', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Cria um arquivo JSON com todos os dados locais. '
                          'O nome do arquivo não contém nomes nem telefones.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy ? null : _export,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Exportar backup'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Importar', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Escolha um arquivo JSON válido. O aplicativo valida '
                          'o conteúdo e mostra uma prévia antes de substituir os dados.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _import,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: const Text('Selecionar backup'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/settings'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Voltar às configurações'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
