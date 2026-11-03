import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Estado de erro com ação de nova tentativa, sem detalhes internos.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    this.title = 'Não foi possível carregar os dados',
    this.message =
        'Nada foi apagado. Verifique o armazenamento do navegador e tente '
        'novamente.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
    );
  }
}

/// Indicador de carregamento centralizado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
