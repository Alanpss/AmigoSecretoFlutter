import 'package:flutter/material.dart';

/// Tela provisória de configurações.
///
/// Preferências, backup e restauração entram nas fases posteriores.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Configurações', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Preferências, backup e restauração serão adicionados nas próximas '
          'fases.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Seus dados ficam neste navegador'),
            subtitle: const Text(
              'O aplicativo não envia dados para servidores. Limpar os dados '
              'do navegador pode apagar a organização; exporte um backup '
              'quando essa opção estiver disponível.',
            ),
          ),
        ),
      ],
    );
  }
}
