import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'empty_state.dart';

/// Tela para rotas desconhecidas.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Este endereço não existe',
        message: 'Volte para a lista de eventos para continuar.',
        action: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Voltar para o início'),
        ),
      ),
    );
  }
}
