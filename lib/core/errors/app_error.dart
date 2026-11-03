/// Erro de aplicação com uma mensagem segura para o usuário.
///
/// A mensagem nunca deve conter nomes, telefones, resultados, caminhos de
/// backup ou detalhes internos que possam expor dados pessoais.
class AppError implements Exception {
  const AppError(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppError: $message';
}

/// Falha ao abrir ou preparar o banco local.
class DatabaseOpenException extends AppError {
  const DatabaseOpenException({super.cause})
    : super(
        'Não foi possível abrir os dados do aplicativo. '
        'Nada foi apagado. Tente novamente.',
      );
}
