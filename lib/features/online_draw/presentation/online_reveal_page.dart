import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_configuration.dart';
import '../data/online_draw_client.dart';

class OnlineRevealPage extends StatefulWidget {
  const OnlineRevealPage({super.key, required this.token});
  final String token;

  @override
  State<OnlineRevealPage> createState() => _OnlineRevealPageState();
}

class _OnlineRevealPageState extends State<OnlineRevealPage> {
  late Future<OnlineResult?> _result;

  @override
  void initState() {
    super.initState();
    _result = _load();
  }

  Future<OnlineResult?> _load() {
    final api = const String.fromEnvironment('ONLINE_DRAW_API_BASE_URL');
    if (api.isEmpty || !FirebaseConfiguration.canInitialize) {
      return Future.error(const OnlineDrawClientException());
    }
    return OnlineDrawClient(
      apiBaseUrl: api,
      auth: FirebaseAuth.instance,
    ).reveal(widget.token);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Seu amigo secreto')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<OnlineResult?>(
            future: _result,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }
              final result = snapshot.data;
              if (snapshot.hasError || result == null) {
                return const _RevealMessage(
                  title: 'Link indisponível',
                  message: 'Este link é inválido ou foi revogado. Peça ao organizador um novo link.',
                  icon: Icons.link_off,
                );
              }
              return _RevealMessage(
                title: 'Olá, ${result.participantName}!',
                message: 'Você tirou ${result.receiverName}.',
                icon: Icons.card_giftcard,
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _RevealMessage extends StatelessWidget {
  const _RevealMessage({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 52),
      const SizedBox(height: 16),
      Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        message,
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
