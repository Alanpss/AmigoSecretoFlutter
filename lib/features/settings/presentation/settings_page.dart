import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Configurações e recuperação local dos dados.
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
          'Salve uma cópia dos seus dados sensíveis antes de trocar de navegador '
          'ou limpar o armazenamento.',
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
              'do navegador pode apagar a organização. Os dados não são enviados '
              'a servidores.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup e restauração'),
            subtitle: const Text(
              'Exporte ou importe uma cópia JSON dos dados deste aplicativo.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/backup'),
            minVerticalPadding: 16,
          ),
        ),
      ],
    );
  }
}
