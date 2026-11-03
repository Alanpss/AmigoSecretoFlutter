import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
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
class DatabaseFailurePage extends StatelessWidget {
  const DatabaseFailurePage({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.storage_outlined,
        title: 'Não foi possível abrir os dados',
        message:
            'Nada foi apagado. Feche outras abas do aplicativo, verifique o '
            'armazenamento do navegador e tente novamente.',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ),
    );
  }
}
