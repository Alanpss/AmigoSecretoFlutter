import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Explica por que a edição está bloqueada e oferece acesso à invalidação.
class DrawLockedNotice extends StatelessWidget {
  const DrawLockedNotice({
    super.key,
    required this.eventId,
    required this.item,
  });

  final String eventId;
  final String item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Editar $item')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                'Este evento já tem um sorteio ativo.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Para proteger os resultados salvos, participantes, pessoas e grupos ficam bloqueados. Acesse o sorteio para conferir ou invalidar antes de editar.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/events/$eventId/draw'),
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Ver ou invalidar sorteio'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
