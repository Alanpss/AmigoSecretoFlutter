import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../core/database/app_database.dart';
import '../core/database/database_factory.dart';
import '../features/backup/data/backup_service.dart';
import '../features/backup/data/file_picker_backup_file_service.dart';
import '../features/backup/domain/backup_document.dart';
import '../features/backup/presentation/backup_confirmation_dialog.dart';
import '../shared/widgets/empty_state.dart';
import 'app.dart';
import 'providers.dart';
import 'theme.dart';

/// Abre o banco e inicia o aplicativo.
///
/// Em falha, mostra uma tela segura sem apagar dados e sem exibir detalhes
/// internos. O usuário pode tentar novamente.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final database = await AppDatabase.open();
    runApp(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const AmigoSecretoApp(),
      ),
    );
  } catch (_) {
    runApp(const DatabaseFailureApp());
  }
}

/// Aplicativo mínimo exibido quando o banco não pode ser aberto.
class DatabaseFailureApp extends StatelessWidget {
  const DatabaseFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amigo Secreto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: DatabaseFailurePage(onRetry: () => unawaited(bootstrap())),
    );
  }
}

/// Tela de falha ao abrir o banco local.
class DatabaseFailurePage extends StatefulWidget {
  const DatabaseFailurePage({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<DatabaseFailurePage> createState() => _DatabaseFailurePageState();
}

class _DatabaseFailurePageState extends State<DatabaseFailurePage> {
  bool _busy = false;

  Future<void> _restoreBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    Database? database;
    try {
      final fileService = const FilePickerBackupFileService();
      final bytes = await fileService.pick(maxBytes: maxBackupBytes);
      if (!mounted || bytes == null) return;

      final document = BackupDocument.decode(bytes);
      final confirmed = await showBackupImportConfirmation(
        context,
        document.preview,
        title: 'Restaurar este backup?',
        replacementMessage: 'O conteúdo validado será gravado neste navegador para recuperar os dados. Nada será apagado antes da confirmação.',
      );
      if (!confirmed || !mounted) return;

      database = await openAppDatabase();
      await BackupService(database).importDocument(document);
      await database.close();
      database = null;
      if (mounted) widget.onRetry();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível restaurar o backup. Os dados não foram substituídos. Confira o arquivo e tente novamente.',
              ),
            ),
          );
      }
    } finally {
      await database?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.storage_outlined,
        title: 'Não foi possível abrir os dados',
        message:
            'Nada foi apagado. Feche outras abas do aplicativo, verifique o '
            'armazenamento do navegador e tente novamente.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : widget.onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _restoreBackup,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Restaurar backup'),
            ),
          ],
        ),
      ),
    );
  }
}
